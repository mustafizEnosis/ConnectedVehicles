terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.53.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  skip_metadata_api_check     = true
  endpoints {
    s3 = "http://host.docker.internal:4566"
    s3control = "http://host.docker.internal:4566"
    mq        = "http://host.docker.internal:4566"
  }
}