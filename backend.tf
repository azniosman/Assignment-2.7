terraform {
  backend "s3" {
    bucket = "azni"
    key    = "dynamodb-table/terraform.tfstate"
    region = "us-east-1"
  }
}
