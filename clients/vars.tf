variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "vco_url" {
  type        = string
  description = "URL of the VCO to activate against - do NOT include https://"
}

variable "edge_profile" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "ipv4_default" {
  type    = string
  default = "0.0.0.0/0"
}

variable "ec2_server_type" {
  type    = string
  default = "t3.medium"
}

variable "ec2_edge_type" {
  type    = string
  default = "c4.large"
}

variable "public_key" {
  type = string
}

variable "name_prefix" {
  type    = string
  default = "sase-branch-lab-"
}