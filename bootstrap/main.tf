# ============================================================
# Bootstrap — Infraestructura de estado remoto de Terraform
#
# Este stack se aplica UNA SOLA VEZ antes del stack principal.
# Su propio state se guarda localmente y puede commitearse al
# repositorio porque no contiene secretos ni datos sensibles.
# ============================================================

# Sufijo aleatorio para garantizar nombre de bucket globalmente unico
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  bucket_name = "${var.project_name}-tfstate-${random_id.suffix.hex}"
  table_name  = "${var.project_name}-tfstate-lock"
}

# Bucket S3 para almacenar el state del stack principal
resource "aws_s3_bucket" "tfstate" {
  bucket        = local.bucket_name
  force_destroy = false # Proteccion extra: no eliminar accidentalmente el state

  tags = {
    Name    = local.bucket_name
    Purpose = "terraform-state"
  }
}

# Versionado obligatorio para poder recuperar estados anteriores
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Cifrado en reposo con clave administrada por AWS (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloqueo total de acceso publico al bucket de state
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Tabla DynamoDB para locking del state (evita applies concurrentes)
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST" # Sin costo fijo, se cobra por operacion
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = local.table_name
    Purpose = "terraform-state-lock"
  }
}
