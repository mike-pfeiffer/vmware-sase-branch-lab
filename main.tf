resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "vmware-sase-branch-lab.pem"
  file_permission = "0600"
}

module "aws-us-west-1" {
  source = "./clients"

  providers = {
    aws       = aws.us-west-1
    velocloud = velocloud.sdwan
  }
  
  public_key = tls_private_key.keypair.public_key_openssh
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  vco_url        = var.vco_url
  edge_profile   = var.edge_profile
  cidr_block     = "10.64.0.0/16"
}