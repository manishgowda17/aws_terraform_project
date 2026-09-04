terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.63.0"
        }
    }
}

resource "aws_instance" "example" {
    ami           = var.ami_id
    instance_type = var.instance_type
    subnet_id     = var.subnet_id
    key_name     = var.key_name
}