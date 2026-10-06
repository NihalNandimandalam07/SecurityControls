# For second detection rule to see if encrytion is enabled (AWS-KMS)

resource "aws_iam_role" "encryption_lambda_role" {
  name = "lambda-encryptionrole-detection"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "encryption_lambda_role_policy_attachment" {
  role       = aws_iam_role.encryption_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role_policy" "encryption_lambda_role_policy" {
  name = "lambda-role-policy-detection"
  role = aws_iam_role.encryption_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadS3Bucket"
        Effect = "Allow"
        Action = [
          "s3:GetEncryptionConfiguration"
        ]
        Resource = "*"
      },
      {
        Sid    = "ReportToConfig"
        Effect = "Allow"
        Action = [
          "config:PutEvaluations"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "encryption_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/encryption_lambda_function.py"
  output_path = "${path.module}/encryption_lambda_function.zip"
}

resource "aws_lambda_function" "encryption_config_lambda" {
  function_name = "config-lambda-encryption_detection"
  role          = aws_iam_role.encryption_lambda_role.arn
  handler       = "encryption_lambda_function.lambda_handler" #change
  runtime       = "python3.13"
  filename      = data.archive_file.encryption_lambda_zip.output_path

  source_code_hash = data.archive_file.encryption_lambda_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy_attachment.encryption_lambda_role_policy_attachment,
    aws_iam_role_policy.encryption_lambda_role_policy
  ]
}



resource "aws_lambda_permission" "allow_encryption_config" {
  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.encryption_config_lambda.function_name
  principal     = "config.amazonaws.com"
}



