#!/bin/bash
set -e

echo "[*] Initializing and applying Terraform..."
cd terraform
terraform init
terraform apply -auto-approve

echo "[*] Copying generated hosts file to Ansible inventory..."
cp hosts.yml ../ansible/inventory/hosts.yml

echo "[*] Extracting AWS region from terraform.tfvars..."
AWS_REGION=$(grep aws_region terraform.tfvars | awk -F'"' '{print $2}')
PUB_KEY_PATH=$(grep ssh_key terraform.tfvars | awk -F'"' '{print $2}')
PRIVATE_KEY_PATH="${PUB_KEY_PATH%.pub}"
cd ..

echo "[*] Running Ansible playbook..."
cd ansible
ansible-playbook playbooks/redteam/roundrobin.yml \
    -i inventory/ \
    --private-key "$PRIVATE_KEY_PATH" \
    -e "aws_region=${AWS_REGION}" \
    -e "region=${AWS_REGION}"

echo "[*] Deployment complete!"