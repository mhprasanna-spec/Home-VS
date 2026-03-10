resource "aws_vpc" "main_vpc" {
    cidr_block = var.vpc_cidr

    tags = {
        Name = "My-VPC"
    }
  
}

resource "aws_subnet" "public_subnet" {
  
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.main_vpc.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
tags = {
  Name = "public-subnet-${count.index + 1}"
  }

}

resource "aws_subnet" "private_subnet" {
    count = length(var.private_subnet_cidrs)
  
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
tags = {
  Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id

    tags = {
        Name = "main-igw"
    }
  
}

resource "aws_eip" "nat_eip" {
  
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.public_subnet[0].id

    tags = {
        Name = "nat-gateway"
    }
  
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_instance_gateway.igw.id
  }
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "pub_ass" {
  
  count = length(aws_subnet.public_subnet)
    subnet_id = aws_subnet.public_subnet[count.index].id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pvt_ass" {
  count = length(aws_subnet.private_subnet)
    subnet_id = aws_subnet.private_subnet[count.index].id
    route_table_id = aws_route_table.private_rt.id
}
