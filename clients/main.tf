locals {
  edge_lan1_subnet = cidrsubnet("${var.cidr_block}", 8, 0)
  edge_wan1_subnet = cidrsubnet("${var.cidr_block}", 8, 1)
  edge_lan2_subnet = cidrsubnet("${var.cidr_block}", 8, 2)
  edge_start_ip    = 10
  windows_start_ip = 200
  first_az         = data.aws_availability_zones.available.names[0]
}

data "velocloud_profile" "aws_edge_profile" {
  name = var.edge_profile
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "velocloud" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["VeloCloud VCE 4.3.1*GA*"]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["801119661308"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "velocloud_edge" "virtual" {
  configurationid = data.velocloud_profile.aws_edge_profile.id
  modelnumber     = "virtual"
  name            = "${var.name_prefix}${local.first_az}"
  site {
    name         = "${var.name_prefix}${local.first_az}"
    contactname  = "VMware SASE Branch Lab"
    contactemail = "vmware_sase_branch_lab@velocloud.net"
  }
}

resource "aws_vpc" "net" {
  cidr_block = var.cidr_block

  tags = {
    Name = "${var.name_prefix}vpc"
  }
}

resource "aws_internet_gateway" "net" {
  vpc_id = aws_vpc.net.id

  tags = {
    Name = "${var.name_prefix}gateway"
  }
}

resource "aws_default_route_table" "net_default_rtb" {
  default_route_table_id = aws_vpc.net.default_route_table_id

  route {
    cidr_block = var.ipv4_default
    gateway_id = aws_internet_gateway.net.id
  }

  tags = {
    Name = "${var.name_prefix}default-rtb"
  }
}

resource "aws_subnet" "edge_lan1_subnet" {
  vpc_id            = aws_vpc.net.id
  cidr_block        = local.edge_lan1_subnet
  availability_zone = local.first_az

  tags = {
    Name = "${var.name_prefix}edge-lan1-subnet"
  }
}

resource "aws_subnet" "edge_wan1_subnet" {
  vpc_id            = aws_vpc.net.id
  cidr_block        = local.edge_wan1_subnet
  availability_zone = local.first_az

  tags = {
    Name = "${var.name_prefix}edge-wan1-subnet"
  }
}

resource "aws_subnet" "edge_lan2_subnet" {
  vpc_id            = aws_vpc.net.id
  cidr_block        = local.edge_lan2_subnet
  availability_zone = local.first_az

  tags = {
    Name = "${var.name_prefix}edge-lan2-subnet"
  }
}

resource "aws_default_network_acl" "net_default_acl" {
  default_network_acl_id = aws_vpc.net.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.ipv4_default
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.ipv4_default
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.name_prefix}network-acl"
  }
}

resource "aws_security_group" "client" {
  name        = "${var.name_prefix}client-sg"
  description = "restrict inbound access to client interface"
  vpc_id      = aws_vpc.net.id

  ingress {
    description = "restrict rdp in"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.ipv4_default]
  }

  egress {
    description = "allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.ipv4_default]
  }

  tags = {
    Name = "${var.name_prefix}client-sg"
  }
}

resource "aws_security_group" "edge_external" {
  name        = "${var.name_prefix}edge-external-sg"
  description = "allow access public edge access"
  vpc_id      = aws_vpc.net.id

  ingress {
    description = "allow all vcmp traffic in"
    from_port   = 2426
    to_port     = 2426
    protocol    = "17"
    cidr_blocks = [var.ipv4_default]
  }

  ingress {
    description = "restrict rdp in"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.ipv4_default]
  }

  egress {
    description = "allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.ipv4_default]
  }

  tags = {
    Name = "${var.name_prefix}edge-external-sg"
  }
}

resource "aws_security_group" "edge_internal" {
  name        = "${var.name_prefix}edge-internal-sg"
  description = "allow access private edge access"
  vpc_id      = aws_vpc.net.id

  ingress {
    description = "allow all internal traffic in"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.ipv4_default]
  }

  egress {
    description = "allow all internal traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.ipv4_default]
  }

  tags = {
    Name = "${var.name_prefix}edge-internal-sg"
  }
}

resource "aws_network_interface" "edge_wan1_eni" {
  subnet_id         = aws_subnet.edge_wan1_subnet.id
  security_groups   = ["${aws_security_group.edge_external.id}"]
  source_dest_check = false
  private_ips = [
    cidrhost("${local.edge_wan1_subnet}", local.edge_start_ip)
  ]
  depends_on = [
    aws_subnet.edge_wan1_subnet
  ]

  tags = {
    Name = "${var.name_prefix}edge-wan1-eni"
  }
}

resource "aws_network_interface" "edge_lan1_eni" {
  subnet_id         = aws_subnet.edge_lan1_subnet.id
  security_groups   = ["${aws_security_group.edge_internal.id}"]
  source_dest_check = false
  private_ips = [
    cidrhost("${local.edge_lan1_subnet}", local.edge_start_ip)
  ]
  depends_on = [
    aws_subnet.edge_lan1_subnet
  ]

  tags = {
    Name = "${var.name_prefix}edge-lan1-eni"
  }
}

resource "aws_network_interface" "edge_lan2_eni" {
  subnet_id         = aws_subnet.edge_lan2_subnet.id
  security_groups   = ["${aws_security_group.edge_internal.id}"]
  source_dest_check = false
  private_ips = [
    cidrhost("${local.edge_lan2_subnet}", local.edge_start_ip)
  ]
  depends_on = [
    aws_subnet.edge_lan2_subnet
  ]

  tags = {
    Name = "${var.name_prefix}edge-lan2-eni"
  }
}

resource "aws_network_interface" "windows_eni" {
  subnet_id         = aws_subnet.edge_lan1_subnet.id
  security_groups   = ["${aws_security_group.client.id}"]
  source_dest_check = false
  private_ips = [
    cidrhost("${local.edge_lan1_subnet}", local.windows_start_ip)
  ]
  depends_on = [
    aws_subnet.edge_lan1_subnet
  ]

  tags = {
    Name = "${var.name_prefix}windows-lan1-eni"
  }
}

resource "aws_eip" "edge_wan1_eip" {
  network_interface = aws_network_interface.edge_wan1_eni.id

  depends_on = [
    aws_network_interface.edge_wan1_eni,
    aws_instance.sdwan_edge
  ]

  tags = {
    Name = "${var.name_prefix}edge-wan1-eip"
  }
}

resource "aws_eip" "windows_eip" {
  network_interface = aws_network_interface.windows_eni.id

  depends_on = [
    aws_network_interface.windows_eni,
    aws_instance.windows
  ]

  tags = {
    Name = "${var.name_prefix}windows-eip"
  }
}

resource "aws_key_pair" "public_key" {
  key_name   = "${var.name_prefix}public-key"
  public_key = var.public_key

  tags = {
    Name = "${var.name_prefix}public-key"
  }
}

resource "aws_instance" "windows" {
  ami           = data.aws_ami.windows.id
  instance_type = var.ec2_server_type
  key_name      = aws_key_pair.public_key.key_name

  network_interface {
    network_interface_id = aws_network_interface.windows_eni.id
    device_index         = 0
  }

  user_data = templatefile("${path.module}/templates/windows_bootstrap.tftpl", {
    cert_file = "${file("${path.module}/vmware_sase_root.cer")}"
  })

  tags = {
    Name = "${var.name_prefix}windows-test"
  }
}

resource "aws_instance" "sdwan_edge" {
  ami           = data.aws_ami.velocloud.id
  instance_type = var.ec2_edge_type
  depends_on = [
    velocloud_edge.virtual,
    aws_internet_gateway.net
  ]

  network_interface {
    network_interface_id = aws_network_interface.edge_lan2_eni.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.edge_lan1_eni.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.edge_wan1_eni.id
    device_index         = 2
  }

  user_data = base64encode(templatefile("${path.module}/templates/vce_userdata.yaml", {
    activation_code = "${velocloud_edge.virtual.activationkey}"
    vco_url         = "${var.vco_url}"
  }))

  tags = {
    Name = "${var.name_prefix}edge"
  }
}
