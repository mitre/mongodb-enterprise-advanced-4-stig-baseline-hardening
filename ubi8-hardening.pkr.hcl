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

variable "ansible_vars" {
  type = map(string)
  default = {
    "ansible_host"        = "default",
    "ansible_connection"  = "docker", # use docker socket instead of default SSH
    "python_version"      = "3.9" 
  }
}

# the unhardened image we will use as in input
variable "input_image" {
  type = map(string)
  default = {
    "tag" = "redhat/ubi8"
    "version" = "latest"
  }
}

# how we want to tag the hardened output image
variable "output_image" {
  type = map(string)
  default = {
    "tag"       = "redhat/ubi8"
    "version"   = "latest"
    "name"      = "test-harden"
  }
}

source "docker" "target" {
  image  = "${var.input_image.tag}:${var.input_image.version}"
  commit = true
  run_command = [ "-d", "-i", "-t", "--name", var.output_image.name, "{{.Image}}", "/bin/bash" ]
}

build {
  name = "harden"
  sources = [
    "source.docker.target"
  ]

  # ansible needs python to be installed on the target
  provisioner "shell" {
    inline = [
        "yum install -y python${var.ansible_vars.python_version}",
        "ln -s /usr/bin/python3 /usr/bin/python"
    ]
  }

  provisioner "shell-local" {
    environment_vars = ["foo=bar"]
    inline  = ["sleep 3600"]
  }

  provisioner "ansible" {
      playbook_file   = "spec/ansible/rhel8-stig-hardening-playbook.yaml"
      galaxy_file     = "spec/ansible/requirements.yaml"
      extra_arguments = [
          "--extra-vars",
          "ansible_host=${var.ansible_host} ansible_connection=${var.ansible_connection} ansible_python_interpreter=/usr/bin/python3"
      ]
  }

  post-processor "docker-tag" {
    repository = "test"
    tag = ["test"]
  }


  provisioner "shell-local" {
    environment_vars = ["foo=bar"]
    scripts  = ["spec/scripts/install.sh"]
  }

  provisioner "shell-local" {
    environment_vars = ["foo=bar"]
    scripts = ["spec/scripts/scan.sh"]
  }

  provisioner "shell-local" {
    environment_vars = ["foo=bar"]
    scripts  = ["spec/scripts/report.sh"]
  }

  provisioner "shell-local" {
    environment_vars = ["foo=bar"]
    scripts  = ["spec/scripts/verify_threshold.sh"]
  }
}
