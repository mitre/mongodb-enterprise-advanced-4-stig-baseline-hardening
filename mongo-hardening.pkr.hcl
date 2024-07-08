packer {
  required_plugins {
    docker = {
      version = " >= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

variable "ansible_vars" {
  type = map(string)
  default = {
    "ansible_host"       = "default",
    # "ansible_connection" uses the docker socket instead of the default SSH connection.
    "ansible_connection" = "docker",
    "python_version"     = "3.9"
    "roles_path"         = "spec/ansible/roles"
  }
}

# Specifies the unhardened image to be used as an input.
variable "input_image" {
  type = map(string)
  default = {
    "name"  = "mongodb/mongodb-enterprise-server"
    "tag"   = "latest"
  }
}

# Defines the naming convention for the hardened output image.
variable "output_image" {
  type = map(string)
  default = {
    "name"    = "mongo-hardened"
  }
}

# Docker container to harden
source "docker" "target" {
  image       = "${var.input_image.name}:${var.input_image.tag}"
  commit      = true
  pull        = true
  run_command = [
    "-d",
    "--name", "${var.output_image.name}",
    "--user", "root",
    "-p", "27017:27017",
    "-v", "mongodb_configdb:/data/configdb",
    "-v", "mongodb_db:/data/db",
    "{{.Image}}"
  ]
}

# Run the process to harden the docker container
build {
  name    = "harden"
  sources = ["source.docker.target"]

  # Create docker volumes
  provisioner "shell-local" {
    inline = [
      "docker volume create mongodb_configdb",
      "docker volume create mongodb_db",
    ]
  }

  # Ansible requires Python and pip to be installed on the target.
  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get install -y python${var.ansible_vars.python_version} python3-pip",
      "ln -s /usr/bin/python3 /usr/bin/python",
    ]
  }

  # Run Ansible playbook
  provisioner "ansible" {
    playbook_file = "spec/ansible/mongo-stig-hardening-playbook.yml"
    galaxy_file   = "spec/ansible/requirements.yml"
    roles_path    = "${var.ansible_vars.roles_path}"
    extra_arguments = [ 
      "--extra-vars", "ansible_host=${var.output_image.name}",
      "--extra-vars", "ansible_connection=${var.ansible_vars.ansible_connection}",
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3",
      "--extra-vars", "ansible_pip_executable=pip3",
    ]
  }

  ### TAG DOCKER IMAGE
  post-processor "docker-tag" {
    repository = "${var.output_image.name}"
    tags = ["latest"]
  }

}
