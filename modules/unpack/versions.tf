terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~>2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~>4"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~>2.22"
    }
    local = {
      source = "hashicorp/local"
      version = "~>2"
    }
  }
}

