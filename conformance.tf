
resource "aws_lambda_permission" "allow_encryption_config" {
  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.encryption_config_lambda.function_name
  principal     = "config.amazonaws.com"
}

resource "aws_config_conformance_pack" "s3_conformance_pack" {
  name = "s3-conformance-pack"

  template_body = yamlencode({
    Resources = {
      S3EncryptionRule = {
        Type = "AWS::Config::ConfigRule"
        Properties = {
          ConfigRuleName = "S3EncryptionRule"
          scope = {
            ComplianceResourceTypes = ["AWS::S3::Bucket"]
          }
          Source = {
            Owner            = "CUSTOM_LAMBDA"
            SourceIdentifier = aws_lambda_function.encryption_config_lambda.arn
            SourceDetails = [
              {
                EventSource = "aws.config"
                MessageType = "ConfigurationItemChangeNotification"
              }
            ]
          }
        }
      }
    }
  })

  depends_on = [
    aws_lambda_permission.allow_encryption_config
  ]
}