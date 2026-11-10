variable "aws_region" {
  description = "AWS region for the ScreenHive assessment environment."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project identifier used for resource names."
  type        = string
  default     = "screenhive"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance size. Review current pricing before applying."
  type        = string
  default     = "t3.small"
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the deployment role."
  type        = string
  default     = "Ritacloud23/ScreenHive-DevOps"
}
