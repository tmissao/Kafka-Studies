provider "aws" {
  access_key = lookup(var.aws_access_key, var.environment)
  secret_key = lookup(var.aws_secret_key, var.environment)
  region     = var.aws_region
}
