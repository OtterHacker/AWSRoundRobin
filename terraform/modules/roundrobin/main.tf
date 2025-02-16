terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        configuration_aliases = [
            aws.aws,
        ]
    }
  }
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

resource "aws_security_group" "openvpn" {
  provider = aws.aws
  name        = "round-robin-openvpn"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "tcp"
    security_groups = [aws_security_group.proxy.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "proxy" {
  provider = aws.aws
  name        = "roundrobin-proxy"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "sshkey" {
  provider = aws.aws
  key_name   = "roundrobin-key"
  public_key = file(var.ssh_key)
}

resource "aws_instance" "openvpn1" {
  provider = aws.aws
  ami           = data.aws_ami.debian.id
  instance_type = "t2.nano"
  security_groups = [aws_security_group.openvpn.name]
  key_name      = aws_key_pair.sshkey.key_name
  tags = {
    Name = "ROUNDROBIN.MASTER"
  }
}

resource "aws_instance" "openvpn2" {
  provider = aws.aws
  ami           = data.aws_ami.debian.id
  instance_type = "t2.nano"
  security_groups = [aws_security_group.openvpn.name]
  key_name      = aws_key_pair.sshkey.key_name
  tags = {
    Name = "ROUNDROBIN.SLAVE"
  }
}

resource "aws_instance" "proxy" {
  provider = aws.aws
  ami           = data.aws_ami.debian.id
  instance_type = "t2.nano"
  security_groups = [aws_security_group.proxy.name]
  key_name      = aws_key_pair.sshkey.key_name
  tags = {
    Name = "ROUNDROBIN.PROXY"
  }
}

data "aws_iam_policy_document" "assume_role" {
  provider = aws.aws
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "archive_file" "lambda_code" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

resource "aws_iam_role" "iam_for_lambda" {
  provider = aws.aws
  name               = "round-robin-${aws_instance.openvpn1.id}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_cloudwatch_log_group" "roundrobin-cloudlog" {
  provider = aws.aws
  name = "/aws/lambda/round-robin-lambda-${aws_instance.openvpn1.id}"
}

resource "aws_lambda_function" "roundrobin-lambda" {
  provider = aws.aws
  function_name = "round-robin-lambda-${aws_instance.openvpn1.id}"
  filename      = "${path.module}/lambda_function_payload.zip"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"
  timeout       = "120"
  runtime       = "python3.12"
  source_code_hash = data.archive_file.lambda_code.output_base64sha256
}

resource "aws_cloudwatch_event_rule" "lambda_trigger" {
  provider = aws.aws
  name        = "round-robin-${aws_instance.openvpn1.id}"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  provider = aws.aws
  rule      = aws_cloudwatch_event_rule.lambda_trigger.name
  target_id = "roundrobin-lambda"
  arn       = aws_lambda_function.roundrobin-lambda.arn
}
