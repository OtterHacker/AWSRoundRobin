output "ansible" {
  value = format("    openvpn_proxy:\n      ansible_host: %s\n      ansible_user: admin\n    openvpn1:\n      ansible_host: %s\n      ansible_user: admin\n    openvpn2:\n      ansible_host: %s\n      ansible_user: admin\n",
    aws_instance.proxy.public_ip,
    aws_instance.openvpn1.public_ip,
    aws_instance.openvpn2.public_ip
  )
}