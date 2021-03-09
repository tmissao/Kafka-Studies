variable "vpc_name" { default = "vpc-default" }
variable "vpc_cidr_block" { default = "10.2.0.0/16" }
variable "public_subnets_cidr_block" { default  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"] }
variable "private_subnets_cidr_block" { default = ["10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"] }
variable "public_subnets"  { default = 3 }
variable "private_subnets" { default = 3 }
variable "all_allowed_output_ips" { default = "0.0.0.0/0" }
variable "is_eks_enabled" { default = "false" }
variable "eks_name"   { default = null }
variable "enable_ssm" { default = true }

variable "tags_shared" {
  type = map(string)
  default = {
    "Owner"        = "System Team"
    "ConfiguredBy" = "System Team"
    "Environment"  = "Dev"
    "Terraform"    = "true"
  }
}
