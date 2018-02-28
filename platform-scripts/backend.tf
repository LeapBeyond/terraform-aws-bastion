terraform {
  backend "s3" {
    region         = "eu-west-2"
    profile        = "adm_rhook_cli"
    dynamodb_table = "terraform-bastion-test-state-lock"
    bucket         = "terraform-bastion-test-state20180227145243778500000001"
    key            = "terraform-aws-bastion/platform-scripts"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-west-2:889199313043:key/77bb013b-5a76-4676-897e-d2408832f969"
  }
}
