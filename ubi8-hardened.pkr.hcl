packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "ubi8" {
  image  = "redhat/ubi8:latest"
  commit = true
}

build {
  name    = "harden"
  sources = [
    "source.docker.ubi8"
  ]
}
