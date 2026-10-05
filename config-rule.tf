/*

#config rule for first detection
resource "aws_config_config_rule" "s3_versioning_rule" {
  name = "s3-versioning-detection"

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.config_versioning_lambda.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  depends_on = [
    aws_lambda_permission.allow_versioning_config
  ]
}
#############################
#config rule for second detection
resource "aws_config_config_rule" "s3_encryption_rule" {
  name = "s3-encryption-detection"

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.encryption_config_lambda.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  depends_on = [
    aws_lambda_permission.allow_encryption_config
  ]
}

*/