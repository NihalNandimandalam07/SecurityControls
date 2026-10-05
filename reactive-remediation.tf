#remediation for the first detection rule
resource "aws_iam_role" "reactive_lambda_role" {
  name = "config-role-reactive"

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

resource "aws_iam_role_policy_attachment" "reactive_lambda_role_policy_attachment" {
  role       = aws_iam_role.reactive_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "reactive_lambda_role_policy" {
  name = "config-role-policy-reactive"
  role = aws_iam_role.reactive_lambda_role.id

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
        Sid    = "EnableBucketVersioning"
        Effect = "Allow"
        Action = [
          "s3:PutBucketVersioning"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "reactive_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/reactive_lambda.py"
  output_path = "${path.module}/reactive_lambda.zip"
}

resource "aws_lambda_function" "reactive_lambda" {
  function_name = "config-lambda-reactive"
  role          = aws_iam_role.reactive_lambda_role.arn
  handler       = "reactive_lambda.lambda_handler"
  runtime       = "python3.13"
  filename      = data.archive_file.reactive_lambda_zip.output_path

  source_code_hash = data.archive_file.reactive_lambda_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy_attachment.reactive_lambda_role_policy_attachment,
    aws_iam_role_policy.reactive_lambda_role_policy
  ]
}

#########################
#remediaton for the second detection rule

resource "aws_iam_role" "reactive_encryption_lambda_role" {
  name = "config-role-encryption-reactive"

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

resource "aws_iam_role_policy_attachment" "reactive_lambda_role_encrytion_policy_attachment" {
  role       = aws_iam_role.reactive_encryption_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "reactive_encryption_lambda_role_policy" {
  name = "config-role-policy-encryption-reactive"
  role = aws_iam_role.reactive_encryption_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadS3Bucket"
        Effect = "Allow"
        Action = [
          "s3:GetEnncryptionConfiguration"
        ]
        Resource = "*"
      },
      {
        Sid    = "EnableBucketVersioning"
        Effect = "Allow"
        Action = [
          "s3:PutEnncryptionConfiguration"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "reactive_encryption_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/reactive_encryption_lambda.py"
  output_path = "${path.module}/reactive_encryption_lambda.zip"
}

resource "aws_lambda_function" "reactive_encryption_lambda" {
  function_name = "config-lambda-encryption_reactive"
  role          = aws_iam_role.reactive_encryption_lambda_role.arn
  handler       = "reactive_encryption_lambda.lambda_handler"
  runtime       = "python3.13"
  filename      = data.archive_file.reactive_encryption_lambda_zip.output_path

  source_code_hash = data.archive_file.reactive_encryption_lambda_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy_attachment.reactive_lambda_role_encrytion_policy_attachment,
    aws_iam_role_policy.reactive_encryption_lambda_role_policy
  ]
}