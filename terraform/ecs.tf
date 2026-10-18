# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  tags = {
    Name        = "${var.environment}-ecs-cluster"
    Environment = var.environment
  }
}

# ECS Task Definition for the OBD-II Replay Engine (Fargate)
resource "aws_ecs_task_definition" "replay_engine" {
  family                   = "${var.environment}-obd-ii-replay-engine"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # Default CPU, can be adjusted
  memory                   = "512"  # Default memory, can be adjusted

  # IAM roles
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "obd-ii-replay-engine"
      image     = "${aws_ecr_repository.replay_engine.repository_url}:latest"  # We'll use latest for simplicity; in production, use a specific tag
      portMappings = [
        {
          containerPort = 8080  # Assuming the app listens on 8080 for health checks, etc. (adjust as needed)
          protocol      = "tcp"
        }
      ]
      essential = true
      environment = [
        {
          name  = "S3_BUCKET"
          value = aws_s3_bucket.logs.bucket
        },
        {
          name  = "MQTT_TOPIC"
          value = var.mqtt_topic
        },
        # Add other environment variables as needed (e.g., AWS IoT endpoint, etc.)
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.environment}-obd-ii-replay-engine"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.environment}-obd-ii-replay-engine-taskdef"
    Environment = var.environment
  }
}

# CloudWatch Logs Group for the task definition
resource "aws_cloudwatch_log_group" "ecs_replay_engine" {
  name              = "/ecs/${var.environment}-obd-ii-replay-engine"
  retention_in_days = 30

  tags = {
    Name        = "${var.environment}-ecs-replay-engine-logs"
    Environment = var.environment
  }
}

# ECS Service to run the task definition
resource "aws_ecs_service" "replay_engine" {
  name            = "${var.environment}-obd-ii-replay-engine-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.replay_engine.arn
  launch_type     = "FARGATE"
  desired_count   = 0
  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false  # Since we are in private subnets and have NAT gateway for outbound
  }

  # Optional: load balancer if needed (not specified, so we skip)
  # health_check_grace_period_seconds = 30

  tags = {
    Name        = "${var.environment}-obd-ii-replay-engine-service"
    Environment = var.environment
  }
}

# Output the cluster name and service name
output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.replay_engine.name
}