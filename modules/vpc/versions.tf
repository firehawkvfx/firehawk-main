terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.15.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  required_version = ">= 0.13"
}