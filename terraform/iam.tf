# IAM Role for ECS task execution (for pulling images and CloudWatch logs)
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_execution_AmazonEC2ContainerServiceforEC2Role" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# IAM Role for ECS task (for the container to access S3 and IoT Core)
resource "aws_iam_role" "ecs_task" {
  name = "${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Policy for ECS task to read from S3 bucket
resource "aws_iam_policy" "ecs_task_s3_read" {
  name        = "${var.environment}-ecs-task-s3-read"
  description = "Allow reading from the OBD-II logs S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
      }
    ]
  })
}

# Policy for ECS task to publish to AWS IoT Core
resource "aws_iam_policy" "ecs_task_iot_publish" {
  name        = "${var.environment}-ecs-task-iot-publish"
  description = "Allow publishing to AWS IoT Core MQTT topics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "iot:Publish",
          "iot:Connect"
        ]
        Resource = [
          # Allow connecting to IoT Core
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_account_id.current.id}:client/*",
          # Allow publishing to our specific topic (we can use a wildcard for the topic if needed)
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_account_id.current.id}:topic/${var.mqtt_topic}"
        ]
      }
    ]
  })
}

# Attach policies to the ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_s3_read" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_s3_read.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_iot_publish" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_iot_publish.arn
}

# IAM Role for IoT Core topic rule to publish to MSK (Kafka)
resource "aws_iam_role" "iot_topic_rule_msk" {
  name = "${var.environment}-iot-topic-rule-msk-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
      }
    ]
  })
}

# Policy for IoT Core to write to MSK (we'll use the MSK cluster ARN)
# Note: The actual permission for MSK is to allow the IoT Core role to send data to the cluster via the Kafka API.
# We'll use the managed policy for MSK? Actually, there isn't one. We'll allow the Kafka cluster resource.
# However, note: the IoT Core rule uses the Kafka action, which requires the cluster to be specified in the rule.
# We'll allow the role to perform kafka-cluster:Connect and kafka-cluster:WriteData on the MSK cluster resource.
resource "aws_iam_policy" "iot_topic_rule_msk" {
  name        = "${var.environment}-iot-topic-rule-msk-policy"
  description = "Allow IoT Core to write to MSK cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "kafka-cluster:Connect",
          "kafka-cluster:WriteData",
          "kafka-cluster:CreateTopic"
        ]
        Resource = "*" # We'll restrict to the MSK cluster ARN once we have it, but for now we use *
      }
    ]
  })
}

# Attach the policy to the IoT Core role
resource "aws_iam_role_policy_attachment" "iot_topic_rule_msk" {
  role       = aws_iam_role.iot_topic_rule_msk.name
  policy_arn = aws_iam_policy.iot_topic_rule_msk.arn
}

# Data sources for current region and account ID
data "aws_region" "current" {}
data "aws_account_id" "current" {}