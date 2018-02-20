terraform {
  backend "s3" {
    region         = "eu-west-2"
    profile        = "adm_rhook_cli"
    dynamodb_table = "terraform-bastion-test-state-lock"
    bucket         = "terraform-bastion-test-state20180220185439484200000001"
    key            = "terraform-aws-bastion/platform-scripts"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-west-2:889199313043:key/89897298-24e2-4fcc-8ffa-c38f25b7685e"
  }
}
