# Configure the Provider
provider "aws" {
    region = "us-east-1"
}

#Create VPC
resource "aws_vpc" "week19vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "week19vpc"
    }
}

#Configure public subnets
resource "aws_subnet" "week19public1" {
    vpc_id                  = aws_vpc.week19vpc
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "us-east-1a"
    map_public_ip_on_launch = true
        tags = {
            Name = "week19public1"
    }
}

resource "aws_subnet" "week19public2" {
    vpc_id                  = aws_vpc.week19vpc
    cidr_block              = "10.0.2.0/24"
    availability_zone       = "us-east-1b"
    map_public_ip_on_launch = true
        tags = {
            Name = "week19public2"
    }
}



#Configure private subnets 
resource "aws_subnet" "week19private1" {
    vpc_id                  = aws_vpc.week19vpc
    cidr_block              = "10.0.3.0/24"
    availability_zone       = "us-east-1a"
    map_public_ip_on_launch = false
        tags = {
            Name = "week19private1"
    }
}

resource "aws_subnet" "week19private2" {
    vpc_id                  = aws_vpc.week19vpc
    cidr_block              = "10.0.4.0/24"
    availability_zone       = "us-east-1b"
    map_public_ip_on_launch = false
        tags = {
            Name = "week19private2"
    }
}

#Internet Gateway
resource "aws_internet_gateway" "week19IG" {
    vpc_id =aws_vpc.week19vpc
    tags = { 
        Name = "week19IG"
    }
}

#Nat Gateway
resource ""
#Route table
resource "aws_route_table" "week19rt" {
    vpc_id  = aws_vpc.week19vpc
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.week19IG
    }
    tags = {
        Name = "week19rt"
    }
}

#Associate public subnets with route table
resource "aws_route_table_associaton" "public1" {
    subnet_id   = aws_subnet.week19public1.id
    route_table_id = aws_route_table.week19rt.id
}

resource "aws_route_table_associaton" "public2" {
    subnet_id   = aws_subnet.week19public2.id
    route_table_id = aws_route_table.week19rt.id
}
















    
}
