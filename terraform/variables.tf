variable "aws_region" {
	description = "AWS Region"
	type = string
}

variable "ssh_key" {
	description = "SSH key to use on the EC2"
	type = string
}

variable "cidr_blocks" {
	description = "Authorized CIDR"
	type = list
}


