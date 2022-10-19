locals {
  assets_dir = "${path.module}/.terraform/assets"
}

resource "local_file" "name" {
  for_each = toset([local.assets_dir])
  content = ""
  filename = "${each.key}/.noop"
  file_permission = "0644"
}

# This builds the "layer-building" image
resource "docker_image" "this" {
  name = "conda-pack"
  triggers = {
    dockerfile  = filesha256("${path.module}/Dockerfile"),
    build-layer = filesha256("${path.module}/build-layer"),
  }
  build {
    path = abspath(path.module)
  }
}

# This generates the layer.zip file into the current directory
resource "docker_container" "this" {
  name     = "layer"
  image    = docker_image.this.image_id
  attach   = true
  must_run = false
  logs     = true
  upload {
    file   = "/tmp/environment.yml"
    source = var.environment
    source_hash = filesha256(var.environment)
  }
  volumes {
    container_path = "/output"
    host_path      = abspath(local.assets_dir)
    read_only      = false
  }
}

resource "aws_s3_object" "this" {
  bucket = var.asset_bucket.id
  key = "layer.tar.bz2"
  source = "${local.assets_dir}/layer.tar.bz2"
  source_hash = docker_container.this.id
}
