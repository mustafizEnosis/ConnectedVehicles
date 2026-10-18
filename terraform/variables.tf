variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "obd-ii-replay-cluster"
}

variable "desired_count" {
  description = "Desired count of tasks in the ECS service (for the replay engine)"
  type        = number
  default     = 1
}

variable "mqtt_topic" {
  description = "MQTT topic for OBD-II telemetry"
  type        = string
  default     = "obdii/telemetry"
}

variable "msk_broker_type" {
  description = "MSK broker instance type"
  type        = string
  default     = "kafka.t3.small"
}

variable "msk_number_of_broker_nodes" {
  description = "Number of MSK broker nodes"
  type        = number
  default     = 2
}

variable "mq_broker_instance_type" {
  description = "Amazon MQ broker instance type"
  type        = string
  default     = "mq.t3.micro"
}

variable "mq_broker_engine_type" {
  description = "Amazon MQ broker engine type"
  type        = string
  default     = "RABBITMQ"
}

variable "mq_broker_engine_version" {
  description = "Amazon MQ broker engine version"
  type        = string
  default     = "5.15.0"
}

variable "mq_broker_username" {
  description = "Amazon MQ broker username"
  type        = string
  default     = "admin"
}

variable "mq_broker_password" {
  description = "Amazon MQ broker password (sensitive)"
  type        = string
  sensitive   = true
}

variable "logs_bucket_name" {
  description = "Name of the S3 bucket for storing driving logs. If empty, a unique name will be generated."
  type        = string
  default     = ""
}