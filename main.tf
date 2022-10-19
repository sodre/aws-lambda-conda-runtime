
resource "aws_s3_bucket" "assets" {
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

module "unpack" {
  source = "./modules/unpack"
}

module "micromamba" {
  source = "./modules/micromamba"
}

module "conda" {
  source = "./modules/conda"
  environment = "${path.module}/environment.yml"

  asset_bucket = aws_s3_bucket.assets
}

data "archive_file" "this" {
  type             = "zip"
  output_path      = "${path.module}/.terraform/assets/handler.zip"
  output_file_mode = "0666"

  source {
    content = file("${path.module}/bootstrap")
    filename = "bootstrap"
  }
  source {
    content = file("${path.module}/environment.yml")
    filename = "environment.yml"
  }
  source {
    content = file("${path.module}/handler.py")
    filename = "handler.py"
  }
}

data aws_iam_policy "this" {
    for_each = toset([
      "AWSLambdaBasicExecutionRole",
      "AmazonS3ReadOnlyAccess",
    ])
    name = each.key
}

data aws_iam_policy_document "this" {
    statement {
      actions = ["sts:AssumeRole"]
      principals {
        type = "Service"
        identifiers = ["lambda.amazonaws.com"]
      }
      effect = "Allow"
    }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/hello-world"
  retention_in_days = 14
}

resource "aws_iam_role" "this" {
  name = "hello-world-AWSLambdaBasicExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.this.json
    managed_policy_arns =  [
      for policy in data.aws_iam_policy.this: policy.arn
    ]
  depends_on = [
    aws_cloudwatch_log_group.this
  ]
}

resource "aws_lambda_function" "this" {
  function_name = "hello-world"

  runtime       = "provided.al2"

  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  handler       = "handler.handler"

  role = aws_iam_role.this.arn

  // speeds up the cold-start to ~30sec
  memory_size = 2048
  timeout = 300

  layers = [
    module.micromamba.lambda_layer.arn,
    module.unpack.lambda_layer.arn,
  ]

  environment {
    variables = {
      CONDA_LAMBDA_URI = module.conda.s3_object_uri
    }
  }
}

data "aws_lambda_invocation" "this" {
  function_name = aws_lambda_function.this.function_name
  input = jsonencode({
    result = "It is working!"
  })
}
