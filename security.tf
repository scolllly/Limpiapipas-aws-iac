# Security Group para el Application Load Balancer (ALB)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Permite trafico HTTP entrante hacia el ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde cualquier origen"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Permite todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Security Group para las tareas de ECS Fargate
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Aisla las tareas de ECS permitiendo trafico unicamente desde el ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Trafico desde el ALB al puerto del contenedor"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Permite salida a Internet para descargar imagen de ECR y APIs AWS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}
