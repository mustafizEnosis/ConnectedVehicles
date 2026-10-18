# AWS IoT Topic Rule to forward telemetry to Kinesis
resource "aws_iot_topic_rule" "kinesis_forward" {
  name        = "${var.environment}_obd_ii_kinesis_forward"
  description = "Forward OBD-II telemetry from MQTT to Kinesis"

  sql         = "SELECT * FROM '${var.mqtt_topic}'"
  enabled     = true
  sql_version = "2016-03-23"

  # Kinesis action (writes each matching message as a record to the stream)
  kinesis {
    role_arn    = aws_iam_role.iot_topic_rule_kinesis.arn
    stream_name = aws_kinesis_stream.telemetry.name

    # Partition by vehicle so each vehicle's telemetry keeps its ordering across shards
    partition_key = "$${vehicle_id}"
  }

  tags = {
    Name        = "${var.environment}-obd-ii-kinesis-forward-rule"
    Environment = var.environment
  }
}
