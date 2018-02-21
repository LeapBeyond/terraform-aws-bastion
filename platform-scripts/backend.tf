terraform {
  backend "s3" {
    region         = "eu-west-2"
    profile        = "adm_rhook_cli"
    dynamodb_table = "terraform-bastion-test-state-lock"
    bucket         = "terraform-bastion-test-state20180221075441498700000001"
    key            = "terraform-aws-bastion/platform-scripts"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-west-2:889199313043:key/a66b5d53-6bf0-46dc-9686-03043e1fd7df"
  }
}
