provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

# --------------------------------------------------------------------------------------------------------------
# define the protected VPC
# --------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "protected_vpc" {
  cidr_block           = "${var.protected_vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name    = "protected"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# seal off the default security group
resource "aws_default_security_group" "protected_default" {
  vpc_id = "${aws_vpc.protected_vpc.id}"

  tags {
    Name    = "protected-default"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_internet_gateway" "protected_gateway" {
  vpc_id = "${aws_vpc.protected_vpc.id}"

  tags {
    Name    = "protected-gateway"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# --------------------------------------------------------------------------------------------------------------
# define the bastion VPC
# --------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "bastion_vpc" {
  cidr_block           = "${var.bastion_vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name    = "bastion"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# seal off the default security group
resource "aws_default_security_group" "bastion_default" {
  vpc_id = "${aws_vpc.bastion_vpc.id}"

  tags {
    Name    = "bastion-default"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_internet_gateway" "bastion_gateway" {
  vpc_id = "${aws_vpc.bastion_vpc.id}"

  tags {
    Name    = "bastion-gateway"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# --------------------------------------------------------------------------------------------------------------
# setup peering
# --------------------------------------------------------------------------------------------------------------
resource "aws_vpc_peering_connection" "bastion_to_protected" {
  vpc_id      = "${aws_vpc.bastion_vpc.id}"
  peer_vpc_id = "${aws_vpc.protected_vpc.id}"
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags {
    Name    = "bastion_to_protected"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# --------------------------------------------------------------------------------------------------------------
# define the  subnets
# --------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "protected" {
  vpc_id                  = "${aws_vpc.protected_vpc.id}"
  cidr_block              = "${var.protected_subnet_cidr}"
  map_public_ip_on_launch = false

  tags {
    Name    = "protected"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_subnet" "protected_nat" {
  vpc_id                  = "${aws_vpc.protected_vpc.id}"
  cidr_block              = "${var.protected_nat_cidr}"
  map_public_ip_on_launch = true

  tags {
    Name    = "protected-nat"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_subnet" "bastion" {
  vpc_id                  = "${aws_vpc.bastion_vpc.id}"
  cidr_block              = "${var.bastion_subnet_cidr}"
  map_public_ip_on_launch = true

  tags {
    Name    = "bastion"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# --------------------------------------------------------------------------------------------------------------
# define the nat gateway in the protected nat subnet
# --------------------------------------------------------------------------------------------------------------
resource "aws_eip" "nat" {
  vpc                       = true
  associate_with_private_ip = "${var.eip_nat_ip}"

  tags {
    Name    = "nat-eip"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.protected_nat.id}"

  tags {
    Name    = "nat-gateway"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

# --------------------------------------------------------------------------------------------------------------
# define routing tables for the subnets
# --------------------------------------------------------------------------------------------------------------
resource "aws_route_table" "bastion" {
  vpc_id = "${aws_vpc.bastion_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.bastion_gateway.id}"
  }

  tags {
    Name    = "bastion-rt"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_route_table_association" "bastion" {
  subnet_id      = "${aws_subnet.bastion.id}"
  route_table_id = "${aws_route_table.bastion.id}"
}

resource "aws_route_table" "protected" {
  vpc_id = "${aws_vpc.protected_vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.gw.id}"
  }

  tags {
    Name    = "protected-rt"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_route_table_association" "protected" {
  subnet_id      = "${aws_subnet.protected.id}"
  route_table_id = "${aws_route_table.protected.id}"
}

resource "aws_route_table" "protected_nat" {
  vpc_id = "${aws_vpc.protected_vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_internet_gateway.protected_gateway.id}"
  }

  tags {
    Name    = "protected-nat-rt"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }
}

resource "aws_route_table_association" "protected_nat" {
  subnet_id      = "${aws_subnet.protected_nat.id}"
  route_table_id = "${aws_route_table.protected_nat.id}"
}

resource "aws_route" "protected_to_bastion" {
  route_table_id            = "${aws_route_table.protected.id}"
  destination_cidr_block    = "${var.bastion_vpc_cidr}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.bastion_to_protected.id}"
}

resource "aws_route" "bastion_to_protected" {
  route_table_id            = "${aws_route_table.bastion.id}"
  destination_cidr_block    = "${var.protected_vpc_cidr}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.bastion_to_protected.id}"
}

# --------------------------------------------------------------------------------------------------------------
# security groups
# --------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "bastion_ssh_access" {
  name        = "bastion-ssh"
  description = "allows ssh access to the bastion host"
  vpc_id      = "${aws_vpc.bastion_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_inbound}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "protected_ssh_access" {
  name        = "protected-ssh"
  description = "allows ssh access to protected host from bastion subnet"
  vpc_id      = "${aws_vpc.protected_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_subnet_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------------------------------------------------------------------------------------------------
# EC2 instances
# --------------------------------------------------------------------------------------------------------------
data "aws_ami" "target_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = "${data.aws_ami.target_ami.id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.bastion_key}"
  subnet_id              = "${aws_subnet.bastion.id}"
  vpc_security_group_ids = ["${aws_security_group.bastion_ssh_access.id}"]

  root_block_device = {
    volume_type = "gp2"
    volume_size = "${var.root_vol_size}"
  }

  tags {
    Name    = "bastion"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }

  volume_tags {
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }

  user_data = <<EOF
#!/bin/bash
yum update -y -q
yum erase -y -q ntp*
yum -y -q install chrony git
service chronyd start
EOF

  provisioner "file" {
    source      = "${path.root}/../data/${var.protected_key}.pem"
    destination = "/home/${var.bastion_user}/.ssh/${var.protected_key}.pem"

    connection {
      type        = "ssh"
      user        = "${var.bastion_user}"
      private_key = "${file("${path.root}/../data/${var.bastion_key}.pem")}"
      timeout     = "5m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 0400 /home/${var.bastion_user}/.ssh/*.pem",
    ]

    connection {
      type        = "ssh"
      user        = "${var.bastion_user}"
      private_key = "${file("${path.root}/../data/${var.bastion_key}.pem")}"
    }
  }
}

resource "aws_instance" "protected" {
  associate_public_ip_address = false
  ami                         = "${data.aws_ami.target_ami.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.protected_key}"
  vpc_security_group_ids      = ["${aws_security_group.protected_ssh_access.id}"]
  subnet_id                   = "${aws_subnet.protected.id}"

  root_block_device = {
    volume_type = "gp2"
    volume_size = "${var.root_vol_size}"
  }

  tags {
    Name    = "protected"
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }

  volume_tags {
    Project = "${var.tags["project"]}"
    Owner   = "${var.tags["owner"]}"
    Client  = "${var.tags["client"]}"
  }

  user_data = <<EOF
#!/bin/bash
yum update -y -q
yum erase -y -q ntp*
yum -y -q install chrony git
service chronyd start
EOF
}
