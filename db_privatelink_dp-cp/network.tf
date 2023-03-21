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

# Databricks Security Group
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


# create service endpoints for AWS services
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

resource "aws_security_group_rule" "s3_endpoint_rule" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = -1
  security_group_id = aws_security_group.databricks_sg.id
  prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]

  depends_on = [aws_vpc_endpoint.s3]
}

# Set up Private Link

resource "aws_subnet" "pl_net" {
    vpc_id = module.vpc.vpc_id
    cidr_block = cidrsubnet(cidrsubnet(local.vpc_cidr,3,4),6,0)
    availability_zone = data.aws_availability_zones.available.names[1] #"eu-west-1b"
    tags = merge(
            {
            Name = "PrivateLink Subnet"
            },
            local.tags
        )
}

resource "aws_route_table" "pl_rt" {
  vpc_id = module.vpc.vpc_id
}

resource "aws_route_table_association" "pl_rt" {
    subnet_id = aws_subnet.pl_net.id
    route_table_id = aws_route_table.pl_rt.id
}

resource "aws_security_group" "pl_group" {
  name = "Private Link security group"
  description = "Dedicated group for Private Link endpoints"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "HTTPS ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    
    security_groups = [aws_security_group.databricks_sg.id]
  }

   ingress {
    description = "SCC ingress"
    from_port = 6666
    to_port = 6666
    protocol = "tcp"
    
    security_groups = [aws_security_group.databricks_sg.id]
  }

   egress {
    description = "HTTPS egress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    
    security_groups = [aws_security_group.databricks_sg.id]
  }

   egress {
    description = "SCC egress"
    from_port = 6666
    to_port = 6666
    protocol = "tcp"
    
    security_groups = [aws_security_group.databricks_sg.id]
  }

  tags = local.tags
}

resource "aws_vpc_endpoint" "workspace" {
  vpc_id = module.vpc.vpc_id
  service_name = local.pl_service_workspace
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.pl_group.id]

  
  #Select the Enable DNS Hostnames and DNS Resolution options at the VPC level for both types of VPC endpoints
  subnet_ids = [aws_subnet.pl_net.id]
  private_dns_enabled = true # set to true after registration

  tags = local.tags
}

resource "aws_vpc_endpoint" "relay" {
  vpc_id = module.vpc.vpc_id
  service_name = local.pl_service_relay
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.pl_group.id]

  
  #Select the Enable DNS Hostnames and DNS Resolution options at the VPC level for both types of VPC endpoints
  subnet_ids = [aws_subnet.pl_net.id]
  private_dns_enabled =  true # set to true after registration

  tags = local.tags
}