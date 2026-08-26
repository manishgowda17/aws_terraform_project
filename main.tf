
resource "aws_vpc" "my_vpc" {
  cidr_block = var.cidr

  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "my_subnet1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "my-subnet1"
  }
}

resource "aws_subnet" "my_subnet2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "my-subnet2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

# Route Table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "my_route_table_association1" {
  subnet_id      = aws_subnet.my_subnet1.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_route_table_association" "my_route_table_association2" {
  subnet_id      = aws_subnet.my_subnet2.id
  route_table_id = aws_route_table.my_route_table.id
}

# ============================================
# ALB SECURITY GROUP
# ============================================

resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group-terraform"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = aws_vpc.my_vpc.id

  tags = {
    Name = "alb-security-group-terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb_sg.id

  cidr_ipv4 = "0.0.0.0/0"

  from_port = 80
  to_port   = 80

  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_outbound" {
  security_group_id = aws_security_group.alb_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# ============================================
# EC2 SECURITY GROUP
# ============================================

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group-terraform"
  description = "Allow SSH and HTTP traffic to EC2"
  vpc_id      = aws_vpc.my_vpc.id

  tags = {
    Name = "ec2-security-group-terraform"
  }
}

# SSH access
resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
  security_group_id = aws_security_group.ec2_sg.id

  cidr_ipv4 = "0.0.0.0/0"

  from_port = 22
  to_port   = 22

  ip_protocol = "tcp"
}

# HTTP access from ALB only
resource "aws_vpc_security_group_ingress_rule" "ec2_http_from_alb" {
  security_group_id = aws_security_group.ec2_sg.id

  referenced_security_group_id = aws_security_group.alb_sg.id

  from_port = 80
  to_port   = 80

  ip_protocol = "tcp"
}

# EC2 outbound traffic
resource "aws_vpc_security_group_egress_rule" "ec2_outbound" {
  security_group_id = aws_security_group.ec2_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# ============================================
# S3 BUCKET
# ============================================

resource "aws_s3_bucket" "my_bucket" {
  bucket = "manish-storage-12"
}

# ============================================
# EC2 INSTANCE 1
# ============================================

resource "aws_instance" "my_instance1" {
  ami           = "ami-0b6d9d3d33ba97d99"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.my_subnet1.id

  # IMPORTANT: Use IDs, not names
  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  user_data = base64encode(file("userdata.sh"))

  tags = {
    Name = "MyInstance1"
  }
}

# ============================================
# EC2 INSTANCE 2
# ============================================

resource "aws_instance" "my_instance2" {
  ami           = "ami-0b6d9d3d33ba97d99"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.my_subnet2.id

  # IMPORTANT: Use IDs, not names
  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  user_data = base64encode(file("userdata1.sh"))

  tags = {
    Name = "MyInstance2"
  }
}

# ============================================
# APPLICATION LOAD BALANCER
# ============================================

resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb_sg.id
  ]

  subnets = [
    aws_subnet.my_subnet1.id,
    aws_subnet.my_subnet2.id
  ]

  tags = {
    Name = "myalb"
  }
}

# ============================================
# TARGET GROUP
# ============================================

resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"

  vpc_id = aws_vpc.my_vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

# ============================================
# ATTACH EC2 INSTANCES TO TARGET GROUP
# ============================================

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.my_instance1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.my_instance2.id
  port             = 80
}

# ============================================
# ALB LISTENER
# ============================================

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ============================================
# OUTPUT
# ============================================

output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
}