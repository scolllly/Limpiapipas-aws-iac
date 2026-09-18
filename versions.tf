terraform {
  required_version = ">= 1.5.0"

  # Backend remoto en S3 — el bucket y la tabla DynamoDB son creados
  # automáticamente por el stack bootstrap antes de este apply.
  # Los valores se inyectan como variables de entorno en el workflow:
  #   TF_VAR_... no aplica aqui; se usan -backend-config en terraform init.
  backend "s3" {
    # Los valores reales se pasan con -backend-config en el CI/CD.
    # Ver deploy.yml -> "Terraform Init" step.
  }

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
    }
  }
}
