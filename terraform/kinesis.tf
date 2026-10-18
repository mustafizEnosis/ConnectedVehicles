# Kinesis Data Stream receiving OBD-II telemetry forwarded by the IoT topic rule
resource "aws_kinesis_stream" "telemetry" {
  name             = "${var.environment}-obd-ii-telemetry"
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_hours

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  # Server-side encryption (uses the AWS-managed aws/kinesis key)
  # encryption_type = "KMS"

  tags = {
    Name        = "${var.environment}-obd-ii-telemetry"
    Environment = var.environment
  }
}

output "kinesis_stream_name" {
  description = "Name of the Kinesis stream receiving telemetry"
  value       = aws_kinesis_stream.telemetry.name
}

output "kinesis_stream_arn" {
  description = "ARN of the Kinesis stream receiving telemetry"
  value       = aws_kinesis_stream.telemetry.arn
}
