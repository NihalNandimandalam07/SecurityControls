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
  config_rule_name = var.detective_config_config_rule_1
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
    aws_iam_role_policy.remediation_role_policy,
    aws_ssm_document.s3_public_remediation
  ]
}



################
#for the second detection rule
resource "aws_ssm_document" "s3_encryption_remediation" {
  name          = "s3-encryption-remediation"
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
        name   = "enableEncryption"
        inputs = {
          FunctionName = aws_lambda_function.reactive_encryption_lambda.arn
          Payload = jsonencode({
            bucketName = "{{ bucketName }}"
          })
        }
      }
    ]
  })
}


resource "aws_iam_role" "remediation_encryption_role" {
  name = "config-encryption-remediation"

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

resource "aws_iam_role_policy" "remediation_encryption_role_policy" {
  name = "config-role-policy-encryption-remediation"
  role = aws_iam_role.remediation_encryption_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadS3Bucket"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.reactive_encryption_lambda.arn
      }
    ]
  })
}

resource "aws_config_remediation_configuration" "s3_encryption_remediation" {
  config_rule_name = var.detective_config_config_rule_2
  target_id        = aws_ssm_document.s3_encryption_remediation.name
  target_type      = "SSM_DOCUMENT"
  automatic        = true

  maximum_automatic_attempts = 3
  retry_attempt_seconds      = 60

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.remediation_encryption_role.arn
  }

  parameter {
    name           = "bucketName"
    resource_value = "RESOURCE_ID"
  }

  depends_on = [
    aws_iam_role_policy.remediation_encryption_role_policy,
    aws_ssm_document.s3_encryption_remediation
  ]
}