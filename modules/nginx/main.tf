data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

resource "aws_autoscaling_group" "nginx" {
  name                 = "${var.name_prefix}-nginx-asg"
  launch_configuration = aws_launch_template.nginx.name
  desired_capacity     = var.desired_capacity
  min_size             = var.min_size
  max_size             = var.max_size
  vpc_zone_identifier  = [var.subnet_id]

  instance_refresh {
    strategy = "Rolling"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "nginx" {
  name          = "${var.name_prefix}-nginx-template"
  image_id      = data.aws_ami.ubuntu.id
  key_name      = var.key_pair
  instance_type = var.instance_type
  user_data     = base64encode(file("${path.module}/scripts/nginx.sh"))
  tags          = var.default_tags

  network_interfaces {
    subnet_id             = var.subnet_id
    security_groups       = [aws_security_group.nginx.id]
    delete_on_termination = true
    description           = "external"
    device_index          = 0
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(tomap({
      "Name" = "NGINX"
      "Type" = "NGINX"
    }), var.default_tags)
  }
}

resource "aws_security_group" "nginx" {
  name   = "${var.name_prefix}nginx"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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
