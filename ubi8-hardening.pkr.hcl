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
    "ansible_connection" = "docker", # use docker socket instead of default SSH
    "python_version"     = "3.9"
  }
}

# the unhardened image we will use as in input
variable "input_image" {
  type = map(string)
  default = {
    "tag"     = "registry1.dso.mil/ironbank/opensource/mongodb/mongodb"
    "version" = "6.0.5"
  }
}

# how we want to tag the hardened output image
variable "output_image" {
  type = map(string)
  default = {
    "name"    = "mongo-hardened"
  }
}

variable "scan" {
  type = map(string)
  default = {
    "report_dir"             = "reports",
    "inspec_profile"         = "spec/inspec_wrapper",
    "inspec_report_filename" = "inspec_results.json",
    "inspec_input_file"      = "spec/inspec_wrapper/inputs.yml"
  }
}

variable "report" {
  type = map(string)
  default = {
    "report_to_heimdall"     = true
  }
}

source "docker" "target" {
  image       = "${var.input_image.tag}:${var.input_image.version}"
  commit      = true
  pull        = true
  run_command = ["-d", "-i", "-t", "--name", var.output_image.name, "--user", "root", "{{.Image}}", "/bin/bash"]
}

build {
  name = "harden"
  sources = [
    "source.docker.target"
  ]

  #ansible needs python and pip to be installed on the target
  provisioner "shell" {
    inline = [
      "dnf install -y python${var.ansible_vars.python_version} python3-pip",
      "ln -s /usr/bin/python3 /usr/bin/python",
    ]
  }

  provisioner "ansible" {
    playbook_file = "spec/ansible/rhel8-stig-hardening-playbook.yml"
    galaxy_file   = "spec/ansible/requirements.yml"
    extra_arguments = [ 
      "--extra-vars", "ansible_host=${var.output_image.name}",
      "--extra-vars", "ansible_connection=${var.ansible_vars.ansible_connection}",
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3",
      "--extra-vars", "ansible_pip_executable=pip3"
    ]
  }

  ### SCAN
  # use raw bash script to invoke scanning tools that don't have their own plugin
  provisioner "shell-local" {
    environment_vars = [
      "CHEF_LICENSE=accept",
      "PROFILE=${var.scan.inspec_profile}",
      "CONTAINER_ID=${var.output_image.name}",
      "REPORT_DIR=${var.scan.report_dir}",
      "REPORT_FILE=${var.scan.inspec_report_filename}",
      "INPUT_FILE=${var.scan.inspec_input_file}",
      "TARGET_IMAGE=${var.output_image.name}"
    ]
    valid_exit_codes = [0, 100, 101] # inspec has multiple valid exit codes
    scripts          = ["spec/scripts/scan.sh"]
  }

  ### REPORT
  provisioner "shell-local" {
    environment_vars = [
      "REPORT_DIR=${var.scan.report_dir}",
      "REPORT_TO_HEIMDALL=${var.report.report_to_heimdall}",
      "API_KEY=****"
    ]
    scripts          = ["spec/scripts/report.sh"]
  }

  ### VERIFY
  provisioner "shell-local" {
    environment_vars = [
      "TARGET_IMAGE=${var.output_image.name}",
      "REPORT_DIR=${var.scan.report_dir}"
    ]
    valid_exit_codes = [0, 1] # the threshold checks return 1 if the thresholds aren't met
                              # this does not mean we want to halt the run 
    scripts          = ["spec/scripts/verify_threshold.sh"]
  }

  ### TAG
  post-processor "docker-tag" {
    repository = "${var.output_image.name}"
    tags = ["latest"]
  }
}
