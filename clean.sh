#!/bin/bash
set -e

AWS_REGION=$(grep aws_region terraform/terraform.tfvars | awk -F'"' '{print $2}')
PUB_KEY_PATH=$(grep ssh_key terraform/terraform.tfvars | awk -F'"' '{print $2}')
PRIVATE_KEY_PATH="${PUB_KEY_PATH%.pub}"

echo "[*] 1/2: Running Ansible cleanup (Removing Lambda, IAM, EventBridge)..."
cd ansible
ansible-playbook playbooks/redteam/cleanup.yml \
    -i inventory/ \
    --private-key "$PRIVATE_KEY_PATH" \
    -e "aws_region=${AWS_REGION}" \
    -e "region=${AWS_REGION}"
cd ..

echo "[*] 2/2: Running Terraform destroy (Removing EC2, Security Groups)..."
cd terraform
terraform destroy -auto-approve

echo "[*] Environment cleaned!"