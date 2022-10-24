terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.35.0"
    }
  }
}

provider "aws" {
  # Configuration options
}

variable "instance_type" {
  default = "t2.micro"
  type = string
}

variable "region" {
  default = "us-east-1"
  type = string
}

variable "amis" {
  default = {
    "us-east-1" = "ami-09d3b3274b6c5d4aa",
    "us-west-1" = "ami-026b57f3c383c2eec"
  }
  type = map(string)
}

variable "vpc_cidr_block" {
  default = "172.16.0.0/16"
  type = string
}

variable "tag" {
  default = {
    Name = "Terraform"
  }
  type = map(string)
}

variable "igw_cidr_block" {
  default = "0.0.0.0/0"
  type = string
}

variable "pub_snet1_cidr" {
  default = "172.16.10.0/24"
  type = string
}

variable "pub_snet2_cidr" {
  default = "172.16.11.0/24"
  type = string
}

variable "pvt_snet1_cidr" {
  default = "172.16.12.0/24"
  type = string
}

variable "pvt_snet2_cidr" {
  default = "172.16.13.0/24"
  type = string
}

variable "availability_zn" {
  default = "us-east-1a"
  type = string
}

resource "aws_vpc" "terraform_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = var.tag
}

resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = var.tag
}

resource "aws_route_table" "terraform_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = var.igw_cidr_block
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  tags = var.tag
}

resource "aws_route_table_association" "terraform_rta" {
  subnet_id      = aws_subnet.terraform_subnet_pub1.id
  route_table_id = aws_route_table.terraform_rt.id
}

resource "aws_route_table_association" "terraform_rta2" {
  subnet_id      = aws_subnet.terraform_subnet_pub2.id
  route_table_id = aws_route_table.terraform_rt.id
}

resource "aws_subnet" "terraform_subnet_pub1" {
  vpc_id = aws_vpc.terraform_vpc.id
  cidr_block = var.pub_snet1_cidr
  availability_zone = var.availability_zn
  
  tags = var.tag
}

resource "aws_subnet" "terraform_subnet_pub2" {
  vpc_id = aws_vpc.terraform_vpc.id
  cidr_block = var.pub_snet2_cidr
  availability_zone = var.availability_zn
  
  tags = var.tag
}

resource "aws_subnet" "terraform_subnet_pvt1" {
  vpc_id = aws_vpc.terraform_vpc.id
  cidr_block = var.pvt_snet1_cidr
  availability_zone = var.availability_zn

  tags = var.tag
}

resource "aws_subnet" "terraform_subnet_pvt2" {
  vpc_id = aws_vpc.terraform_vpc.id
  cidr_block = var.pvt_snet2_cidr
  availability_zone = var.availability_zn

  tags = var.tag
}

resource "aws_security_group" "terraform_sg" {
  name = "terraform_sg"
  vpc_id = aws_vpc.terraform_vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [var.igw_cidr_block]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.igw_cidr_block]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.igw_cidr_block]
  }
}

variable "keyname" {
  default = "TPStraining"
  type = string
}

variable "userdata" {
  default = <<EOF
  #!/bin/bash
  sudo yum update
  sudo yum install httpd -y
  sudo yum install php -y
  sudo systemctl start httpd
  sudo chmod -R 777 /var/www/html/
  sudo echo "<?php phpinfo(); ?>" >> /var/www/html/info.php
  EOF
  type = string
}

resource "aws_instance" "test1" {
  ami = var.amis[var.region]
  instance_type = var.instance_type
  subnet_id = aws_subnet.terraform_subnet_pub1.id
  vpc_security_group_ids = [ aws_security_group.terraform_sg.id ]
  key_name = var.keyname
  associate_public_ip_address = true
  user_data = var.userdata
  user_data_replace_on_change = true
  depends_on = [aws_internet_gateway.terraform_igw]
  tags = var.tag
}

resource "aws_instance" "test2" {
  ami = var.amis[var.region]
  instance_type = var.instance_type
  subnet_id = aws_subnet.terraform_subnet_pub2.id
  vpc_security_group_ids = [ aws_security_group.terraform_sg.id ]
  key_name = var.keyname
  associate_public_ip_address = true
  user_data = var.userdata
  user_data_replace_on_change = true
  depends_on = [aws_internet_gateway.terraform_igw]
  tags = var.tag
}
