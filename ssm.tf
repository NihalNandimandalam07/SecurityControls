#for the first detection rule
resource "aws_ssm_document" "s3_public_remediation" {
  name          = "s3-public-remediation"
  document_type = "Automation"

  content = jsonencode({
    schemaVersion = "0.3"
    assumeRole    = "{{ AutomationAssumeRole }}"

    parameters = {
      AutomationAssumeRole = {
        type = "String"
      }
      bucketName = {
        type = "String"
      }
    }
    mainSteps = [
      {
        action = "aws:invokeLambdaFunction"
        name   = "enableVersioning"
        inputs = {
          FunctionName = aws_lambda_function.reactive_lambda.arn
          Payload = jsonencode({
            bucketName = "{{ bucketName }}"
          })
        }
      }
    ]
  })
}

#ssm document for the conformance pack
resource "aws_ssm_document" "s3_conformance_remediation" {
  name          = "s3-conformance-remediation"
  document_type = "Automation"

  content = jsonencode({
    schemaVersion = "0.3"
    assumeRole    = "{{ AutomationAssumeRole }}"

    parameters = {
      AutomationAssumeRole = {
        type = "String"
      }
      bucketName = {
        type = "String"
      }
    }
    mainSteps = [
      {
        action = "aws:executeAwsApi"
        name   = "enableVersioning"
        inputs = {
          Service = "S3"
          Api     = "PutBucketVersioning"
          Bucket  = "{{ bucketName }}"
          VersioningConfiguration = {
            Status = "Enabled"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role" "remediation_role" {
  name = "config-role-remediation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "remediation_role_policy" {
  name = "config-role-policy-remediation"
  role = aws_iam_role.remediation_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadS3Bucket"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.reactive_lambda.arn
      }
    ]
  })
}


resource "aws_config_remediation_configuration" "s3_public_remediation" {
  config_rule_name = aws_config_config_rule.s3_versioning_rule.name
  target_id        = aws_ssm_document.s3_public_remediation.name
  target_type      = "SSM_DOCUMENT"
  automatic        = true

  maximum_automatic_attempts = 3
  retry_attempt_seconds      = 60

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.remediation_role.arn
  }

  parameter {
    name           = "bucketName"
    resource_value = "RESOURCE_ID"
  }

  depends_on = [
    aws_config_config_rule.s3_versioning_rule,
    aws_iam_role_policy.remediation_role_policy,
    aws_ssm_document.s3_public_remediation
  ]
}

