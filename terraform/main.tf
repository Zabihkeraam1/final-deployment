variable "customer_name" {
  type        = string
  description = "Name of the customer"
}

variable "app_image" {
  type        = string
  description = "Docker image (not used if deploying from source)"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "apprunner_role" {
  name = "apprunner-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "build.apprunner.amazonaws.com"
      }
    }]
  })
}

resource "aws_apprunner_service" "backend_service" {
  service_name = "monorepo-backend-service"

  source_configuration {
    authentication_configuration {
      connection_arn = "arn:aws:apprunner:us-east-1:135808921133:connection/app-runner/234318073f4f44bca1591d8b1b97fe9d"
    }

    auto_deployments_enabled = true

    code_repository {
      repository_url = "https://github.com/Zabihkeraam1/final-deployment.git"
      source_code_version {
        type  = "BRANCH"
        value = "master"
      }

      code_configuration {
        configuration_source = "API"
        code_configuration_values {
          runtime        = "NODEJS_18"
          build_command  = "cd Backend && npm install --production"
          start_command  = "cd Backend && node server.js"
          port           = 8080
        }
      }
    }
  }

  instance_configuration {
    instance_role_arn = aws_iam_role.apprunner_role.arn
    cpu               = "1024"
    memory            = "2048"
  }

  tags = {
    Environment = "production"
    App         = "backend"
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 5
  }
}
