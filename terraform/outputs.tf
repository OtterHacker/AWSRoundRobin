locals{
    ansible = format("%s",
        local.roundrobin_ansible,
    )
}

output "ansible_hosts" {
  value = format(
    "Creating the following host.yml file:\nall:\n  hosts:\n%s",
    local.ansible
  )
}

resource "local_file" "instance_details" {
  content = format(
    "all:\n  hosts:\n%s",
    local.ansible
  )
  filename = "hosts.yml"
}
