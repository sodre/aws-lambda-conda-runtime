output "lambda_layer" {
    description = "The S3 download bootstrap layer"
    value = aws_lambda_layer_version.this
}