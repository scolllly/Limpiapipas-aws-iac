# Infraestructura Demo AWS con Terraform (Costo Mínimo / Capa Gratuita)

Este repositorio contiene la Infraestructura como Código (IaC) en Terraform para desplegar una arquitectura completa en AWS optimizada para **costo mínimo** (compatible con AWS Free Tier o céntimos de dólar para pruebas).

## Arquitectura

```
[Usuario / Navegador]
        │
        ▼
[API Gateway (HTTP API v2 Público)]
        │
        ▼
[Application Load Balancer (ALB)]
        │
        ▼
[ECS Fargate (Subredes Públicas sin NAT Gateway)]
        │
        ├── Descarga imagen ──► [ECR (Retención 1 imagen)]
        └── Referencia HTML  ──► [S3 Bucket Público con CORS]
```

### Componentes Incluidos

1. **API Gateway (HTTP API v2 Público)**: Punto de entrada público ultraligero y de latencia mínima. 1 Millón de peticiones gratis al mes.
2. **Application Load Balancer (ALB)**: Balanceador de carga en 2 zonas de disponibilidad (incluido en Free Tier por 750 h/mes los primeros 12 meses).
3. **ECS Cluster con Fargate Spot**: Contenedor con tamaño mínimo (0.25 vCPU y 0.5 GB RAM) utilizando capacidad Spot (~$0.004/hora).
4. **AWS ECR Privado**: Repositorio de imágenes Docker con política de ciclo de vida para retener solo 1 imagen (evitando superar los 500 MB gratuitos).
5. **AWS S3**: Almacenamiento de objetos con CORS y política de lectura pública para servir la imagen directamente al navegador cuando la plantilla HTML la renderice.
6. **VPC sin NAT Gateway**: Ahorro inmediato de ~$32 USD/mes. Las tareas tienen IP pública para descargar la imagen de ECR, pero su Security Group bloquea todo tráfico entrante salvo el originado por el ALB.

---

## Prerrequisitos

- [Terraform](https://www.terraform.io/downloads) (>= 1.5.0)
- [AWS CLI](https://aws.amazon.com/cli/) configurado (`aws configure`) con credenciales y región adecuada.
- [Docker](https://www.docker.com/) (para compilar y subir la imagen al ECR).

---

## Guía Paso a Paso de Despliegue

### 1. Inicializar Terraform

```bash
terraform init
```

### 2. Revisar el Plan de Ejecución

```bash
terraform plan
```

### 3. Aplicar la Infraestructura

```bash
terraform apply -auto-approve
```

Al finalizar, Terraform mostrará los outputs con las URLs y nombres de recursos creados:
- `api_gateway_url`: URL pública principal para ingresar a la demo.
- `alb_dns_name`: URL directa al balanceador.
- `ecr_repository_url`: URI del repositorio ECR.
- `s3_bucket_name`: Nombre del bucket S3 para la imagen.
- `sample_image_url`: Ejemplo de URL para referenciar la imagen en el HTML.

---

## Cómo Probar la Demo (S3 y Contenedor HTML)

### 1. Subir la imagen a S3

Sube cualquier imagen (por ejemplo `demo.png`) al bucket creado:

```bash
aws s3 cp demo.png s3://<NOMBRE_DEL_BUCKET>/demo.png
```

La imagen estará disponible públicamente en:
`https://<NOMBRE_DEL_BUCKET>.s3.<REGION>.amazonaws.com/demo.png`

### 2. Construir y Subir tu Contenedor HTML al ECR

Supongamos que tienes un `Dockerfile` y un `index.html` simple que hace:
```html
<!DOCTYPE html>
<html>
<body>
  <h1>Demo Limpiapipas</h1>
  <img src="https://<NOMBRE_DEL_BUCKET>.s3.<REGION>.amazonaws.com/demo.png" alt="Imagen S3" />
</body>
</html>
```

Ejecuta los siguientes comandos para subir tu imagen a ECR:

```bash
# 1. Autenticar Docker con ECR (puedes copiar el comando exacto desde el output 'ecr_login_command')
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REPOSITORY_URL>

# 2. Construir la imagen
docker build -t limpiapipas-demo .

# 3. Etiquetar la imagen para ECR
docker tag limpiapipas-demo:latest <ECR_REPOSITORY_URL>:latest

# 4. Subir la imagen
docker push <ECR_REPOSITORY_URL>:latest
```

### 3. Actualizar el Servicio ECS con la Nueva Imagen

Para indicarle a ECS que utilice tu imagen de ECR recién subida:

```bash
aws ecs update-service \
  --cluster limpiapipas-demo-cluster \
  --service limpiapipas-demo-service \
  --force-new-deployment
```

### 4. Acceder a la Aplicación

Abre en tu navegador la URL devuelta en `api_gateway_url`:
```
https://<api-id>.execute-api.us-east-1.amazonaws.com
```

Verás tu plantilla HTML cargada a través del API Gateway, pasando por el ALB, ejecutada en ECS Fargate, dibujando la imagen alojada en S3.

---

## Destruir Recursos (Para Costo Cero al Terminar)

Cuando termines tu demostración o pruebas, destruye toda la infraestructura para evitar cualquier cobro residual:

```bash
terraform destroy -auto-approve
```
