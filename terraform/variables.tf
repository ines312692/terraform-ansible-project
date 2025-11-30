variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (Ubuntu 22.04)"
  type        = string
  default     = "ami-0c7217cdde317cfec"
}

variable "vocareum_key_name" {
  description = "Name of the existing Vocareum key pair"
  type        = string
  default     = "vockey"
}