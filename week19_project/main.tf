# Configure the Provider
provider "aws" {
    region = "us-east-1"
}

# Create VPC
resource "aws vpc" "week19vpc"
    