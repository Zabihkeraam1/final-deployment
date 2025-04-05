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
  region = "us-east-1" # Change to your region
}

# 1️⃣ GitHub Connection (fully managed by Terraform)
resource "aws_apprunner_connection" "github_connection" {
  connection_name = "github-monorepo-connection"
  provider_type   = "GITHUB"
}

# 2️⃣ App Runner Service (backend folder in monorepo)
resource "aws_apprunner_service" "backend_service" {
  service_name = "monorepo-backend-service"

  source_configuration {
    authentication_configuration {
      connection_arn = aws_apprunner_connection.github_connection.arn
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

        code_configuration {
        configuration_source = "REPOSITORY"
        # Now App Runner will look for apprunner.yaml inside the repo
      }
      }
    }
  }

  instance_configuration {
    cpu    = "1024"   # 1 vCPU
    memory = "2048"   # 2 GB RAM
  }

  tags = {
    Environment = "production"
    App         = "backend"
  }
}
