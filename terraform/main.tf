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
  region = "us-east-1" # Change to your region
}

# 1️⃣ App Runner Service (backend folder in monorepo)
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
          configuration_source = "API"  # Use "API" if using apprunner.yaml
        code_configuration_values {
          runtime = "NODEJS_18"       # Node.js 18
          build_command = "cd backend && npm install"
          start_command = "cd backend && npm start"
          port = "8080"               # Your app's port
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
