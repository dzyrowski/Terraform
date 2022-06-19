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

#Internet Gateway
resource "aws_internet_gateway" "week19IG" {
  vpc_id = aws_vpc.week19vpc.id
  tags = {
    Name = "week19IG"
  }
}

#Create Elastic IP
resource "aws_eip" "week19ip" {
  vpc = true
  tags = {
    Name = "week19ip"
  }
}

#Nat Gateway
resource "aws_nat_gateway" "week19nat" {
  allocation_id = aws_eip.week19ip.id
  subnet_id     = aws_subnet.week19public2.id
  tags = {
    Name = "week19nat"
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

#Private Route table
resource "aws_route_table" "dbrt" {
  vpc_id = aws_vpc.week19vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.week19nat.id
  }
  tags = {
    Name = "dbrt"
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

#Associate private subnets with route table
resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.week19private1.id
  route_table_id = aws_route_table.dbrt.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.week19private2.id
  route_table_id = aws_route_table.dbrt.id
}

#Create EC2 instances in public subnets 
resource "aws_instance" "public1ec2" {
  ami                    = "ami-0cff7528ff583bf9a"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.week19lb-sg.id]
  subnet_id              = aws_subnet.week19public1.id
  tags = {
    Name = "public1ec2"
  }
}

resource "aws_instance" "public2ec2" {
  ami                    = "ami-0cff7528ff583bf9a"
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1b"
  vpc_security_group_ids = [aws_security_group.week19lb-sg.id]
  subnet_id              = aws_subnet.week19public2.id
  tags = {
    Name = "public2ec2"
  }
}

#Create public security group for VPC
resource "aws_security_group" "vpc-sg" {
  name        = "vpc-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.week19vpc.id

  ingress {
    description = "HTTP from VPC"
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

  tags = {
    Name = "vpc-sg"
  }
}

#Create security group for load balancer
resource "aws_security_group" "week19lb-sg" {
  name        = "week19lb-sg"
  description = "Allow HTTP inbound traffic from ALB"
  vpc_id      = aws_vpc.week19vpc.id

  ingress {
    description     = "Allow traffic from web"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "week19lb-sg"
  }
}

#Create Load Balancer/Load Balancer Target Group
resource "aws_lb" "week19lb" {
  name               = "week19lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.vpc-sg.id]
  subnets            = [aws_subnet.week19public1.id, aws_subnet.week19public2.id]
}

resource "aws_lb_target_group" "week19lb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.week19vpc.id
}


#Map ALB to EC2 instances
resource "aws_lb_target_group_attachment" "week19lb1" {
  target_group_arn = aws_lb_target_group.week19lb.arn
  target_id        = aws_instance.public1ec2.id
  port             = 80

  depends_on = [
    aws_instance.public1ec2,
  ]
}

resource "aws_lb_target_group_attachment" "week19lb2" {
  target_group_arn = aws_lb_target_group.week19lb.arn
  target_id        = aws_instance.public2ec2.id
  port             = 80

  depends_on = [
    aws_instance.public2ec2,
  ]
}

#Add listener to port 80
resource "aws_lb_listener" "week19lb" {
  load_balancer_arn = aws_lb.week19lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.week19lb.arn
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
    security_groups = [aws_security_group.week19lb-sg.id]
  }
  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS-sg"
  }
}

#Create RDS Database, launch Database in private subnets
resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_subnet_group_name   = aws_db_subnet_group.default.id
  engine                 = "mysql"
  engine_version         = "8.0.20"
  instance_class         = "db.t2.micro"
  multi_az               = true
  db_name                = "week19db"
  username               = "username"
  password               = "password"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.RDS-sg.id]
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.week19private1.id, aws_subnet.week19private2.id]

  tags = {
    Name = "RDS subnet group"
  }
}
