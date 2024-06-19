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

# Specifies the hardened image to be used as an input.
variable "input_hardened_image" {
  type = map(string)
  default = {
    "name"  = "mongo-hardened"
    "tag"   = "latest"
  }
}

variable "scan" {
  type = map(string)
  default = {
    "report_dir"             = "reports",
    "inspec_profile"         = "spec/mongo-inspec-profile",
    "inspec_report_filename" = "inspec_results.json",
    "inspec_input_file"      = "spec/mongo-inspec-profile/inputs.yml"
  }
}

variable "report" {
  type = map(string)
  default = {
    "report_to_heimdall"     = true
    "heimdall_url"           = "https://heimdall-demo.mitre.org/evaluations"
    "heimdall_api_key"       = "" 
  }
}

# Hardened docker container to be validated
source "docker" "hardened" {
  image       = "${var.input_hardened_image.name}:${var.input_hardened_image.tag}"
  commit      = false
  pull        = false
  discard     = true
  run_command = [
    "-d",
    "--name", "${var.input_hardened_image.name}",
    "-p", "27017:27017",
    "-v", "mongodb_configdb:/data/configdb",
    "-v", "mongodb_db:/data/db",
    "-e", "PATH=/usr/local/src/openssl-3.1.0/apps:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    "-e", "LD_LIBRARY_PATH=/usr/local/src/openssl-3.1.0",
    "{{.Image}}",
    "mongod", "--config", "/etc/mongod.conf"
  ]
}

# Run validation process
build {
  name    = "validate"
  sources = ["source.docker.hardened"]

  provisioner "shell-local" {
    environment_vars = [
      "CHEF_LICENSE=accept",
      "PROFILE=${var.scan.inspec_profile}",
      "CONTAINER_ID=${var.input_hardened_image.name}",
      "REPORT_DIR=${var.scan.report_dir}",
      "REPORT_FILE=${var.scan.inspec_report_filename}",
      "INPUT_FILE=${var.scan.inspec_input_file}",
      "TARGET_IMAGE=${var.input_hardened_image.name}",
    ]
    valid_exit_codes = [0, 100, 101] # inspec has multiple valid exit codes
    script           = "spec/scripts/scan.sh"
  }

  // ### REPORT
  // provisioner "shell-local" {
  //   environment_vars = [
  //     "REPORT_DIR=${var.scan.report_dir}",
  //     "REPORT_TO_HEIMDALL=${var.report.report_to_heimdall}",
  //     "HEIMDALL_URL=${var.report.heimdall_url}",
  //     "HEIMDALL_API_KEY=${var.report.heimdall_api_key}"
  //   ]
  //   scripts          = ["spec/scripts/report.sh"]
  // }

  // ### VERIFY
  // provisioner "shell-local" {
  //   environment_vars = [
  //     "TARGET_IMAGE=${var.input_hardened_image.name}",
  //     "REPORT_DIR=${var.scan.report_dir}"
  //   ]
  //   valid_exit_codes = [0, 1] # the threshold checks return 1 if the thresholds aren't met
  //                             # this does not mean we want to halt the run 
  //   scripts          = ["spec/scripts/verify_threshold.sh"]
  // }

  // provisioner "shell" {
  //   inline = [
  //     "docker stop ${var.input_hardened_image.name}",
  //     //"docker rm ${var.input_hardened_image.name}"
  //   ]
  // }
}