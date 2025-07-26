terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  
  backend "s3" {
    bucket = "databucketfortfs3"
    key = "demo/terrafrom.tf.state"
    region = "ap-south-1"
    dynamodb_table = "terraform_state"
    encrypt = true
    
  }
}

# Configure the AWS Provider
provider "aws" {
  alias = "east"
  region = "us-east-1"
}

provider "aws" {
  alias = "south"
  region = "us-south-1"
}