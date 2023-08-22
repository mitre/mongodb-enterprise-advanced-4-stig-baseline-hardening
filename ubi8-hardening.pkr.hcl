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
    inspec = {
      source  = "github.com/hashicorp/inspec"
      version = "~> 1"
    }
  }
}

variable "ansible_vars" {
  type = map(string)
  default = {
    "ansible_host"       = "default",
    "ansible_connection" = "docker", # use docker socket instead of default SSH
    "python_version"     = "3.9"
  }
}

# the unhardened image we will use as in input
variable "input_image" {
  type = map(string)
  default = {
    "tag"     = "redhat/ubi8"
    "version" = "latest"
  }
}

# how we want to tag the hardened output image
variable "output_image" {
  type = map(string)
  default = {
    "tag"     = "redhat/ubi8"
    "version" = "latest"
    "name"    = "test-harden"
  }
}

variable "scan" {
  type = map(string)
  default = {
    "report_dir"             = "./reports",
    "inspec_profile"         = "spec/inspec_profile",
    "inspec_report_filename" = "inspec_results.json",
    "inspec_input_file"      = "spec/inspec_profile/inputs.yml"
  }
}

source "docker" "target" {
  image       = "${var.input_image.tag}:${var.input_image.version}"
  commit      = true
  run_command = ["-d", "-i", "-t", "--name", var.output_image.name, "{{.Image}}", "/bin/bash"]
}

build {
  name = "harden"
  sources = [
    "source.docker.target"
  ]

  # ansible needs python and pip to be installed on the target
  provisioner "shell" {
    inline = [
      "dnf install -y python${var.ansible_vars.python_version} python3-pip",
      "ln -s /usr/bin/python3 /usr/bin/python",
    ]
  }

  provisioner "ansible" {
    playbook_file = "spec/ansible/rhel8-stig-hardening-playbook.yaml"
    galaxy_file   = "spec/ansible/requirements.yaml"
    extra_arguments = [ 
      "--extra-vars", "ansible_host=${var.output_image.name}",
      "--extra-vars", "ansible_connection=${var.ansible_vars.ansible_connection}",
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3",
      "--extra-vars", "ansible_pip_executable=pip3"
    ]
  }

  provisioner "shell-local" {
    environment_vars = ["foo=bar"]
    scripts          = ["spec/scripts/install.sh"]
  }

  # use inspec plugin for compliance scanning
  #provisioner "inspec" {
  #  inspec_env_vars = ["CHEF_LICENSE=accept"]
  #  backend         = "docker"
  #  host    = "${var.output_image.name}"
  #  profile         = "${var.scan.inspec_profile}"
  #  attributes      = ["${var.scan.inspec_input_file}"]
  #  extra_arguments = [
  #    "--reporter", "cli", "json:${var.scan.report_dir}/${var.scan.inspec_report_filename}"
  #  ]
  #}

  # use raw bash script to invoke scanning tools that don't have their own plugin
  provisioner "shell-local" {
    environment_vars = ["targetImage=${var.output_image.name}:latest"]
    scripts          = ["spec/scripts/scan.sh"]
  }

  provisioner "shell-local" {
    environment_vars = ["outputFile=scanHDF.json"]
    scripts          = ["spec/scripts/report.sh"]
  }

  provisioner "shell-local" {
    environment_vars = ["outputFile=scanHDF.json"]
    scripts          = ["spec/scripts/verify_threshold.sh"]
  }
}
