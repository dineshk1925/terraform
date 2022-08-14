#Creating VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tendancy = "default"
  enable_dns_hostname = true

  tags = {
    name = "test_vpc"
  }
}

#Creating Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    name = "test_igw"
  }
}

#Creating 2 Public Subnet
resource "aws_subnet" "public-subnet-1" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone  = "us-east-1a"
  map_publicip_on_launch = true

  tags = {
      name = "public subnet 1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone  = "us-east-1b"
  map_publicip_on_launch = true

  tags = {
     name = "public subnet 2"
   }
}

##Create Rout Table For Public Subnet
resource "aws_route_table" "public-route-table" {
  vpc_id = "${aws_vpc.vpc.id}"
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }

  tags  = {
    name = "public route table"
  }
}

#Adding Public Subnet to Route Table
resource "aws_route_table_association" "public-subnet-1-route-table-association" {
  subnet_id      = "${aws_subnet.public-subnet-1.id}"
  route_table_id = "${aws_route_table.public-route-table.id}"
}

resource "aws_route_table_association" "public-subnet-2-route-table-association" {
  subnet_id      = "${aws_subnet.public-subnet-2.id}"
  route_table_id = "${aws_route_table.public-route-table.id}"
}

#Creating 2 Private Subnet
resource "aws_subnet" "private-subnet-1" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone_id = "us-east-1a"
  map_publicip_on_launch = false

tags = {
   name = "private_subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone_id = "us-east-1b"
  map_publicip_on_launch = false

tags = {
   name = "private_subnet-2"
  }
}

resource "aws_subnet" "private-subnet-3" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.4.0/24"
  availability_zone_id = "us-east-1a"
  map_publicip_on_launch = false

tags = {
   name = "private_subnet-3"
  }
}

resource "aws_subnet" "private-subnet-4" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.5.0/24"
  availability_zone_id = "us-east-1b"
  map_publicip_on_launch = false

tags = {
   name = "private_subnet-4"
  }
}

