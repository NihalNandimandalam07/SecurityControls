resource "aws_config_config_rule" "s3_public_rule" {
  name = "s3-public-data-classification-detection"

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.config_lambda.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  depends_on = [
    aws_lambda_permission.allow_config
  ]
}
