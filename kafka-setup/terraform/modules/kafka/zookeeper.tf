data "template_file" "init-zookeeper" {
    template = file("${path.module}/scripts/init.cfg")
}

data "template_file" "setup-zookeeper" {
    template = file("${path.module}/scripts/setup-zookeeper.sh")
    vars = {
        ZOOKEEPER_SERVICE =  base64encode(templatefile("${path.module}/scripts/zookeeper.service", {}))
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
        ZOOKEEPER_PROPERTIES = var.zookeeper_properties_base64 != null ? (
                    var.zookeeper_properties_base64) : ( 
                    base64encode(templatefile("${path.module}/values/zookeeper.properties", {}))
                  )     
    }
}

data "template_cloudinit_config" "config-zookeeper" {
    gzip = true
    base64_encode = true

    part {
        filename = "init.cfg"
        content_type = "text/cloud-config"
        content = data.template_file.init-zookeeper.rendered
    }

    part {
        content_type = "text/x-shellscript"
        content = data.template_file.setup-zookeeper.rendered
    }
}

resource "aws_network_interface" "zookeeper" {
  count = var.zookeeper_instance_number
  subnet_id       = element(var.subnets_ids, count.index)
  private_ips     = [cidrhost(data.aws_subnet.selected[count.index].cidr_block, var.zookeeper_hostnum_suffix)]
  security_groups = [aws_security_group.zookeeper.id]
   tags = merge(
          var.tags_shared,
          map( 
            "Name", "zookeeper-${count.index}",
          )
        )
}


resource "aws_instance" "zookeeper" {
  count = var.zookeeper_instance_number
  instance_type          = var.zookeeper_instance_size
  key_name               = var.ssh_key_name
  ami                    = data.aws_ami.ubuntu.id
  user_data_base64       = data.template_cloudinit_config.config-zookeeper.rendered
  network_interface {
    network_interface_id = aws_network_interface.zookeeper[count.index].id
    device_index         = 0
  }
  tags = merge(
          var.tags_shared,
          map( 
            "Name", "zookeeper-${count.index}",
          )
        ) 
  volume_tags = merge(
                  var.tags_shared,
                  map( 
                    "Name", "zookeeper-${count.index}",
                  )
                ) 
  
  lifecycle {
    ignore_changes = [tags["data-criacao"]]
  }
}