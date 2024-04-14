terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }

    google = {
      source  = "hashicorp/google"
      version = "5.24.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      App = local.app
      Env = local.env
    }
  }
}

provider "google" {
  region = "asia-northeast1"

  default_labels = {
    app = local.app
    env = local.env
  }
}
