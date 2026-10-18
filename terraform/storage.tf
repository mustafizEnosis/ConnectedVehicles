# S3 Bucket for driving logs
resource "aws_s3_bucket" "logs" {
  bucket = var.logs_bucket_name != "" ? var.logs_bucket_name : "${var.environment}-obd-ii-logs-${random_id.bucket_suffix.hex}"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "${var.environment}-obd-ii-logs-bucket"
    Environment = var.environment
  }
}

# Random ID for bucket name if not provided
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ECR Repository for OBD-II Replay Engine image
resource "aws_ecr_repository" "replay_engine" {
  name                 = "${var.environment}-obd-ii-replay-engine"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.environment}-obd-ii-replay-engine-repo"
    Environment = var.environment
  }
}

# Output the repository URL
output "ecr_repository_url" {
  value = aws_ecr_repository.replay_engine.repository_url
}