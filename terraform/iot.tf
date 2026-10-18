# AWS IoT Topic Rule to forward telemetry to MSK
resource "aws_iot_topic_rule" "msk_forward" {
  name        = "${var.environment}-obd-ii-msk-forward"
  description = "Forward OBD-II telemetry from MQTT to MSK"

  sql         = "SELECT * FROM '${var.mqtt_topic}'"

  # We'll use the MSK action
  action {
    kafka {
      destination_arn = aws_msk_cluster.main.arn
      topic           = var.mqtt_topic  # Kafka topic name
      key             = ""  # Optional key
      partition       = ""  # Optional partition
    }
  }

  # IAM role for the rule to assume (to access MSK)
  role_arn = aws_iam_role.iot_topic_rule_msk.arn

  tags = {
    Name        = "${var.environment}-obd-ii-msk-forward-rule"
    Environment = var.environment
  }
}