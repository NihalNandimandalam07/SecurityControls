
resource "aws_ssm_document" "s3_public_remediation"{
    name          = "s3-public-remediation-${random_id.suffix.hex}"
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
        mainSteps     = [
        {
            action      = "aaws:invokeLambdaFunction"
            name        = "enableVersioning"
            inputs      = {
                FunctionName = aws_lambda_function.reactive_lambda.arn
                Payload      = jsonencode({
                    bucketName = "{{ bucketName }}"
                })
            }
        }
        ]
    })
}


resource "aws_iam_role" "remediation_role" {
  name = "config-role-remediation-${random_id.suffix.hex}"

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
  name = "config-role-policy-remediation-${random_id.suffix.hex}"
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
        Resource = "aws_lambda_function.reactive_lambda.arn"
      }
    ]
  })
}

data "aws_config_config_rule" "s3_public_rule" {
  name = s3-public-data-classification-detection
}

resource "aws_config_remediation_configuration" "s3_public_remediation" {
  config_rule_name = data.aws_config_config_rule.s3_public_rule.name
  target_id        = aws_ssm_document.s3_public_remediation.name
  target_type      = "SSM_DOCUMENT"
  automatic        = true

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.remediation_role.arn
  }

  parameter {
    name         = "bucketName"
    resource_value ={
      source = "RESOURCE_ID"
    }
  }

  depends_on = [
    aws_iam_role_policy.remediation_role_policy,
    aws_ssm_document.s3_public_remediation
  ]
}