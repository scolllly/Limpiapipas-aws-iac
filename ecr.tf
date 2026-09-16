# Repositorio ECR para alojar la imagen de la aplicacion HTML
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Permite borrar el repositorio aunque tenga imagenes al ejecutar terraform destroy

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name = "${var.project_name}-repo"
  }
}

# Politica de retencion de ciclo de vida para mantenerse estrictamente dentro de la capa gratuita (500 MB)
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Mantener unicamente la imagen mas reciente para evitar costos de almacenamiento"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
