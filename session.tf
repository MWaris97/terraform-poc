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
  access_key = ""
  secret_key = ""
}

resource "aws_instance" "test" {
  ami = "ami-078296f82eb463377"
  instance_type = "t2.micro"

  tags = {
    Name = "Terraform"
  }
}