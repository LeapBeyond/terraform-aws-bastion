output "project_tags" {
  value = "${var.tags}"
}

output "bucket_arn" {
  value = "${aws_s3_bucket.terraform-state-storage-s3.arn}"
}

output "table_name" {
  value = "${aws_dynamodb_table.dynamodb-terraform-state-lock.i}"
}

output "table_arn" {
  value = "${aws_dynamodb_table.dynamodb-terraform-state-lock.arn}"
}
