# MSK Cluster
resource "aws_msk_cluster" "main" {
  cluster_name           = "${var.environment}-obd-ii-msk-cluster"
  kafka_version          = "2.8.1"  # Choose a version that is supported
  number_of_broker_nodes = var.msk_number_of_broker_nodes

  broker_node_group_info {
    instance_type          = var.msk_broker_type
    client_subnets         = aws_subnet.private[*].id
    security_groups        = [aws_security_group.msk.id]
    storage_info {
      ebs_storage_info {
        volume_size = 1000  # 1 GB, adjust as needed
      }
    }
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.msk.arn
    encryption_in_transit {
      client_broker = "TLS"  # or "TLS_PLAINTEXT" to allow both, but we choose TLS for security
      in_cluster    = true
    }
  }

  tags = {
    Name        = "${var.environment}-obd-ii-msk-cluster"
    Environment = var.environment
  }
}

# KMS Key for MSK encryption at rest
resource "aws_kms_key" "msk" {
  description             = "KMS key for MSK cluster encryption at rest"
  deletion_window_in_days = 30

  tags = {
    Name        = "${var.environment}-msk-kms-key"
    Environment = var.environment
  }
}

# Allow the MSK cluster to use the KMS key
resource "aws_kms_alias" "msk" {
  name          = "alias/${var.environment}-msk-key"
  target_key_id = aws_kms_key.msk.id
}

# Output the MSK cluster ARN and bootstrap brokers
output "msk_cluster_arn" {
  value = aws_msk_cluster.main.arn
}

output "msk_bootstrap_brokers" {
  value = aws_msk_cluster.main.bootstrap_brokers_tls
}