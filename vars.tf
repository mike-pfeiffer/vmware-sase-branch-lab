variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "vco_address" {
  type = string
}

variable "vco_url" {
  type = string
}

variable "vco_username" {
  type = string
}

variable "vco_password" {
  type = string
}

variable "edge_profile" {
  type = string
}

variable "required_tags" {
  type = map(any)
  default = {
    Environment = "vmware-sase-branch-lab"
  }
}