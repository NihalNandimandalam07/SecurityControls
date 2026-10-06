resource "aws_config_conformance_pack" "s3_conformance_pack" {
  name = "s3-conformance-pack"

  template_body = yamlencode({
    Resources = {
      S3VersioningRule = {
        Type = "AWS::Config::ConfigRule"
        Properties = {
          ConfigRuleName = "S3VersioningRule"
          scope = {
            ComplianceResourceTypes = ["AWS::S3::Bucket"]
          }
          Source = {
            Owner            = "CUSTOM_LAMBDA"
            SourceIdentifier = aws_lambda_function.config_versioning_lambda.arn
            SourceDetails = [
              {
                EventSource = "aws.config"
                MessageType = "ConfigurationItemChangeNotification"
              }
            ]
          }
        }
      }
      S3VersioningRemediation = {
        Type = "AWS::Config::RemediationConfiguration"
        Properties = {
          ConfigRuleName = "S3VersioningRule"
          TargetType     = "SSM_DOCUMENT"
          TargetId       = aws_ssm_document.s3_conformance_remediation.name
          Automatic      = true

          MaximumAutomaticAttempts = 5
          RetryAttemptSeconds      = 60

          Parameters = {
            AutomationAssumeRole = {
              StaticValue = {
                Values = [aws_iam_role.remediation_role.arn]
              }
            }
            bucketName = {
              ResourceValue = {
                Value = "RESOURCE_ID"
              }
            }
          }
        }
    } }
  })


  depends_on = [
    aws_lambda_permission.allow_versioning_config,
    aws_ssm_document.s3_conformance_remediation,
    aws_iam_role_policy.remediation_role_policy
  ]
}
