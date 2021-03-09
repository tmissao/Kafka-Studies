module "SsmVpcId" {
  create = var.enable_ssm
  source                     = "../ssm"
  key = "vpc-id"
  prefix = "${var.vpc_name}-"
  value = "${aws_vpc.vpc.id}"
  tags_shared = var.tags_shared
}

module "SsmPublicSubnetIds" {
  create = var.enable_ssm
  source                     = "../ssm"
  key = "public-subnets-ids"
  prefix = "${var.vpc_name}-"
  type = "StringList"
  value = "${join(",", aws_subnet.public.*.id)}"
  tags_shared = var.tags_shared
}

module "SsmPrivateSubnetIds" {
  create = var.enable_ssm
  source                     = "../ssm"
  key = "private-subnets-ids"
  prefix = "${var.vpc_name}-"
  type = "StringList"
  value = "${join(",", aws_subnet.private.*.id)}"
  tags_shared = var.tags_shared
}