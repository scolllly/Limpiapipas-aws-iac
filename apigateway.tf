# API Gateway HTTP API v2 (Publico, ligero y con 1 Millon de llamadas gratis/mes)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"
  description   = "API Gateway publico para enrutar trafico al Application Load Balancer"

  tags = {
    Name = "${var.project_name}-http-api"
  }
}

# Integracion HTTP hacia la raiz del ALB
resource "aws_apigatewayv2_integration" "alb_root" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${aws_lb.main.dns_name}/"
  integration_method     = "ANY"
  connection_type        = "INTERNET"
  payload_format_version = "1.0"
}

# Ruta para la raiz (GET /)
resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.alb_root.id}"
}

# Integracion HTTP para capturar cualquier subruta (/index.html, /assets, etc.)
resource "aws_apigatewayv2_integration" "alb_proxy" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${aws_lb.main.dns_name}/{proxy}"
  integration_method     = "ANY"
  connection_type        = "INTERNET"
  payload_format_version = "1.0"
}

# Ruta proxy dinamica ({proxy+})
resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb_proxy.id}"
}

# Stage por defecto con despliegue automatico
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Name = "${var.project_name}-default-stage"
  }
}
