resource "aws_security_group" "client" {
  name        = "MSK${title(var.msk_name)}Client"
  description = "Allow Connection with MSK ${title(var.msk_name)}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.msk_allowed_output_ips
  }

  tags = merge(
          var.tags,
          map( 
            "Name", "MSK${title(var.msk_name)}Client",
          )
        )     
}

resource "aws_security_group" "msk" {
  name        = "MSK${title(var.msk_name)}"
  description = "SG For MSK ${title(var.msk_name)}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Zookeeper Plaintext and SSL Ports"
    from_port       = 2181
    to_port         = 2182
    protocol        = "tcp"
    security_groups = concat(
      var.msk_allowed_security_group_ids, list(aws_security_group.client.id)
    )
  }

  ingress {
    description     = "Brokers Plaintext, SSL and SASL Ports"
    from_port       = 9092
    to_port         = 9094
    protocol        = "tcp"
    security_groups = concat(
      var.msk_allowed_security_group_ids, list(aws_security_group.client.id)
    )
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.msk_allowed_output_ips
  }

  tags = merge(
          var.tags,
          map( 
            "Name", "MSK${title(var.msk_name)}",
          )
        ) 
}

resource "aws_s3_bucket" "logs" {
  count = var.msk_broker_log_bucket_id == null ? 1 : 0
  bucket = "msk-${var.msk_name}-broker-logs"
  acl    = "private"
}

resource "aws_msk_configuration" "server-properties" {
  kafka_versions = list(var.msk_version)
  name           = var.msk_name
  server_properties = var.msk_server_properties_file_path == null ? ( 
                        templatefile("${path.module}/values/kafka.properties", {}) ) : (
                        var.msk_server_properties_file_path
                      )
}

resource "aws_msk_cluster" "msk" {
  cluster_name = var.msk_name
  kafka_version = var.msk_version
  number_of_broker_nodes = var.msk_number_of_brokers
  configuration_info {
    arn = aws_msk_configuration.server-properties.arn
    revision = aws_msk_configuration.server-properties.latest_revision
  }
  broker_node_group_info {
    instance_type = var.msk_broker_instance_size
    ebs_volume_size = var.msk_broker_ebs_size
    client_subnets = var.private_subnets_ids
    security_groups = [aws_security_group.msk.id]
  }
  encryption_info {
    encryption_in_transit {
      client_broker = var.msk_broker_client_encryption_in_transit
      in_cluster = var.msk_broker_in_cluster_encryption_in_transit
    }
  }
  logging_info {
    broker_logs {
      s3 {
        enabled = true
        bucket = var.msk_broker_log_bucket_id == null ? aws_s3_bucket.logs[0].id : var.msk_broker_log_bucket_id
        prefix  = "logs/msk-"
      }
    }
  }
  tags = var.tags
}

resource "aws_appautoscaling_target" "msk-storage-autoscalling" {
  count = var.msk_storage_autoscalling_config != null ? 1 : 0
  service_namespace  = "kafka"
  scalable_dimension = "kafka:broker-storage:VolumeSize"
  resource_id        = aws_msk_cluster.msk.arn
  min_capacity       = 1
  max_capacity       =  var.msk_storage_autoscalling_config.msk_broker_maximum_ebs_size
}

resource "aws_appautoscaling_policy" "msk-storage-autoscalling-policy" {
  count = var.msk_storage_autoscalling_config != null ? 1 : 0
  name               = "msk-${var.msk_name}-storage-autoscalling-policy"
  service_namespace  = "kafka"
  scalable_dimension = "kafka:broker-storage:VolumeSize"
  resource_id        = aws_msk_cluster.msk.arn
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value       = var.msk_storage_autoscalling_config.autoscalling_percentage_target
    predefined_metric_specification {
      predefined_metric_type = "KafkaBrokerStorageUtilization"
    }
  }
}