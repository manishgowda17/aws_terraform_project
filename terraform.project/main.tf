terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.63.0"
        }
    }
}
resource "aws_instance" "example" {
  ami       = "ami-0b6d9d3d33ba97d99"
  subnet_id     = "subnet-0e11f6efb1ccc2a76"
  instance_type = "t3.micro"
  key_name     = "cloud"

  tags = {
    Name = "ExampleInstance"
  }
}