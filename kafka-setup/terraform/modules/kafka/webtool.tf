resource "aws_security_group" "kafka-webtool" {
  name        = "Kafka Webtool Security Group"
  description = "Allow Connection with Kafka Webtool"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_ips
  }

  ingress {
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_ips
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_ips
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_ips
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
          var.tags_shared,
          map( 
            "Name", "Zookeeper Security Group",
          )
        ) 

  lifecycle {
    ignore_changes = [tags["data-criacao"]]
  }
}

data "template_file" "init-webtool" {
    template = file("${path.module}/scripts/init.cfg")
}

data "template_file" "setup-webtool" {
    template = file("${path.module}/scripts/setup-webtool.sh")
    vars = {
      ZOOKEEPER_HOSTS = join( ",", 
          formatlist(
            "%s", 
            [for o in data.aws_subnet.selected : cidrhost(o.cidr_block, var.zookeeper_hostnum_suffix)], 
          )
        )
        KAFKA_HOSTS = join( ",", 
          formatlist(
            "%s", 
            [for o in data.aws_subnet.selected : cidrhost(o.cidr_block, var.kafka_hostnum_suffix)], 
          )
        )
        ZOO_NAVIGATOR_DEPLOYMENT = base64encode(templatefile("${path.module}/values/zoonavigator-docker-compose.yml", {}))
        KAFKA_MANAGER_DEPLOYMENT = base64encode(templatefile("${path.module}/values/kafka-manager-docker-compose.tpl", {KAFKA_MANAGER_SECRET = var.kafka_manager_password }))
        KAFKA_TOPICS_UI_DEPLOYMENT = base64encode(templatefile("${path.module}/values/kafka-topics-ui-docker-compose.tpl", {KAFKA_MANAGER_SECRET = var.kafka_manager_password }))
    }
}

data "template_cloudinit_config" "config-webtool" {
    gzip = true
    base64_encode = true

    part {
        filename = "init.cfg"
        content_type = "text/cloud-config"
        content = data.template_file.init-webtool.rendered
    }

    part {
        content_type = "text/x-shellscript"
        content = data.template_file.setup-webtool.rendered
    }
}

resource "aws_instance" "webtool" {
  count = var.kafka_install_webtool ? 1 : 0
  instance_type          = var.kafka_webtool_intance_size
  key_name               = var.ssh_key_name
  ami                    = data.aws_ami.ubuntu.id
  user_data_base64       = data.template_cloudinit_config.config-webtool.rendered
  vpc_security_group_ids = [aws_security_group.kafka-webtool.id]
  subnet_id              = element(var.subnets_ids, count.index)
  tags = merge(
          var.tags_shared,
          map( 
            "Name", "kafka-webtool",
          )
        ) 
  volume_tags = merge(
                  var.tags_shared,
                  map( 
                    "Name", "kafka-webtool",
                  )
                ) 
  
  lifecycle {
    ignore_changes = [tags["data-criacao"]]
  }
}