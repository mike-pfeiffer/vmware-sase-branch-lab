provider "aws" {
  region     = "us-west-1"
  alias      = "us-west-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  default_tags {
    tags = var.required_tags
  }
}

provider "velocloud" {
  alias                 = "sdwan"
  vco                   = var.vco_address
  username              = var.vco_username
  password              = var.vco_password
  skip_ssl_verification = true
}

terraform {
  required_providers {
    velocloud = {
      source = "adeleporte/velocloud"
    }
  }
}
