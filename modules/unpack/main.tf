locals {
  assets_dir = "${path.module}/.terraform/assets"
  src_dir = "${path.module}/src"
  build_dir = "${path.module}/.terraform/build"
}

resource "local_file" "name" {
  for_each = toset([local.assets_dir, local.build_dir])
  content = ""
  filename = "${each.key}/.noop"
  file_permission = "0644"
}

data "docker_registry_image" "this" {
  name = "golang:1.18-bullseye"
}

resource "docker_image" "this" {
  name = data.docker_registry_image.this.name
  pull_triggers = [
    data.docker_registry_image.this.sha256_digest
  ]
  keep_locally = true
}

# Generate the "unpack-environment" executable
resource "docker_container" "this" {
  depends_on = [
    local_file.name
  ]

  name = "conda-unpack"
  image = docker_image.this.image_id
  attach = true
  must_run = false
  logs = true

  command = [ "go", "build", "-o", "/output/bin/unpack-environment" ]

  working_dir = "/app"

  dynamic "upload" {
    for_each = fileset(local.src_dir, "**")
    content {
      file = "/app/${upload.value}"
      source = "${local.src_dir}/${upload.value}" 
      source_hash = filesha256("${local.src_dir}/${upload.value}")
    }
  }

  volumes {
    container_path = "/output"
    host_path = abspath(local.build_dir)
    read_only = false
  }
}

data "archive_file" "this" {
  depends_on = [
    docker_container.this,
  ]
  excludes = [
    ".noop"
  ]

  type        = "zip"
  source_dir  = local.build_dir
  output_path = "${local.assets_dir}/${docker_container.this.id}.zip"
}

resource "aws_lambda_layer_version" "this" {
  layer_name = "conda-unpack-environment"
  compatible_runtimes = [
    "provided.al2"
  ]
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
}
