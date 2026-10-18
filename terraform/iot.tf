# AWS IoT Topic Rule to forward telemetry to MSK
resource "aws_iot_topic_rule" "msk_forward" {
  name        = "${var.environment}_obd_ii_msk_forward"
  description = "Forward OBD-II telemetry from MQTT to MSK"

  # Simple syntax attributes (required)
  sql         = "SELECT * FROM '${var.mqtt_topic}'"
  enabled     = true
  sql_version = "2016-03-23"

  # Kafka action block (for sending data to MSK)
  kafka {
    destination_arn = aws_msk_cluster.main.arn
    topic           = var.mqtt_topic
    key             = ""
    partition       = ""

    # Required by Terraform's kafka block for producer client config
    client_properties = {
      "bootstrap.servers" = aws_msk_cluster.main.bootstrap_brokers_sasl_iam
    }
  }

  tags = {
    Name        = "${var.environment}-obd-ii-msk-forward-rule"
    Environment = var.environment
  }
}