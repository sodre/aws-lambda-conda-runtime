locals {
  assets_dir = "${path.module}/.terraform/assets"
  build_dir = "${path.module}/.terraform/build"
  bin_dir = "${local.build_dir}/bin"
}

resource "local_file" "name" {
  for_each = toset([local.assets_dir, local.build_dir, local.bin_dir])
  content = ""
  filename = "${each.key}/.noop"
  file_permission = "0644"
}

data "docker_registry_image" "this" {
  name = "mambaorg/micromamba:0.27.0"
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

  name = "micromamba"
  image = docker_image.this.image_id
  attach = true
  must_run = false
  logs = true

  command = [ "cp", "/bin/micromamba", "/output" ]

  working_dir = "/app"

  volumes {
    container_path = "/output"
    host_path = abspath(local.bin_dir)
    read_only = false
  }
}

data "archive_file" "this" {
  depends_on = [
    docker_container.this,
  ]
  excludes = [
    ".noop",
    "bin/.noop"
  ]

  type        = "zip"
  source_dir  = local.build_dir
  output_path = "${local.assets_dir}/${docker_container.this.id}.zip"
}

resource "aws_lambda_layer_version" "this" {
  layer_name = "micromamba"
  compatible_runtimes = [
    "provided.al2"
  ]
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
}
