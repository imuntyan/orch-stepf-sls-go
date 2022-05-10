provider "aws" {
  region = "us-east-1"
  profile = "dev"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


