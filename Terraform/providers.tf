terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

terraform {
    backend "s3" {
        bucket = "saketh-movielens-data-ingestion-code"
       # dynamodb_table = "terraform-state-lock-db"
        key = "secure-tf/terrafrom_state/tf_state.json"
        region = "us-east-2"
    }
}