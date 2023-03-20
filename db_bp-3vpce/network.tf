# Create networking VPC resources

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"

  name = local.prefix
  cidr = local.vpc_cidr
  azs  = data.aws_availability_zones.available.names
  tags = local.tags

  enable_dns_hostnames = true

  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false
  
  create_igw = true

  public_subnets = [cidrsubnet(local.vpc_cidr,3,0)]
  private_subnets = [cidrsubnet(local.vpc_cidr,3,1),
  cidrsubnet(local.vpc_cidr,3,2),
  cidrsubnet(local.vpc_cidr,3,3)
  ]
}

# modify security groups
resource "aws_security_group" "databricks_sg" {
    
  vpc_id = module.vpc.vpc_id
  
  egress {
            from_port = 443
            to_port = 443
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
  egress {
            from_port = 3306
            to_port = 3306
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
  egress {
            from_port = 6666
            to_port = 6666
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }

  egress {
            self = true
            from_port = 0
            to_port = 65535
            protocol = "tcp"
    }
  egress {
            self = true
            from_port = 0
            to_port = 65535
            protocol = "udp"
    }

  ingress {
            self = true
            from_port = 0
            to_port = 65535
            protocol = "tcp"
    }
  ingress {
            self = true
            from_port = 0
            to_port = 65535
            protocol = "udp"
    }

  tags = local.tags
}


# 4 - create service endpoints for AWS services
# S3 endpoint
resource "aws_vpc_endpoint" "s3" {
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_id = module.vpc.vpc_id
  route_table_ids = module.vpc.private_route_table_ids
  tags = local.tags
  vpc_endpoint_type = "Gateway"
}

# Kinesis endpoint
resource "aws_vpc_endpoint" "kinesis" {
  service_name = "com.amazonaws.${var.region}.kinesis-streams"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  tags = local.tags
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.databricks_sg.id]
  private_dns_enabled = true
}

# STS endpoint
resource "aws_vpc_endpoint" "sts" {
  service_name = "com.amazonaws.${var.region}.sts"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  tags = local.tags
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.databricks_sg.id]
  private_dns_enabled = true
}