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
  default = "3.9"
}

variable "base_image" {
  default = "redhat/ubi8:latest"
}

source "docker" "target" {
  image  = "${var.base_image}"
  commit = true
  run_command = [ "-d", "-i", "-t", "--name", var.ansible_host, "{{.Image}}", "/bin/bash" ]
}

build {
  name = "harden"
  sources = [
    "source.docker.target"
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

  provisioner "shell" {
    environment_vars = [""]
    scripts  = ["spec/scripts/install.sh"]
  }

  provisioner "shell-local" {
    environment_vars = [""]
    scripts = ["spec/scripts/scan.sh"]
  }

  provisioner "shell-local" {
    environment_vars = [""]
    scripts  = ["spec/scripts/report.sh"]
  }

  provisioner "shell-local" {
    environment_vars = [""]
    scripts  = ["spec/scripts/verify_threshold.sh"]
  }
}
