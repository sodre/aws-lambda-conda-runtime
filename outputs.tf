output "result" {
  value = jsondecode(data.aws_lambda_invocation.this.result)
}