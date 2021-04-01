variable "msk_name" { type = string }
variable "msk_version" { default = "2.7.0" }
variable "msk_number_of_brokers" { default = 3 }
variable "msk_broker_instance_size" { default = "kafka.t3.small" }
variable "msk_broker_ebs_size" { default = "10" }
variable "msk_broker_client_encryption_in_transit" { default = "TLS_PLAINTEXT" }
variable "msk_broker_in_cluster_encryption_in_transit" { default = "false" }
variable "msk_allowed_output_ips" { default = ["0.0.0.0/0"] }
variable "msk_allowed_security_group_ids" { default = [] }
variable "msk_server_properties_file_path" { default = null }
variable "msk_broker_log_bucket_id" { default = null }
variable "msk_storage_autoscalling_config" { 
  default = {
    msk_broker_maximum_ebs_size = 100
    autoscalling_percentage_target = 75
  }
}
variable "vpc_id" { type = string }
variable "private_subnets_ids" { type = list(string) }
variable "tags" {
  type = map(string)
  default = {
    "Terraform"    = "true"
  }
}