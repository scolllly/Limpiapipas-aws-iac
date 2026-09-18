output "state_bucket_name" {
  description = "Nombre del bucket S3 que almacena el state del stack principal"
  value       = local.bucket_name
}

output "state_bucket_arn" {
  description = "ARN del bucket S3 de state"
  value       = aws_s3_bucket.tfstate.arn
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB usada para el locking del state"
  value       = local.table_name
}

output "aws_region" {
  description = "Region AWS donde se crearon los recursos del bootstrap"
  value       = var.aws_region
}
