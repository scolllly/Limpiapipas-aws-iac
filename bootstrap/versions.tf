terraform {
  required_version = ">= 1.5.0"

  # El bootstrap usa state LOCAL intencionalmente.
  # Los recursos tienen nombres fijos, por lo que el workflow
  # importa los recursos existentes antes de correr apply,
  # haciendo el bootstrap idempotente sin necesitar persistir state.

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
