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
variable "eks_cluster_identifier" { default= "eks-demo"}
variable "eks_cluster_version" { default = "1.18" }
variable "eks_nodes" { default = [ 
    {
        "label" = "worker"
        "instanceType" = "m5.large"
        "minSize" = 2
        "desiredSize" = 2
        "maxSize" = 10
        "instanceOnDemandPercentagem" = 0
        "instanceOndemandBaseSize" = 0
        "enableAutoScale" = true
    }
 ]}
variable "eks_hpa_deployment_values_path" { default = "./deployments/hpa-values.tmpl" }
variable "eks_auto-scaler_deployment_values_path" { default = "./deployments/autoscaler-values.tmpl" }

# variable "eks_ec2_setup" { default = true  }
# variable "eks_cluster_identifier" { default= "ava30"}
# variable "eks_cluster_version" { default = "1.14" }
# variable "eks_cluster_allowed_ingress_ips" { default = ["0.0.0.0/0"] }
# variable "eks_worker_node_autoscaling_max_size" { default = 2 }
# variable "eks_worker_node_autoscaling_min_size" { default = 1 }
# variable "eks_worker_node_autoscaling_desired_capacity" { default = 2 }
# variable "eks_worker_node_autoscaling_policy_high_cpu_scaling_adjustment" { default = 1 }
# variable "eks_worker_node_cloudwatch_metric_alarm_high_cpu_threshold" { default = 70 }
# variable "eks_worker_node_autoscaling_policy_low_cpu_scaling_adjustment" { default = -1 }
# variable "eks_worker_node_cloudwatch_metric_alarm_low_cpu_threshold" { default = 30 }
# variable "eks_shared_security_group" { default = true }
# variable "eks_istio_loadbalancer_ssm_sufix" { default = "istio-loadbalancer" }
# variable "eks_appdynamics_should_install" {default = 0 }
# variable "eks_appdynamics_license" { default = "" }
# variable "eks_appdynamics_cluster_name" { default = "AVA 3.0"}
# variable "eks_appdynamics_controller_url" {default = "https://kroton.saas.appdynamics.com" }
# variable "eks_appdynamics_account" {default = "kroton" }
# variable "eks_appdynamics_docker_image" {default = "049058846518.dkr.ecr.us-east-1.amazonaws.com/ava30/appdynamics:20.8.0" }

