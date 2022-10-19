output "s3_object" {
    description = "The conda environment layer"
    value = aws_s3_object.this
}

output "s3_object_uri" {
    description = "The S3 URI of the layer"
    value = "s3://${aws_s3_object.this.bucket}/${aws_s3_object.this.key}?VersionId=${aws_s3_object.this.version_id}"
}