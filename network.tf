resource "aws_vpc" "main" {
  cidr_block           = var.network.VPC.CIDR
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = var.vpc_name
    Application = "Wordpress-on-Fargate"
    Network     = "Public"
  }
}

resource "aws_subnet" "main_public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.network.Public0.CIDR
  map_public_ip_on_launch = true
  availability_zone       = join("", ["eu-west-1", lookup(var.AZRegions["eu-west-1"], "AZs", [])[0]])
  tags = {
    Application = "Wordpress-on-Fargate"
    Network     = "Public"
    Name        = join("-", [var.vpc_name, "public", lookup(var.AZRegions["eu-west-1"], "AZs", [])[0]])
  }
}

resource "aws_subnet" "PublicSubnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.network.Public1.CIDR
  map_public_ip_on_launch = true
  availability_zone       = join("", ["eu-west-1", lookup(var.AZRegions["eu-west-1"], "AZs", [])[1]])
  tags = {
    Application = "Wordpress-on-Fargate"
    Network     = "Public"
    Name        = join("-", [var.vpc_name, "public", lookup(var.AZRegions["eu-west-1"], "AZs", [])[1]])
  }
}

resource "aws_subnet" "PrivateSubnet0" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network.Private0.CIDR
  availability_zone = join("", ["eu-west-1", lookup(var.AZRegions["eu-west-1"], "AZs", [])[0]])
  tags = {
    Application = "Wordpress-on-Fargate"
    Network     = "Private"
    Name        = join("-", [var.vpc_name, "private", lookup(var.AZRegions["eu-west-1"], "AZs", [])[0]])
  }
}

resource "aws_subnet" "PrivateSubnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network.Private1.CIDR
  availability_zone = join("", ["eu-west-1", lookup(var.AZRegions["eu-west-1"], "AZs", [])[1]])
  tags = {
    Application = "Wordpress-on-Fargate"
    Network     = "Private"
    Name        = join("-", [var.vpc_name, "private", lookup(var.AZRegions["eu-west-1"], "AZs", [])[1]])
  }
}

resource "aws_internet_gateway" "vpc-eu-west-1-dev-web-app-IGW" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = join("-", [var.vpc_name, "IGW"])
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc-eu-west-1-dev-web-app-IGW.id
  }
  tags = {
    Application = "Wordpress-on-Fargate"
    Network     = "Public"
    Name        = join("-", [var.vpc_name, "public-route-table"])
  }
}

resource "aws_route_table_association" "public0" {
  subnet_id      = aws_subnet.main_public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.PublicSubnet1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private0" {
  subnet_id      = aws_subnet.PrivateSubnet0.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.PrivateSubnet1.id
  route_table_id = aws_route_table.private2.id
}

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.main_public_1.id, aws_subnet.PublicSubnet1.id]
  tags = {
    Application = "Wordpress-on-Fargate"
    Network     = "Public"
    Name        = join("-", [var.vpc_name, "public-nacl"])
  }
}

resource "aws_network_acl_rule" "egress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "ingress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535
}

resource "aws_eip" "IP1" {
  domain = "vpc"
}

resource "aws_eip" "IP2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "public_nat1" {
  allocation_id = aws_eip.IP1.allocation_id
  subnet_id     = aws_subnet.main_public_1.id
}

resource "aws_nat_gateway" "public_nat2" {
  allocation_id = aws_eip.IP2.allocation_id
  subnet_id     = aws_subnet.PublicSubnet1.id
}

resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public_nat1.id
  }

  tags = {
    Name = join("-", [var.vpc_name, "private-route-table-1"])
  }
}

resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public_nat2.id
  }

  tags = {
    Name = join("-", [var.vpc_name, "private-route-table-2"])
  }
}
