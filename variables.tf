variable "aws_region" {
  description = "Region de AWS donde se desplegaran los recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre identificador del proyecto para prefijos de recursos"
  type        = string
  default     = "limpiapipas-demo"
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "container_port" {
  description = "Puerto en el que escucha el contenedor dentro de ECS"
  type        = number
  default     = 80
}

variable "container_image" {
  description = "Imagen inicial de prueba para ECS Task antes de compilar y subir a ECR"
  type        = string
  default     = "public.ecr.aws/docker/library/httpd:alpine"
}

variable "desired_task_count" {
  description = "Numero deseado de tareas ECS (1 para mantener costo minimo)"
  type        = number
  default     = 1
}

variable "fargate_cpu" {
  description = "Unidades de CPU para la tarea Fargate (256 = 0.25 vCPU, minimo permitido)"
  type        = string
  default     = "256"
}

variable "fargate_memory" {
  description = "Memoria en MB para la tarea Fargate (512 = 0.5 GB, minimo permitido)"
  type        = string
  default     = "512"
}
