output "config_rule_name" {
  value = aws_config_config_rule.s3_public_rule.name
}

output "lambda_function_name" {
  value = aws_lambda_function.config_lambda.function_name
}