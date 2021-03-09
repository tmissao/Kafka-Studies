data "template_file" "init-kafka" {
    template = file("${path.module}/scripts/init.cfg")
}

data "template_file" "setup-kafka" {
    template = file("${path.module}/scripts/setup-kafka.sh")
    vars = {
        KAFKA_SERVICE =  base64encode(templatefile("${path.module}/scripts/kafka.service", {}))
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
        KAFKA_PROPERTIES = var.kafka_properties_base64 != null ? (
                            var.kafka_properties_base64) : ( 
                            base64encode(templatefile("${path.module}/values/kafka.properties", {}))
                          )   
    }
}

data "template_cloudinit_config" "config-kafka" {
    gzip = true
    base64_encode = true

    part {
        filename = "init.cfg"
        content_type = "text/cloud-config"
        content = data.template_file.init-kafka.rendered
    }

    part {
        content_type = "text/x-shellscript"
        content = data.template_file.setup-kafka.rendered
    }
}

resource "aws_network_interface" "kafka" {
  count = var.kafka_instance_number
  subnet_id       = element(var.subnets_ids, count.index)
  private_ips     = [cidrhost(data.aws_subnet.selected[count.index].cidr_block, var.kafka_hostnum_suffix)]
  security_groups = [aws_security_group.zookeeper.id]
   tags = merge(
          var.tags_shared,
          map( 
            "Name", "kafka-${count.index}",
          )
        )
}

resource "aws_instance" "kafka" {
  count = var.kafka_instance_number
  instance_type          = var.kafka_instance_size
  key_name               = var.ssh_key_name
  ami                    = data.aws_ami.ubuntu.id
  user_data_base64       = data.template_cloudinit_config.config-kafka.rendered
  network_interface {
    network_interface_id = aws_network_interface.kafka[count.index].id
    device_index         = 0
  }
  tags = merge(
          var.tags_shared,
          map( 
            "Name", "kafka-${count.index}",
          )
        ) 
  volume_tags = merge(
                  var.tags_shared,
                  map( 
                    "Name", "kafka-${count.index}",
                  )
                ) 
  
  lifecycle {
    ignore_changes = [tags["data-criacao"]]
  }
}


resource "aws_ebs_volume" "kafka-volume" {
  count = var.kafka_instance_number
  availability_zone = data.aws_subnet.selected[count.index].availability_zone
  size              = var.kafka_ebs_size_gb
  encrypted         = "true"
  type              = "gp2"

  tags = merge(
          var.tags_shared,
          map( 
            "Name", "kafka-${count.index}",
          )
        ) 
}

resource "aws_volume_attachment" "kafka-volume-attachment" {
  count = var.kafka_instance_number
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.kafka-volume[count.index].id
  instance_id = aws_instance.kafka[count.index].id
}