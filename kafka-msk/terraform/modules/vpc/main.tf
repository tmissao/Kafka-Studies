data "aws_availability_zones" "azs" {}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_classiclink   = false

  tags = var.is_eks_enabled ? "${
      merge(
        var.tags_shared,
        map( 
          "Name", var.vpc_name,
          "kubernetes.io/cluster/${var.eks_name}", "shared"
        )
      ) 
  }" : "${
      merge(
        var.tags_shared,
        map( 
          "Name", var.vpc_name,
        )
      ) 
  }"
  lifecycle {
    ignore_changes = [tags["data-criacao"]]
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets_cidr_block)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(var.public_subnets_cidr_block, count.index)
  availability_zone       = element(data.aws_availability_zones.azs.names, count.index)
  map_public_ip_on_launch = true

  tags = var.is_eks_enabled ? merge(
        var.tags_shared,
        map( 
          "Name", "${var.vpc_name}-public-${element(data.aws_availability_zones.azs.names, count.index)}",
          "kubernetes.io/cluster/${var.eks_name}", "shared"
        )
      ) : merge(
        var.tags_shared,
        map( 
          "Name", "${var.vpc_name}-public-${element(data.aws_availability_zones.azs.names, count.index)}",
        )
      ) 
  lifecycle {
    ignore_changes = [tags["data-criacao"]]
  }    
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
          var.tags_shared,
          map( 
            "Name", "${var.vpc_name}-igw-vpc",
          )
        )   
  lifecycle {
    ignore_changes = [tags["data-criacao"]]
  }
}

resource "aws_subnet" "private" {
  count                   = length(var.private_subnets_cidr_block)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(var.private_subnets_cidr_block, count.index)
  availability_zone       = element(data.aws_availability_zones.azs.names, count.index)
  map_public_ip_on_launch = false

  tags = merge(
          var.tags_shared,
          map( 
            "Name", "${var.vpc_name}-private-${element(data.aws_availability_zones.azs.names, count.index)}",
          )
        ) 
  lifecycle {
    ignore_changes = [tags["data-criacao"]]
  }   
}

resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
          var.tags_shared,
          map( 
            "Name", "${var.vpc_name}-public-route",
          )
        ) 
  lifecycle {
    ignore_changes = [tags["data-criacao"]]
  } 
}

resource "aws_route" "public-route" {
  route_table_id            = aws_route_table.public-route.id
  destination_cidr_block    = var.all_allowed_output_ips
  gateway_id    = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public-association" {
  count          = length(var.public_subnets_cidr_block)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public-route.id
}

resource "aws_eip" "nat-ips" {
  vpc        = true
  tags = merge(
        var.tags_shared,
        map( 
          "Name", "${var.vpc_name}-NAT-EIP",
        )
      )   
  lifecycle {
    ignore_changes = [tags["data-criacao"]]
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat-ips.id
  subnet_id     = aws_subnet.public.0.id
  depends_on    = [aws_internet_gateway.igw]

  tags = merge(
          var.tags_shared,
          map( 
            "Name", "${var.vpc_name}-igw-nat-vpc",
          )
        ) 
  lifecycle {
    ignore_changes = [tags["data-criacao"]]
  }  
}

resource "aws_route_table" "private-route" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
          var.tags_shared,
          map( 
            "Name", "${var.vpc_name}-private-route",
          )
        ) 
  lifecycle {
    ignore_changes = [tags["data-criacao"]]
  } 
}

resource "aws_route" "private-route" {
  route_table_id            = aws_route_table.private-route.id
  destination_cidr_block    = var.all_allowed_output_ips
  nat_gateway_id    = aws_nat_gateway.nat-gw.id
}

resource "aws_route_table_association" "private-association" {
  count          = length(var.private_subnets_cidr_block)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private-route.id
}
