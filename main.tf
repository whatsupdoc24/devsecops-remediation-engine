terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket       = "kyle-boobie-24"
    key          = "production/compliance-engine.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
