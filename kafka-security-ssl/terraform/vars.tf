variable "aws_access_key" { type = map(string) }
variable "aws_secret_key" { type = map(string) }
variable "aws_region" { default = "us-east-2" }
variable "environment" { default = "dev" }
variable "tags" { 
  default = { 
    "data-criacao" = "202101"
    "cadeia-valor" = "Jornada Academica"
    "estagio"      = "DEV"
    "conjunto-orcamentario"= "400000030051320000200314"
    "tag-servico"  = "AVA 3.0"
    "Owner"        = "EKS AVA 3.0"
    "Environment"  = "Development"
    "Terraform"    = "true"
    "sn-produto"   = "ava30"
    "sn-modulo"    = "ava30"
  }
}

variable "project_name" { default = "eks-demo" }
variable "vpc_cidr_block" { default = "172.18.0.0/16" }
variable "public_subnets_cidr_block" { default = ["172.18.1.0/24", "172.18.2.0/24", "172.18.3.0/24"] }
variable "private_subnets_cidr_block" { default = ["172.18.4.0/24", "172.18.5.0/24", "172.18.6.0/24"] }