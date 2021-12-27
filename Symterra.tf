#Defining the provider
provider "aws" {
    project = "Symbiosis-Portal"
}

#Creating a Virtual Private Cloud
resource "aws_vpc" "sym_vpc" {
    cidr_block  = "10.0.0.0/16"
    tags = {
        Name = "SYM_VPC"
  }
}

#Creating Subnets
resource "aws_subnet" "public_web_subnet_1" {
  tags = {
    Name = "Public Subnet 1"
  }
  vpc_id     = aws_vpc.sym_vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-southeast-1"
}

resource "aws_subnet" "public_web_subnet_2" {
    tags = {
    Name = "Public Subnet 2"
  }
    vpc_id     = aws_vpc.sym_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-southeast-2"
}

#Creating private DB Subnet
resource "aws_subnet" "private_db_subnet" {
    tags = {
    Name = "DB Subnet"
  }
    vpc_id     = aws_vpc.sym_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-northeast-1"
}

#Setting up an internet gateway
resource "aws_internet_gateway" "sym_vpc_igw" {
  tags = {
    Name = "SYM VPC Internet Gateway"
  }
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "sym_vpc_public" {
    tags = {
    Name = "Sym Public Route Table"
  }
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.sym_vpc_igw.id
    }
}

resource "aws_route_table_association" "sym_vpc_ap_southeast_1_public" {
    subnet_id = aws_subnet.public_web_subnet_1.id
    route_table_id = aws_route_table.sym_vpc_public.id
}

resource "aws_route_table_association" "sym_vpc_ap_southeast_2_public" {
    subnet_id = aws_subnet.public_web_subnet_2.id
    route_table_id = aws_route_table.sym_vpc_public.id
}

#Creating a Security Group for the Web Instance
resource "aws_security_group" "web_sg"{
    tags = {
    Name = "Web Security Group"
  }
    name = "web_sg"
    description = "Allow HTTP inbound traffic"
    vpc_id = aws_vpc.sym_vpc.id

    ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

    egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Creating a Security Group for the Database Instance
resource "aws_security_group" "web_sg"{
    tags = {
    Name = "Web Security Group"
  }
    name = "web_sg"
    description = "Allow HTTP inbound traffic"
    vpc_id = aws_vpc.sym_vpc.id

    ingress {
    protocol = "tcp"
    from_port = 5432
    to_port = 5432
    security_groups = [aws_security_group.web_sg.id]
  }
