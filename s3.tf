resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Bucket S3 para almacenar la imagen que consumira el HTML
resource "aws_s3_bucket" "assets" {
  bucket        = "${var.project_name}-assets-${random_id.bucket_suffix.hex}"
  force_destroy = true # Permite borrar el bucket con terraform destroy aunque contenga imagenes

  tags = {
    Name = "${var.project_name}-assets"
  }
}

# Deshabilitar bloqueo estricto para permitir lectura publica de las imagenes
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Politica de lectura publica para que el navegador descargue la imagen en la plantilla HTML
resource "aws_s3_bucket_policy" "public_read" {
  bucket     = aws_s3_bucket.assets.id
  depends_on = [aws_s3_bucket_public_access_block.assets]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.assets.arn}/*"
      }
    ]
  })
}

# Configuracion CORS para que navegadores carguen la imagen sin restricciones de origen cruzado
resource "aws_s3_bucket_cors_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}
