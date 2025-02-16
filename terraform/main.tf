provider "aws" {
  region = var.aws_region
  alias = "aws"
}

data "aws_ami" "debian" {
  most_recent = true
  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["136693071363"]
}

resource "aws_key_pair" "sshkey" {
  provider = aws.aws
  key_name   = "redteam-key"
  public_key = file(var.ssh_key)
}