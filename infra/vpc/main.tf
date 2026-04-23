resource "aws_vpc" "pgagi_vpc" {
    enable_dns_hostnames = true
    enable_dns_support = true
    cidr_block = var.vpc_cidr

    tags = {
        owner = var.owner
        team = var.team
    }
}



resource "aws_internet_gateway" "igw_gateway" {
    vpc_id = aws_vpc.pgagi_vpc.id

    tags = {
        owner = var.owner
        team = var.team
    }
}
resource "aws_eip" "nat1_eip" {
    domain = "vpc"
}
resource "aws_nat_gateway" "nat_gateway" {
    allocation_id = aws_eip.nat1_eip.id
    subnet_id = aws_subnet.pgagi_pubsub1.id

    depends_on = [aws_internet_gateway.igw_gateway]
}





resource "aws_subnet" "pgagi_pubsub1" {
    vpc_id = aws_vpc.pgagi_vpc.id
    availability_zone = "ap-south-1a"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    tags = {
        team = var.team
        owner = var.owner
        name = "public_subnet"
    }
}
resource "aws_subnet" "pgagi_pubsub2" {
    vpc_id = aws_vpc.pgagi_vpc.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1b"
    tags = {
        owner = var.owner
        team = var.team
    }
}
resource "aws_route_table" "pub_route_table" {
    vpc_id = aws_vpc.pgagi_vpc.id
    tags = {
        owner = var.owner
        team = var.team
    }
}
resource  "aws_route" "pub_route"{
    route_table_id = aws_route_table.pub_route_table.id
    gateway_id = aws_internet_gateway.igw_gateway.id
    destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route_table_association" "pubsub1_assoc" {
    route_table_id = aws_route_table.pub_route_table.id
    subnet_id = aws_subnet.pgagi_pubsub1.id
}

resource "aws_route_table_association" "pubsub2_assoc" {
    route_table_id = aws_route_table.pub_route_table.id
    subnet_id = aws_subnet.pgagi_pubsub2.id
}





resource "aws_subnet" "pgagi_prisub1" {
    availability_zone = "ap-south-1c"
    vpc_id = aws_vpc.pgagi_vpc.id
    map_public_ip_on_launch = false
    cidr_block = "10.0.3.0/24"
    tags = {
        owner = var.owner
        team = var.team
    }
}
resource "aws_subnet" "pgagi_prisub2" {
    availability_zone = "ap-south-1b"
    vpc_id = aws_vpc.pgagi_vpc.id
    map_public_ip_on_launch = false
    cidr_block = "10.0.4.0/24"
    tags = {
        owner = var.owner
        team = var.team
    }
}
resource "aws_route_table" "pri_route_table" {
    vpc_id = aws_vpc.pgagi_vpc.id
    tags = {
        owner = var.owner
        team = var.team
    }
}
resource "aws_route" "pri_route" {
    destination_cidr_block = "0.0.0.0/0"
    route_table_id = aws_route_table.pri_route_table.id
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "prisub1_asssoc"{
    route_table_id = aws_route_table.pri_route_table.id
    subnet_id = aws_subnet.pgagi_prisub1.id
}
resource "aws_route_table_association" "prisub2_assoc" {
    route_table_id = aws_route_table.pri_route_table.id
    subnet_id = aws_subnet.pgagi_prisub2.id
  
}