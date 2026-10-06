
# For first detection rule to see if versioning is enabled
resource "aws_iam_role" "versioning_lambda_role" {
  name = "lambda-versioningrole-detection"

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

resource "aws_iam_role_policy_attachment" "versioning_lambda_role_policy_attachment" {
  role       = aws_iam_role.versioning_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role_policy" "versioning_lambda_role_policy" {
  name = "lambda-role-policy-versioning-detection"
  role = aws_iam_role.versioning_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadS3Bucket"
        Effect = "Allow"
        Action = [
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning"
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

data "archive_file" "versioning_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/versioning_lambda_function.py"
  output_path = "${path.module}/versioning_lambda_function.zip"
}

resource "aws_lambda_function" "config_versioning_lambda" {
  function_name = "config-lambda-detection"
  role          = aws_iam_role.versioning_lambda_role.arn
  handler       = "versioning_lambda_function.lambda_handler"
  runtime       = "python3.13"
  filename      = data.archive_file.versioning_lambda_zip.output_path

  source_code_hash = data.archive_file.versioning_lambda_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy_attachment.versioning_lambda_role_policy_attachment,
    aws_iam_role_policy.versioning_lambda_role_policy
  ]
}


resource "aws_lambda_permission" "allow_versioning_config" {
  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.config_versioning_lambda.function_name
  principal     = "config.amazonaws.com"
}




