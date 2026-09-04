variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
}
variable "subnet_id" {
  description = "The subnet ID to launch the EC2 instance in"
  type        = string
}
variable "key_name" {
  description = "The name of the key pair to use for the EC2 instance"
  type        = string
}
variable "instance_type" {
  description = "The type of instance to launch"
  type        = string
  default     = "t3.micro"
}