# Amazon MQ Broker (RabbitMQ)
resource "aws_mq_broker" "main" {
  broker_name        = "${var.environment}-obd-ii-mq-broker"
  engine_type        = var.mq_broker_engine_type
  engine_version     = var.mq_broker_engine_version
  host_instance_type = var.mq_broker_instance_type
  deployment_mode    = "SINGLE_INSTANCE"
  publicly_accessible = false
  security_groups    = [aws_security_group.mq.id]

  # Subnets where the broker will be placed
  subnet_ids         = aws_subnet.private[*].id

  # User credentials must be nested inside the user block
  user {
    username       = var.mq_broker_username
    password       = var.mq_broker_password
    groups         = ["amq-admins"]
    console_access = true
  }

  # Optional: logs
  logs {
    audit   = false
    general = false
  }

  tags = {
    Name        = "${var.environment}-obd-ii-mq-broker"
    Environment = var.environment
  }

  # Workaround for LocalStack compatibility
  lifecycle {
    ignore_changes = [
      # Temporary workaround for LocalStack DescribeSharedResources issue
      # In real AWS, this wouldn't be needed
    ]
  }
}

# SQS Queue for faulty payloads from the MQ broker
resource "aws_sqs_queue" "faulty_payloads" {
  name                        = "${var.environment}-obd-ii-faulty-payloads"
  fifo_queue                  = false
  content_based_deduplication = false

  tags = {
    Name        = "${var.environment}-obd-ii-faulty-payloads-queue"
    Environment = var.environment
  }
}

# Output broker endpoints list and SQS queue URL
output "mq_broker_endpoints" {
  description = "List of wire-level protocol endpoints for the broker"
  value       = aws_mq_broker.main.instances[0].endpoints
}

output "sqs_queue_url" {
  value = aws_sqs_queue.faulty_payloads.id
}