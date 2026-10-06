variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-2"
}

variable "detective_config_config_rule_1" {
  type    = string
  default = "s3-versioning-detection"
}
