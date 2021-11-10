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

  egress  {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "All networks allowed"
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  tags = {
    "Name" = "test-sg"
  }

}

# choose the default vpc
data "aws_vpc" "default_vpc" {
  default = true
}

# get subnet ids in the default VPC
data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
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
resource "aws_lb" "fursa_lb" {
  name               = "my-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = data.aws_subnet_ids.default_subnet.ids

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

# add a listener to the load balancer
resource "aws_lb_listener" "my_aws_lb_listener" {
  load_balancer_arn = aws_lb.fursa_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}
