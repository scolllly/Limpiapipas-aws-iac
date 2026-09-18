output "api_gateway_url" {
  description = "URL publica principal del API Gateway (Punto de entrada recomendado)"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "alb_dns_name" {
  description = "DNS directo del Application Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR para docker tag y docker push"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_login_command" {
  description = "Comando AWS CLI para autenticar Docker contra el repositorio ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}"
}
