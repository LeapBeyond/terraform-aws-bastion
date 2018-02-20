variable "tags" {
  default = {
    "owner"   = "rahook"
    "project" = "bastion-test"
    "client"  = "Internal"
  }
}

variable "bucket_prefix" {
  default = "terraform-bastion-test-state"
}

variable "lock_table_name" {
  default = "terraform-bastion-test-state-lock"
}

/* variables to inject via terraform.tfvars */
variable "aws_region" {}

variable "aws_account_id" {}
variable "aws_profile" {}
