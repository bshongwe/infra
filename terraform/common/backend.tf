terraform {
  backend "s3" {
    bucket         = "platform-tf-state"
    key            = "${var.environment}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "platform-tf-locks"
    encrypt        = true
  }
}