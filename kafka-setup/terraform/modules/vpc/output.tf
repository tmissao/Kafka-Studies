output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${aws_vpc.vpc.id}"
}

output "ssm_vpc_id" {
  description = "SSM Key for VPC ID"
  value = "${module.SsmVpcId.parameter_name}"
}

output "vpc_cidr_block" {
  description = "The Cidr Block of the VPC"
  value       = "${aws_vpc.vpc.cidr_block}"
}

output "public_subnets" {
  description = "The Ids of public subnets"
  value       = "${aws_subnet.public.*.id}"
}

output "ssm_public_subnets_ids" {
  description = "SSM Key for VPC`s public subnets"
  value = "${module.SsmPublicSubnetIds.parameter_name}"
}

output "public_subnets_cidr_block" {
  description = "The Ids of public subnets"
  value       = "${aws_subnet.public.*.cidr_block}"
}

output "public_routing_table_id" {
  value = aws_route_table.public-route.id
}

output "private_subnets" {
  description = "The Ids of private subnets"
  value       = "${aws_subnet.private.*.id}"
}

output "ssm_private_subnets_ids" {
  description = "SSM Key for VPC`s private subnets"
  value = "${module.SsmPrivateSubnetIds.parameter_name}"
}

output "private_subnets_cidr_block" {
  description = "The Ids of private subnets"
  value       = "${aws_subnet.private.*.cidr_block}"
}

output "private_routing_table_id" {
  value = aws_route_table.private-route.id
}

output "vpc_default_security_group" {
  description = "The VPC`s default security group id"
  value       = "${aws_vpc.vpc.default_security_group_id}"
}

output "vpc_internet_gateway" {
  description = "The VPC`s default internet gateway"
  value       = "${aws_internet_gateway.igw}"
}


output "public_subnets_availability_zone" {
  description = "The availability zone of public subnets"
  value       = "${aws_subnet.public.*.availability_zone}"
}

output "private_subnets_availability_zone" {
  description = "The availability zone of private subnets"
  value       = "${aws_subnet.private.*.availability_zone}"
}