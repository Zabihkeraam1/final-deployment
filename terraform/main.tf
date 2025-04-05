resource "aws_apprunner_service" "backend_service" {
  service_name = "monorepo-backend-service"

  source_configuration {
    authentication_configuration {
      connection_arn = "arn:aws:apprunner:us-east-1:135808921133:connection/app-runner/234318073f4f44bca1591d8b1b97fe9d"
    }

    auto_deployments_enabled = true

    image_repository {
      image_repository_type = "ECR_PUBLIC"
      image_identifier      = "public.ecr.aws/aws-apprunner/example/nodejs18:latest" # Base image
    }

    # Remove code_repository block
  }

  instance_configuration {
    cpu    = "1024"
    memory = "2048"
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/health"
    interval            = 25
    timeout             = 20
    healthy_threshold   = 3
    unhealthy_threshold = 5
  }
}
