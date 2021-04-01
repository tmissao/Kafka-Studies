data "aws_caller_identity" "current" {}

module "vpc" {
  source                     = "./modules/vpc"
  vpc_name                   = var.project_name
  vpc_cidr_block             = var.vpc_cidr_block
  public_subnets_cidr_block  = var.public_subnets_cidr_block
  private_subnets_cidr_block = var.private_subnets_cidr_block
  tags_shared                = var.tags
}

module "kafka" {
  source              = "./modules/msk"
  msk_name            = "demo"
  vpc_id              = module.vpc.vpc_id
  private_subnets_ids = module.vpc.private_subnets
  tags                = var.tags
}