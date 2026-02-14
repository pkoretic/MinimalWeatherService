terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

# ---------------------------------------------------------
# BACKEND CONFIGURATION
# ---------------------------------------------------------
  backend "s3" {
    bucket = "mkoretic-minimalweatherservice-state"
    key    = "minimalweatherservice/terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}

# ---------------------------------------------------------
# VARIABLES
# ---------------------------------------------------------
variable "weather_api_key" {
  description = "The Weather API Key (passed from GitHub Secrets)"
  type        = string
  sensitive   = true
}

variable "image_tag" {
  description = "The docker image tag to deploy"
  type        = string
  default     = "latest"
}

# ---------------------------------------------------------
# 1. ECR REPOSITORY
# ---------------------------------------------------------
resource "aws_ecr_repository" "service_repo" {
  name                 = "mkoretic/minimalweatherservice"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
}

# ---------------------------------------------------------
# 2. IAM ROLE (App Runner -> ECR Access)
# ---------------------------------------------------------
resource "aws_iam_role" "apprunner_role" {
  name = "AppRunnerECRAccessRole-TF"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_access" {
  role       = aws_iam_role.apprunner_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# ---------------------------------------------------------
# 3. APP RUNNER SERVICE
# ---------------------------------------------------------
resource "aws_apprunner_service" "weather_service" {
  service_name = "MinimalWeatherService"

  # We strictly depend on the Policy Attachment.
  # If the Role exists but has no permissions yet, App Runner creation will fail.
  depends_on = [aws_iam_role_policy_attachment.apprunner_ecr_access]

  source_configuration {
    auto_deployments_enabled = true

    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_role.arn
    }

    image_repository {
      image_repository_type = "ECR"
      # Constructs the URI: <account_id>.dkr.ecr.<region>.amazonaws.com/repo:tag
      image_identifier      = "${aws_ecr_repository.service_repo.repository_url}:${var.image_tag}"

      image_configuration {
        port = "8080"
        runtime_environment_variables = {
          "WeatherApi__ApiKey" = var.weather_api_key
        }
      }
    }
  }

  instance_configuration {
    cpu    = "256" # 0.25 vCPU
    memory = "512" # 512 MB
  }

  health_check_configuration {
    protocol            = "TCP"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }

  network_configuration {
    ingress_configuration {
      is_publicly_accessible = true
    }
    egress_configuration {
      egress_type = "DEFAULT"
    }
  }
}

# ---------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------
output "service_url" {
  description = "The public URL of the App Runner service"
  value       = aws_apprunner_service.weather_service.service_url
}

output "ecr_repo_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.service_repo.repository_url
}
