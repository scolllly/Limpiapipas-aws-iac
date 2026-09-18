variable "aws_region" {
  description = "Region de AWS donde se crearan los recursos de bootstrap"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto, usado como prefijo de los recursos"
  type        = string
  default     = "limpiapipas-demo"
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "dev"
}
