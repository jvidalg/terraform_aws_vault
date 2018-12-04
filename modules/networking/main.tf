data "aws_availability_zones" "available" {}

resource "aws_vpc" "tf_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "tf_vpc"
  }
}

resource "aws_internet_gateway" "tf_internet_gateway" {
  vpc_id = "${aws_vpc.tf_vpc.id}"

  tags {
    Name = "tf_igw"
  }
}

resource "aws_route_table" "tf_public_rt" {
  vpc_id = "${aws_vpc.tf_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.tf_internet_gateway.id}"
  }

  tags {
    Name = "tf_public"
  }
}

resource "aws_default_route_table" "tf_private_rt" {
  default_route_table_id = "${aws_vpc.tf_vpc.default_route_table_id}"

  tags {
    Name = "tf_private"
  }
}

resource "aws_route_table" "tf_vault_rt" {
  vpc_id = "${aws_vpc.tf_vpc.id}"
  tags {
    Name = "tf_vault_private"
  }
########################################################################################
# The below routing is enabled only for demo purposes, this route should not exist in private module
########################################################################################
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.tf_internet_gateway.id}"
  }
}

#### Public Subnet #######

resource "aws_subnet" "tf_public_subnet" {
  count                   = 2
  vpc_id                  = "${aws_vpc.tf_vpc.id}"
  cidr_block              = "${var.public_cidrs[count.index]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"

  tags {
    Name = "tf_public_${count.index + 1}"
  }
}

resource "aws_route_table_association" "tf_public_assoc" {
  count          = "${aws_subnet.tf_public_subnet.count}"
  subnet_id      = "${aws_subnet.tf_public_subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.tf_public_rt.id}"
}

resource "aws_security_group" "tf_public_sg" {
  name        = "tf_public_sg"
  description = "public security group"
  vpc_id      = "${aws_vpc.tf_vpc.id}"

  #SSH

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.accessip}"]
  }

  #HTTP

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.accessip}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#### DB Subnet #######

resource "aws_subnet" "tf_db_subnet" {
  count                   = 2
  vpc_id                  = "${aws_vpc.tf_vpc.id}"
  cidr_block              = "${var.db_cidrs[count.index]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"

  tags {
    Name = "tf_db_${count.index + 1}"
  }
}

resource "aws_route_table_association" "tf_db_assoc" {
  count          = "${aws_subnet.tf_db_subnet.count}"
  subnet_id      = "${aws_subnet.tf_db_subnet.*.id[count.index]}"
  route_table_id = "${aws_default_route_table.tf_private_rt.id}"
}

resource "aws_security_group" "tf_db_sg" {
  name        = "tf_db_sg"
  description = "private sg for DB"
  vpc_id      = "${aws_vpc.tf_vpc.id}"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${element(var.public_cidrs, 0)}", "${element(var.public_cidrs, 1)}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#### Vault Subnet #######

resource "aws_subnet" "tf_vault_subnet" {
  count                   = 2
  vpc_id                  = "${aws_vpc.tf_vpc.id}"
  cidr_block              = "${var.vault_cidrs[count.index]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"

  tags {
    Name = "tf_vault_${count.index + 1}"
  }
}

resource "aws_route_table_association" "tf_vault_assoc" {
  count          = "${aws_subnet.tf_vault_subnet.count}"
  subnet_id      = "${aws_subnet.tf_vault_subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.tf_vault_rt.id}"
}


#resource "aws_security_group" "tf_vault_sg" {
#  name        = "tf_vault_sg"
#  description = "SG for Vault Cluster"
#  vpc_id      = "${aws_vpc.tf_vpc.id}"
#
#  ingress {
#    from_port   = 3306
#    to_port     = 3306
#    protocol    = "tcp"
#    cidr_blocks = ["${element(var.public_cidrs, 0)}", "${element(var.public_cidrs, 1)}"]
#  }
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#}

#### ELB ####

resource "aws_security_group" "elbsg" {
  name   = "sg_elb"
  vpc_id = "${aws_vpc.tf_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
