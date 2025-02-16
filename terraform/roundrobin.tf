module "roundrobin" {
    source = "./modules/roundrobin"
    providers = {
      aws.aws = aws.aws
    }
    ssh_key = var.ssh_key
    aws_region = var.aws_region
}

locals {
    roundrobin_ansible = module.roundrobin.ansible
}