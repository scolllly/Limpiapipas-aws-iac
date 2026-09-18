terraform {
  required_version = ">= 1.5.0"

  # El bootstrap usa state LOCAL intencionalmente.
  # El archivo terraform.tfstate generado aqui debe commitearse
  # al repositorio para que los workflows puedan reutilizarlo.

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Stack       = "bootstrap"
    }
  }
}
