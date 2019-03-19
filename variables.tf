variable "key_name" {
  description = "name of ssh keypair"
}

variable "aws_region" {
 default = "us-east-2" 
}

variable "aws_amis" {
  default = {
    "us-east-2" = "ami-0c55b159cbfafe1f0"
  } 
}
variable "aws_instance_count" {
  default = "3"
}
