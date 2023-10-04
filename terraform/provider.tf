terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket         = "checkpoint-iac-3"
    key            = "terraform.tfstate"
    dynamodb_table = "checkpoint-iac-3"
    region         = "us-east-1"
  }
}
