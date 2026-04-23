terraform {
    required_providers {
        aws = {
            source = "Hashicorp/aws"
            version = "6.28.0"
        }
    }
}
provider "aws" {
    region = "ap-south-1"
}