packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

variable "ansible_host" {
  default = "default"
}

variable "ansible_connection" {
  default = "docker"
}

variable "python_version" {
  default = "3.11"
}

source "docker" "ubi8" {
  image  = "redhat/ubi8:latest"
  commit = true
  run_command = [ "-d", "-i", "-t", "--name", var.ansible_host, "{{.Image}}", "/bin/bash" ]
}

build {
  name = "harden"
  sources = [
    "source.docker.ubi8"
  ]

  # ansible needs python to be installed on the target
  provisioner "shell" {
    inline = [
        "yum install -y python${var.python_version}",
        "ln -s /usr/bin/python3 /usr/bin/python"
    ]
  }

  provisioner "ansible" {
      playbook_file   = "spec/ansible/rhel8-stig-hardening-playbook.yaml"
      galaxy_file     = "spec/ansible/requirements.yaml"
      extra_arguments = [
          "--extra-vars",
          "ansible_host=${var.ansible_host} ansible_connection=${var.ansible_connection} ansible_python_interpreter=/usr/bin/python3"
      ]
  }
}
