terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.17.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "4.20.1"
    }
  }
}

provider "docker" {}

provider "aws" {
  region = "us-east-1"
}

#Create VPC
resource "aws_vpc" "w20_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Week 20 VPC"
  }
}

#Create subnets
resource "aws_subnet" "w20_privatesub1" {
  vpc_id     = aws_vpc.w20_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Week 20 Private Subnet 1"
  }
}

resource "aws_subnet" "week20public1" {
  vpc_id                  = aws_vpc.w20_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "week20public1"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "week20IG" {
  vpc_id = aws_vpc.w20_vpc.id
  tags = {
    Name = "week20IG"
  }
}

#create ECS Cluster
resource "aws_ecs_cluster" "w20_ecs" {
  name = "w20_ecs"
}

resource "aws_ecs_cluster_capacity_providers" "w20_ecs_providers" {
  cluster_name = aws_ecs_cluster.w20_ecs.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }
}

#Fargate module
module "ecs-fargate" {
  source  = "umotif-public/ecs-fargate/aws"
  version = "~> 6.1.0"

  name_prefix        = "ecs-fargate-w20_fargate"
  vpc_id             = aws_vpc.w20_vpc.id
  private_subnet_ids = [aws_subnet.w20_privatesub1.id, aws_subnet.week20public1.id]

  cluster_id = aws_ecs_cluster.w20_ecs.id

  task_container_image   = "centos:latest"
  task_definition_cpu    = 256
  task_definition_memory = 512

  task_container_port             = 80
  task_container_assign_public_ip = true

  load_balanced = false

  target_groups = [
    {
      target_group_name = "tg-fargate-week20"
      container_port    = 80
    }
  ]

  health_check = {
    port = "traffic-port"
    path = "/"
  }

  tags = {
    Environment = "test"
    Project     = "Test"
  }
}