variable "s3_bucket_name" {
  default = "tf-remote-state-bucket-demo-aws-modules-jesus"
}

variable "dynamodb_table_name" {
  default = "terraform-state-lock-dynamo-modules-jesus"
}
