# configure the aws provider
provider "aws" {
    region = "eu-west-1" 

    access_key = var.accessKey
    secret_key = var.secretKey
}

# specify the relevant image
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# create 2 ubuntu instances
resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  count         = var.instance_count
  user_data     = file("install_nginx.sh")

  tags = {
    Name  = element(var.instance_tags, count.index)
  }
}

# Create Security Group (SG)
resource "aws_security_group" "allow_web" {
  name = "allow_web_traffic"
  description = "Allow inbound web traffic"
  vpc_id = data.aws_vpc.default_vpc.id

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  tags = {
    "Name" = "fursa-sg"
  }

}

# choose the default vpc
data "aws_vpc" "default_vpc" {
  default = true
}

# choose the default subnet
data "aws_subnet" "default_subnet" {
  default_for_az = true 
  vpc_id         = "${data.aws_vpc.default_vpc.id}"
}

# Crate an internet Gateway
resource "aws_internet_gateway" "my_gtw" {
  vpc_id = data.aws_vpc.default_vpc.id

  tags = {
    Name = "my_gtw"
  }
}

# create a routing table
resource "aws_route_table" "my_rtb" {
  vpc_id = data.aws_vpc.default_vpc.id

  route {
      cidr_block = "0.0.0.0/0" # IPv4
      gateway_id = aws_internet_gateway.my_gtw.id
  }
  tags = {
    Name = "my_rtb"
  }
}

# Create a RTB association
resource "aws_route_table_association" "a" {
  subnet_id      = data.aws_subnet.default_subnet.id
  route_table_id = aws_route_table.my_rtb.id 
}

# create a target group
resource "aws_lb_target_group" "my_tg" {
  name     = "terraform-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id
}

# attach the newly created instances to the target group
resource "aws_alb_target_group_attachment" "test" {
  count = length(aws_instance.my_instance) # taken from https://stackoverflow.com/questions/44491994/not-able-to-add-multiple-target-id-inside-targer-group-using-terraform
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id = aws_instance.my_instance[count.index].id
  port = 80
}

# create a load balancer
resource "aws_lb" "fursa-lb" {
  name               = "my-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = [data.aws_subnet.default_subnet.id]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}