# limpiapipas-terraform

Infraestructura como código (IaC) para el proyecto Limpiapipas Demo desplegada en AWS con Terraform y automatizada mediante GitHub Actions.

## Arquitectura

```
Internet
   │
   ▼
API Gateway HTTP API (v2)
   │  enruta todo el tráfico
   ▼
Application Load Balancer (ALB)
   │  distribuye entre tareas
   ▼
ECS Fargate (FARGATE_SPOT)
   │  contenedor de la aplicación
   ▼
S3 Bucket (assets estáticos)
```

**Recursos desplegados:**

| Recurso | Descripción |
|---|---|
| VPC + Subnets + IGW | Red privada con 2 subnets públicas en distintas AZs |
| Security Groups | ALB (80 público) + ECS (solo desde ALB) |
| ALB + Target Group | Balanceador HTTP con health check |
| API Gateway HTTP API v2 | Punto de entrada público, 1M llamadas gratis/mes |
| ECS Cluster + Service | Fargate SPOT, 0.25 vCPU / 512 MB |
| ECR Repository | Registro de imágenes Docker privado |
| CloudWatch Logs | Retención de 1 día para costo cero |
| IAM Roles | Execution role + Task role para ECS |

---

## Estructura del repositorio

```
.
├── bootstrap/                  # Stack de infraestructura de state remoto
│   ├── main.tf                 # Bucket S3 + tabla DynamoDB para Terraform state
│   ├── outputs.tf
│   ├── variables.tf
│   └── versions.tf
├── .github/
│   └── workflows/
│       ├── deploy.yml          # CI/CD: bootstrap + apply del stack principal
│       ├── destroy.yml         # Destruye solo el stack principal
│       └── destroy-bootstrap.yml  # Destruye el backend de state (limpieza total)
├── alb.tf
├── apigateway.tf
├── ecr.tf
├── ecs.tf
├── iam.tf
├── outputs.tf
├── s3.tf
├── security.tf
├── variables.tf
├── versions.tf
└── vpc.tf
```

---

## Requisitos previos (pasos manuales, una sola vez)

Antes de ejecutar cualquier workflow es necesario configurar las credenciales AWS en GitHub.

### 1. Crear usuario IAM en AWS

En la consola de AWS → IAM → Users → Create user:

- **Nombre:** `dev` (o el que prefieras)
- **Tipo de acceso:** Programmatic access (Access key)
- **Política:** Adjuntar la política del archivo `iam-policy.json` que se incluye más adelante

### 2. Configurar secrets en GitHub

En el repositorio → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Valor |
|---|---|
| `AWS_ACCESS_KEY_ID` | Access key ID del usuario IAM |
| `AWS_SECRET_ACCESS_KEY` | Secret access key del usuario IAM |
| `AWS_REGION` | Región de despliegue, ej: `us-east-1` (opcional, por defecto `us-east-1`) |

### 3. Política IAM mínima requerida

El usuario IAM necesita los siguientes permisos para poder desplegar toda la infraestructura:

<details>
<summary>Ver política completa JSON</summary>

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "STSPermissions",
      "Effect": "Allow",
      "Action": ["sts:GetCallerIdentity"],
      "Resource": "*"
    },
    {
      "Sid": "VPCAndEC2Permissions",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc", "ec2:DeleteVpc", "ec2:DescribeVpcs",
        "ec2:DescribeVpcAttribute", "ec2:ModifyVpcAttribute",
        "ec2:CreateSubnet", "ec2:DeleteSubnet", "ec2:DescribeSubnets",
        "ec2:ModifySubnetAttribute",
        "ec2:CreateInternetGateway", "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway", "ec2:DetachInternetGateway",
        "ec2:DescribeInternetGateways",
        "ec2:CreateRouteTable", "ec2:DeleteRouteTable",
        "ec2:CreateRoute", "ec2:DeleteRoute",
        "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable",
        "ec2:DescribeRouteTables",
        "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress",
        "ec2:DescribeSecurityGroups", "ec2:DescribeSecurityGroupRules",
        "ec2:DescribeAvailabilityZones",
        "ec2:CreateTags", "ec2:DeleteTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ALBPermissions",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:CreateLoadBalancer", "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DescribeLoadBalancers", "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:CreateTargetGroup", "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DescribeTargetGroups", "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:ModifyTargetGroup", "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:CreateListener", "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DescribeListeners", "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:DescribeListenerAttributes", "elasticloadbalancing:ModifyListenerAttributes",
        "elasticloadbalancing:AddTags", "elasticloadbalancing:RemoveTags",
        "elasticloadbalancing:DescribeTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECSPermissions",
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster", "ecs:DeleteCluster", "ecs:DescribeClusters",
        "ecs:PutClusterCapacityProviders",
        "ecs:RegisterTaskDefinition", "ecs:DeregisterTaskDefinition", "ecs:DescribeTaskDefinition",
        "ecs:CreateService", "ecs:UpdateService", "ecs:DeleteService", "ecs:DescribeServices",
        "ecs:ListTagsForResource", "ecs:TagResource", "ecs:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRPermissions",
      "Effect": "Allow",
      "Action": [
        "ecr:CreateRepository", "ecr:DeleteRepository", "ecr:DescribeRepositories",
        "ecr:PutLifecyclePolicy", "ecr:GetLifecyclePolicy", "ecr:DeleteLifecyclePolicy",
        "ecr:GetRepositoryPolicy", "ecr:SetRepositoryPolicy", "ecr:DeleteRepositoryPolicy",
        "ecr:ListTagsForResource", "ecr:TagResource", "ecr:UntagResource",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage",
        "ecr:PutImage", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3Permissions",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket",
        "s3:GetBucketPolicy", "s3:PutBucketPolicy", "s3:DeleteBucketPolicy",
        "s3:GetBucketPublicAccessBlock", "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketCors", "s3:PutBucketCors", 
        "s3:GetBucketTagging", "s3:PutBucketTagging", 
        "s3:GetBucketVersioning", "s3:PutBucketVersioning",
        "s3:GetBucketObjectLockConfiguration",
        "s3:GetLifecycleConfiguration", "s3:PutLifecycleConfiguration",
        "s3:GetBucketLogging", "s3:GetAccelerateConfiguration",
        "s3:GetBucketRequestPayment", "s3:GetEncryptionConfiguration",
        "s3:PutEncryptionConfiguration",
        "s3:GetObject", "s3:PutObject", "s3:DeleteObject",
        "s3:GetBucketAcl", "s3:PutBucketAcl",
        "s3:GetBucketWebsite", "s3:PutBucketWebsite", "s3:DeleteBucketWebsite",
        "s3:GetBucketNotification", "s3:PutBucketNotification",
        "s3:GetReplicationConfiguration", "s3:PutReplicationConfiguration",
        "s3:GetAnalyticsConfiguration", "s3:GetMetricsConfiguration",
        "s3:GetInventoryConfiguration"
      ],
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Sid": "DynamoDBPermissions",
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable",
        "dynamodb:DescribeTimeToLive",
        "dynamodb:DescribeContinuousBackups",
        "dynamodb:ListTagsOfResource",
        "dynamodb:TagResource",
        "dynamodb:UntagResource",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ServiceLinkedRoles",
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "iam:AWSServiceName": [
            "elasticloadbalancing.amazonaws.com",
            "ecs.amazonaws.com"
          ]
        }
      }
    },
    {
      "Sid": "APIGatewayV2Permissions",
      "Effect": "Allow",
      "Action": [
        "apigateway:GET", "apigateway:POST", "apigateway:PUT",
        "apigateway:PATCH", "apigateway:DELETE"
      ],
      "Resource": [
        "arn:aws:apigateway:*::/*",
        "arn:aws:apigateway:*:*:*"
      ]
    },
    {
      "Sid": "CloudWatchLogsPermissions",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup", "logs:DeleteLogGroup", "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy", "logs:DeleteRetentionPolicy",
        "logs:ListTagsForResource", "logs:ListTagsLogGroup",
        "logs:TagResource", "logs:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPermissionsForECS",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole", "iam:DeleteRole", "iam:GetRole",
        "iam:TagRole", "iam:UntagRole", "iam:ListRoleTags",
        "iam:ListRolePolicies", "iam:GetRolePolicy",
        "iam:ListInstanceProfilesForRole", "iam:ListAttachedRolePolicies",
        "iam:CreatePolicy", "iam:DeletePolicy",
        "iam:GetPolicy", "iam:GetPolicyVersion", "iam:ListPolicyVersions",
        "iam:AttachRolePolicy", "iam:DetachRolePolicy"
      ],
      "Resource": [
        "arn:aws:iam::*:role/limpiapipas-demo-*",
        "arn:aws:iam::*:policy/limpiapipas-demo-*"
      ]
    },
    {
      "Sid": "IAMPassRoleForECS",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::*:role/limpiapipas-demo-*",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "ecs-tasks.amazonaws.com"
        }
      }
    }
  ]
}
```

</details>

> **Nota:** También se añadió `DynamoDBPermissions` requerido por el bootstrap para crear y usar la tabla de state locking.

---

## Cómo desplegar la infraestructura

### Automático (recomendado)

El despliegue completo es totalmente automático. El workflow:

1. Aplica el **bootstrap** (crea bucket S3 + tabla DynamoDB para el state remoto si no existen)
2. Lee los outputs del bootstrap para configurar el backend dinámicamente
3. Corre `terraform fmt -check`, `init`, `validate`, `plan` y `apply` del stack principal

**Trigger automático:** cualquier push a la rama `main`.

**Trigger manual:**
1. Ir a Actions → **Deploy Terraform to AWS** → Run workflow → Run workflow

Al finalizar, el job summary muestra las URLs y nombres de los recursos creados.

### Secuencia interna del workflow

```
bootstrap/terraform init
bootstrap/terraform apply       ← crea bucket tfstate + DynamoDB (idempotente)
        │
        └─ outputs: bucket_name, table_name, region
                │
                ▼
terraform init -backend-config=...   ← configura backend S3 dinámicamente
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

---

## Cómo destruir la infraestructura

### Destruir solo el stack principal (mantiene el backend de state)

Usar este flujo para limpiar costos sin perder la capacidad de volver a desplegar.

1. Ir a Actions → **Destroy AWS Infrastructure** → Run workflow
2. En el campo de confirmación escribir exactamente: `destroy`
3. Hacer clic en **Run workflow**

Los recursos destruidos incluyen: VPC, ALB, ECS, ECR, S3 assets, API Gateway, CloudWatch Logs, IAM roles.

El bucket de state y la tabla DynamoDB **se conservan**.

### Destruir todo (incluyendo el backend de state)

Usar este flujo solo cuando se quiere eliminar absolutamente todo de AWS.

> **Importante:** ejecutar primero el destroy del stack principal antes de destruir el bootstrap.

1. Asegurarse de haber corrido **Destroy AWS Infrastructure** primero
2. Ir a Actions → **Destroy Bootstrap (State Backend)** → Run workflow
3. En el campo de confirmación escribir exactamente: `destroy-bootstrap`
4. Hacer clic en **Run workflow**

### Resumen de flujos

```
Solo limpiar costos (re-deployable):
  Destroy AWS Infrastructure  →  escribe "destroy"

Limpieza total e irreversible:
  Destroy AWS Infrastructure  →  escribe "destroy"
  Destroy Bootstrap           →  escribe "destroy-bootstrap"
```

---

## Variables de configuración

Las variables del stack principal se encuentran en `variables.tf`. Los valores por defecto están orientados a costo mínimo (capa gratuita de AWS).

| Variable | Default | Descripción |
|---|---|---|
| `aws_region` | `us-east-1` | Región AWS |
| `project_name` | `limpiapipas-demo` | Prefijo de todos los recursos |
| `environment` | `dev` | Etiqueta de ambiente |
| `container_port` | `80` | Puerto del contenedor ECS |
| `container_image` | `public.ecr.aws/docker/library/httpd:alpine` | Imagen inicial de prueba |
| `desired_task_count` | `1` | Número de tareas ECS |
| `fargate_cpu` | `256` | CPU Fargate (0.25 vCPU) |
| `fargate_memory` | `512` | Memoria Fargate (512 MB) |

Para sobreescribir valores sin modificar el código, crear un archivo `terraform.tfvars` (ignorado por git) o pasar `-var` en el workflow.

---

## State remoto

El state de Terraform se almacena en S3 con locking via DynamoDB, gestionado automáticamente por el stack bootstrap:

| Recurso | Nombre |
|---|---|
| Bucket S3 | `limpiapipas-demo-tfstate-<sufijo>` |
| Tabla DynamoDB | `limpiapipas-demo-tfstate-lock` |
| Clave del state | `terraform.tfstate` |

El state del propio bootstrap se guarda localmente en `bootstrap/terraform.tfstate` y está commiteado en el repositorio. No contiene secretos, solo IDs de recursos de infraestructura de soporte.
