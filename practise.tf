provider "aws"{
  region = "us-east-2"
}

resource "aws_vpc" "tf_vpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "tf_subnet"{
  cidr_block = "10.0.0.0/24"
  vpc_id = "${aws_vpc.tf_vpc.id}"
  map_public_ip_on_launch = true
 } 
resource "aws_internet_gateway" "ig"{
  vpc_id = "${aws_vpc.tf_vpc.id}"
}
resource "aws_route_table" "routes" {
  vpc_id = "${aws_vpc.tf_vpc.id}"
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ig.id}"
  }
}
resource "aws_route_table_association" "ra" {
  subnet_id = "${aws_subnet.tf_subnet.id}"
  route_table_id = "${aws_route_table.routes.id}"
}
resource "aws_security_group" "sg_ec2" {
  name = "Web Security Group"
  description = "Security group to access ec2 instances"
  vpc_id = "${aws_vpc.tf_vpc.id}"
  
#SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

#HTTP access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}    
}
#ELB security group
resource "aws_security_group" "elb_sg" {
  name = "elb security"
  description = "for accessing ELB"
  vpc_id = "${aws_vpc.tf_vpc.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

# ensure the VPC has an Internet gateway or this step will fail

  depends_on = ["aws_internet_gateway.ig"]
}

resource "aws_elb" "web" {
  name = "test-elb"
  subnets = ["${aws_subnet.tf_subnet.id}"]
  security_groups = ["${aws_security_group.elb_sg.id}"]
  
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
}
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
}
  instances = ["${aws_instance.web.*.id}"]
  
  cross_zone_load_balancing = true
  idle_timeout = 400
  #connection_draining = true
  #connection_drain_timeout = 400
}

resource "aws_instance" "web" {
  count = "${var.aws_instance_count}"
  instance_type = "t2.micro"
  ami = "${lookup(var.aws_amis,var.aws_region)}"
  key_name = "awsshop"
  vpc_security_group_ids = ["${aws_security_group.sg_ec2.id}"]
  subnet_id = "${aws_subnet.tf_subnet.id}"
  
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("/root/terraform/awsshop.pem")}"
}


  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y && sudo apt-get update -y",
      "sudo apt-get install apache2 -y",
]
}
}
