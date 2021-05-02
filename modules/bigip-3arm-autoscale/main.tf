locals {
  admin_password = var.admin_password != "" ? var.admin_password : random_password.admin_password.result
}

resource "random_password" "admin_password" {
  length  = 16
  special = false
}

# User Data Template
data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.tpl")

  vars = {
    hostname            = var.hostname
    bigip_password      = local.admin_password
    internal_self_ip    = ""
    provisioned_modules = join(",", var.provisioned_modules)
  }
}

data "aws_ami" "latest_f5_image" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["F5 BIGIP-15.1.2.1-0.0.10 PAYG-Good 25Mbps*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "bigip_3arm" {
  name          = "bigip-3arm-template"
  image_id      = data.aws_ami.latest_f5_image.id
  key_name      = var.key_pair
  instance_type = var.instance_type
  # user_data     = data.template_file.user_data.rendered
  tags = var.default_tags

  network_interfaces {
    subnet_id                   = var.management_subnet_id
    description                 = "mgmt"
    device_index                = 0
  }

  network_interfaces {
    subnet_id    = var.internal_subnet_id
    description  = "internal"
    device_index = 1
  }

  network_interfaces {
    subnet_id    = var.external_subnet_id
    description  = "external"
    device_index = 2
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(tomap({ "Name" = "F5_LTM" }), var.default_tags)
    # tags = var.default_tags
  }
}

resource "aws_autoscaling_group" "bigip_3arm" {
  name                      = "bigip-3arm-ag"
  availability_zones        = ["us-west-1b"]
  desired_capacity          = 2
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"

  launch_template {
    id      = aws_launch_template.bigip_3arm.id
    version = "$Latest"
  }

  warm_pool {
    pool_state                  = "Stopped"
    min_size                    = 1
    max_group_prepared_capacity = 3
  }
}
