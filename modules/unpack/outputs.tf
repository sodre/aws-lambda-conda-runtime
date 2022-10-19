output "lambda_layer" {
    description = "The S3 download bootstrap layer"
    value = docker_container.this.exit_code == 0 ? aws_lambda_layer_version.this : null
}