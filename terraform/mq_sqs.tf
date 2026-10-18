# Amazon MQ Broker (ActiveMQ)
resource "aws_mq_broker" "main" {
  broker_name           = "${var.environment}-obd-ii-mq-broker"
  engine_type           = var.mq_broker_engine_type
  engine_version        = var.mq_broker_engine_version
  host_instance_type    = var.mq_broker_instance_type
  deployment_mode       = "SINGLE_INSTANCE"  # or STANDARD_ACTIVE for HA, but we use SINGLE_INSTANCE for dev
  publicly_accessible   = false  # We want it private, accessible only from within the VPC
  security_groups       = [aws_security_group.mq.id]

  # Subnets where the broker will be placed
  subnet_ids            = aws_subnet.private[*].id

  # User credentials
  username              = var.mq_broker_username
  password              = var.mq_broker_password

  # Optional: logs
  logs {
    audit           = false
    general         = false
  }

  tags = {
    Name        = "${var.environment}-obd-ii-mq-broker"
    Environment = var.environment
  }
}

# SQS Queue for faulty payloads from the MQ broker
resource "aws_sqs_queue" "faulty_payloads" {
  name                  = "${var.environment}-obd-ii-faulty-payloads"
  fifo_queue            = false
  content_based_deduplication = false

  tags = {
    Name        = "${var.environment}-obd-ii-faulty-payloads-queue"
    Environment = var.environment
  }
}

# Output the broker endpoint and SQS queue URL
output "mq_broker_endpoint" {
  value = aws_mq_broker.main.endpoints["STOMP"]  # or "SSL", etc. We'll output the STOMP endpoint for ActiveMQ
}

output "sqs_queue_url" {
  value = aws_sqs_queue.faulty_payloads.id
}