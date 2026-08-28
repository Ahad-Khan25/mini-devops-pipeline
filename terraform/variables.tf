variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"  # free-tier eligible
}

variable "project_name" {
  description = "Name prefix for tagging resources"
  type        = string
  default     = "mini-devops-pipeline"
}
