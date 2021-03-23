# AWS VPC Module

Este módulo ter por objetivo provisionar o recurso VPC, provisionando subnets públicas já mapeadas para um ingress gateway e subnets privadas mapeadas para um NAT gateway, bem como parametros SSM para utilização e referência da mesma.

# Utilização

```terraform
module "vpc" {
  source                     = "git@ssh.dev.azure.com:v3/kdop/System%20Team/terraform-modules//provider/aws/vpc"
  vpc_name                   = "my-vpc"
  vpc_cidr_block             = "172.16.0.0/16"
  public_subnets_cidr_block  = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  private_subnets_cidr_block = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
}
```

# Argumentos

* `vpc_name` - (Opcional) nome da VPC. O valor padrão é "vpc-default"

* `vpc_cidr_block` - (Opcional) máscara de sub-rede a ser utilizada pela vpc. O valor padrão é "10.2.0.0/16"

* `public_subnets_cidr_block` - (Opcional) lista de string com as máscaras de ip das subnets públicas, a quantidade de elementos do array deve coindicir com o valor da variável `public_subnets`. O valor padrão é ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]

* `private_subnets_cidr_block` - (Opcional) lista de string com as máscaras de ip das subnets privadas, a quantidade de elementos do array deve coindicir com o valor da variável `private_subnets`. O valor padrão é ["10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"]

* `public_subnets` - (Opcional) número de subnets públicas a serem criadas. O valor padrão é 3

* `private_subnets` - (Opcional) número de subnets privadas a serem criadas. O valor padrão é 3

* `all_allowed_output_ips` - (Opcional) faixa de ip permitida nas rotas de entrada e saída das subnets públicas e privadas. O valor padrão é "0.0.0.0/0"

* `is_eks_enabled` - (Opcional) booleando indicando se um EKS será colocado na VPC, se sim as tags `kubernetes.io/cluster/<eks_name> : shared` serão adicionadas as subnets públicas e privadas. O valor padrão é false

* `eks_name` - (Opcional) nome do eks que será adicionado à VPC, sendo que esse valor é utilizado para compor a tag `kubernetes.io/cluster/<eks_name> : shared` e sua utilização depende da ativação da variável `is_eks_enabled`. O valor padrão é null

* `enable_ssm` - (Opcional) Booleano indicando se o módulo deverá criar chaves-valor no SSM para os recursos criados. O valor padrão é true

* `tags_shared` - (Opcional) Mapa de String, chave-valor contendo as tags que serão associadas aos recursos criados

# Outputs

* `vpc_id` - id da vpc

* `ssm_vpc_id` - chave ssm com valor `vpc_id` do cluster documentdb

* `vpc_cidr_block` - máscara de sub-rede a ser utilizada pela vpc

* `public_subnets` - lista de string contendo os ids das subnets públicas da vpc

* `ssm_public_subnets_ids` - chave ssm com valor `public_subnets` do cluster documentdb

* `public_subnets_cidr_block` - lista das máscaras de ip utilizadas pelas subnets públicas

* `public_routing_table_id` - id da tabela de rotas das subnets públicas

* `public_subnets_availability_zone` - lista de availability zones das subnets públicas

* `private_subnets` - lista de string contendo os ids das subnets privadas da vpc

* `ssm_private_subnets_ids` - chave ssm com valor `private_subnets` do cluster documentdb

* `private_subnets_cidr_block` - lista das máscaras de ip utilizadas pelas subnets privadas

* `private_routing_table_id` - id da tabela de rotas das subnets privadas

* `private_subnets_availability_zone` - lista de availability zones das subnets privadas

* `vpc_default_security_group` - id da security group padrão da vpc

* `vpc_internet_gateway` - id do internet gateway da vpc

