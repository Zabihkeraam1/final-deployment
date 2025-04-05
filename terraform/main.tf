variable "customer_name" {
  description = "Unique identifier for the customer (lowercase alphanumeric only)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.customer_name))
    error_message = "Customer name must be lowercase alphanumeric with hyphens only."
  }
}

variable "app_image" {
  description = "Container image URI (ECR Public or Private)"
  type        = string
  default     = "public.ecr.aws/aws-containers/nginx:latest"
}

#variable "website_files_path" {
# description = "Path to website files for upload"
# type        = string
# default     = "./dist"
#}
variable "website_files_path" {
  description = "Path to website files (must contain index.html)"
  type        = string
  default     = "./website" # Changed default to more common directory name
}

locals {
  normalized_name   = lower(replace(var.customer_name, "/[^a-zA-Z0-9-]/", "-"))
  s3_bucket_name    = "website-${local.normalized_name}-${random_id.suffix.hex}"
  apprunner_name = "app-${local.normalized_name}-${random_id.suffix.hex}"
  cloudfront_comment = "CDN for ${local.normalized_name}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

# AWS Provider (using environment variables for credentials)
provider "aws" {
  region = "us-east-1"
}

# App Runner Configuration
resource "aws_apprunner_service" "backend" {
  service_name = "${local.apprunner_name}-${random_id.suffix.hex}"
  
  source_configuration {
    auto_deployments_enabled = false
    
    image_repository {
      image_identifier      = var.app_image
      image_repository_type = startswith(var.app_image, "public.ecr.aws") ? "ECR_PUBLIC" : "ECR"
      
      image_configuration {
        port = "3000"
        runtime_environment_variables = {
          APP_ENV = "production"
        }
      }
    }
  }

  instance_configuration {
    cpu    = "1 vCPU"
    memory = "2 GB"
  }

  tags = {
    Customer = var.customer_name
    ManagedBy = "terraform"
  }
}

# S3 Bucket for Website Files
resource "aws_s3_bucket" "frontend" {
  bucket        = local.s3_bucket_name
  force_destroy = true  # Allows easy cleanup for demo purposes

  tags = {
    Purpose    = "Website Hosting"
    Customer   = var.customer_name
    ManagedBy  = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Distribution
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = local.cloudfront_comment
}

resource "aws_s3_bucket_policy" "cdn_access" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.frontend.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = local.cloudfront_comment

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  price_class = "PriceClass_100"  # Use only North America and Europe for cost savings

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Customer   = var.customer_name
    ManagedBy  = "terraform"
  }
}

# Website Deployment Resource
resource "null_resource" "upload_website" {
  count = fileexists("${var.website_files_path}/index.html") ? 1 : 0 # Only create if index.html exists

  provisioner "local-exec" {
    command = <<-EOT
      echo "Uploading website files from ${var.website_files_path}"
      aws s3 sync ${var.website_files_path} s3://${aws_s3_bucket.frontend.id} \
        --exclude ".git/*" \
        --exclude ".DS_Store" \
        --delete
    EOT
  }

  depends_on = [
    aws_s3_bucket_policy.cdn_access
  ]
}

# Outputs
output "website_url" {
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
  description = "The URL of the deployed website"
}

output "apprunner_url" {
  value       = aws_apprunner_service.backend.service_url
  description = "The URL of the App Runner service"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.frontend.id
  description = "Name of the S3 bucket hosting website files"
}
