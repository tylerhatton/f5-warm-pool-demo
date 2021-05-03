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

resource "aws_security_group" "bigip_1arm" {
  name        = "${var.name_prefix}-bigip-1arm-sg"
  description = "Allow inbound mgmt and https traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "bigip_1arm" {
  name          = "${var.name_prefix}-bigip-1arm-template"
  image_id      = data.aws_ami.latest_f5_image.id
  key_name      = var.key_pair
  instance_type = var.instance_type
  user_data     = base64encode(data.template_file.user_data.rendered)
  tags          = var.default_tags

  network_interfaces {
    subnet_id       = var.external_subnet_id
    security_groups = [aws_security_group.bigip_1arm.id]
    description     = "external"
    device_index    = 0
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(tomap({ "Name" = "F5_LTM" }), var.default_tags)
  }
}

resource "aws_autoscaling_group" "bigip_1arm" {
  name                      = "${var.name_prefix}-bigip-1arm-asg"
  vpc_zone_identifier       = [var.external_subnet_id]
  desired_capacity          = 2
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  target_group_arns      = module.nlb.target_group_arns

  launch_template {
    id      = aws_launch_template.bigip_1arm.id
    version = "$Latest"
  }

  warm_pool {
    pool_state                  = "Stopped"
    min_size                    = 1
    max_group_prepared_capacity = 3
  }
}

module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name               = "${var.name_prefix}-external-nlb"
  load_balancer_type = "network"
  vpc_id             = var.vpc_id
  subnets            = [var.external_subnet_id]

  http_tcp_listeners = [
    {
      port               = 443
      protocol           = "TCP"
      target_group_index = 0
    },
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 1
    }
  ]

  target_groups = [
    {
      backend_protocol = "TCP"
      backend_port     = 443
      target_type      = "instance"
    },
    {
      backend_protocol = "TCP"
      backend_port     = 80
      target_type      = "instance"
    },
  ]

  tags = var.default_tags
}
