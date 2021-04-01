# MSK Module

This module intends to provide a quick way to provisioning a MSK (Kafka) Cluster on AWS. Setting up Kafka optimized configurations, monitoring, logs on S3 and a minimum security design.

## How to Use
---

```bash
module "msk" {
  source              = "./msk" # Path to module
  msk_name            = "Kafka-Demo"
  vpc_id              = "vpc-030fe380efbf5ecc5"
  private_subnets_ids = ["subnet-0541692d11843dea2", "subnet-0cfdc8c3bf95e336f", "subnet-0369d3e194fdb43c9"]
}
```

## Argument Reference
---
The following arguments are supported:

* `msk_name` - (Required) The MSK Cluster`s Name.

* `msk_version` - (Optional) Kafka Version to be installed on MSK Cluster. Defaults `2.7.0`.

* `msk_number_of_brokers` - (Optional) Number of Brokers on MSK Cluster. Defaults `3`.

* `msk_broker_instance_size` - (Optional) Broker's instance type. Defaults `kafka.t3.small`.

* `msk_broker_ebs_size` - (Optional) Size of the Disk Storare (EBS) in GB, attached on each broker. Defaults `10`.

* `msk_broker_client_encryption_in_transit` - (Optional) Protocol used by client communication with the MSK Cluster. Valid values are: `TLS`, `TLS_PLAINTEXT`, and `PLAINTEXT`. Defaults `TLS_PLAINTEXT`.

* `msk_broker_in_cluster_encryption_in_transit` - (Optional) Forces SSL on intra broker communication. Defaults `false`.

* `msk_allowed_output_ips` - (Optional) List of allowed output CIDRs attached on MSK's security group. Defaults `[0.0.0.0/0]`.

* `msk_allowed_security_group_ids` - (Optional) List of security groups ids allowed to communicate with MSK's cluster. Defaults `[]`.

* `msk_server_properties_file_path` - (Optional) Kafka's server properties file path, meaning the Kafka's brokers configurations. Defaults `null`, which represents the file [kafka.properties](./values/kafka.properties).

* `msk_broker_log_bucket_id` - (Optional) S3 bucket where Kafka's brokers will create their logs files. Defaults `null`, meaning that a new bucket will be created concating the `msk_name`.

* `msk_storage_autoscalling_config` - (Optional) Map representing the MSK's storage autoscaling configuration. The value `null` disable the storage autoscalling. The following values are supported:

  * `msk_broker_maximum_ebs_size` - The maximum size in GB that the EBS attached on each broker is allowed to reach. Defaults `100`.

  * `autoscalling_percentage_target` - Percentage representing the amount of disk used on broker that will trigger the storage autoscalling. Defaults `75`
   
* `vpc_id` - (Required) VPC's ID where the MSK Cluster will be created.

* `private_subnets_ids` - (Required) List of subnets' ids where the MSK brokers will be created.

* `tags` - (Optional) Map of tags that will be attached on created resources. Defaults `{ "Terraform" = "true" }`.

## Attributes Reference
---

* `arn` - MSK's ARN (Amazon Resource Name).

* `zookeeper_connect_string` - A comma separated list of one or more hostname:port pairs to use to connect to the Apache Zookeeper cluster. 

* `bootstrap_brokers` - A comma separated list of one or more hostname:port pairs of kafka brokers suitable to boostrap connectivity to the kafka cluster. Only contains value if `msk_broker_client_encryption_in_transit` is set to `PLAINTEXT` or `TLS_PLAINTEXT`.

* `bootstrap_brokers_tls` - A comma separated list of one or more DNS names (or IPs) and TLS port pairs kafka brokers suitable to boostrap connectivity to the kafka cluster. Only contains value if `msk_broker_client_encryption_in_transit` is set to `TLS_PLAINTEXT` or `TLS`.

* `msk_client_security_group_id` - Id of the security group that allows communication with MSK Cluster.