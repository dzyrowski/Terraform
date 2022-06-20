terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.19.0"
    }
  }
}

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

#Create public subnets
resource "aws_subnet" "week19public1" {
  vpc_id                  = aws_vpc.week19vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "week19public1"
  }
}

resource "aws_subnet" "week19public2" {
  vpc_id                  = aws_vpc.week19vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "week19public2"
  }
}

#Create private subnets 
resource "aws_subnet" "week19private1" {
  vpc_id                  = aws_vpc.week19vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "week19private1"
  }
}

resource "aws_subnet" "week19private2" {
  vpc_id                  = aws_vpc.week19vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "week19private2"
  }
}

#Public Route table
resource "aws_route_table" "publicrt" {
  vpc_id = aws_vpc.week19vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.week19IG.id
  }
    tags = {
    Name = "publicrt"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "week19IG" {
  vpc_id = aws_vpc.week19vpc.id
  tags = {
    Name = "week19IG"
  }
}

#Create public security group for VPC
resource "aws_security_group" "vpc-sg" {
  name        = "vpc-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.week19vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-sg"  
  }
}

#Associate public subnets with route table
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.week19public1.id
  route_table_id = aws_route_table.publicrt.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.week19public2.id
  route_table_id = aws_route_table.publicrt.id
}

#Create EC2 instances in public subnets 
resource "aws_instance" "public1ec2" {
  ami                    = "ami-0cff7528ff583bf9a"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a"
  security_groups        = [aws_security_group.vpc-sg.id]
  subnet_id              = aws_subnet.week19public1.id
  tags = {
    Name = "public1ec2"
  }
}

resource "aws_instance" "public2ec2" {
  ami                    = "ami-0cff7528ff583bf9a"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1b"
  vpc_security_group_ids = [aws_security_group.vpc-sg.id]
  subnet_id              = aws_subnet.week19public2.id
  tags = {
    Name = "public2ec2"
  }
}

#Create security group for RDS database.
resource "aws_security_group" "RDS-sg" {
  name        = "RDS-sg"
  description = "Allow inbound traffic from web layer"
  vpc_id      = aws_vpc.week19vpc.id

  ingress {
    description     = "Allow traffic from web layer"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc-sg.id]
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc-sg.id]
    cidr_blocks     = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS-sg"
  }
}

#Create RDS Database, launch Database in private subnets
resource "aws_db_instance" "db1" {
  allocated_storage      = 10
  db_subnet_group_name   = "db_subnet"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  
  username               = "admin"
  password               = "password"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.RDS-sg.id]
}

resource "aws_db_subnet_group" "db_subnet" {
  name       = "db_subnet"
  subnet_ids = [aws_subnet.week19private1.id, aws_subnet.week19private2.id]

  tags = {
    Name = "RDS subnet group"
  }
}

#Create Load Balancer/Load Balancer Target Group
resource "aws_alb" "week19alb" {
  name               = "week19alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.vpc-sg.id]
  subnets            = [aws_subnet.week19public1.id, aws_subnet.week19public2.id]
}
