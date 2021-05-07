locals {
  admin_password = var.admin_password != "" ? var.admin_password : random_password.admin_password.result
}

resource "random_password" "admin_password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "bigip_username" {
  name  = "/big-ip/credentials/bigip-username"
  type  = "SecureString"
  value = var.admin_username
  tags  = var.default_tags
}

resource "aws_ssm_parameter" "bigip_password" {
  name  = "/big-ip/credentials/bigip-password"
  type  = "SecureString"
  value = local.admin_password
  tags  = var.default_tags
}

data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.tpl")

  vars = {
    hostname            = var.hostname
    bigip_username      = var.admin_username
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
    subnet_id             = var.external_subnet_id
    security_groups       = [aws_security_group.bigip_1arm.id]
    delete_on_termination = true
    description           = "external"
    device_index          = 0
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(tomap({ "Name" = "F5_LTM" }), var.default_tags)
  }
}

resource "aws_autoscaling_group" "bigip_1arm" {
  name                      = "${var.name_prefix}-bigip-1arm-asg"
  vpc_zone_identifier       = [var.external_subnet_id]
  desired_capacity          = 5
  max_size                  = 6
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  target_group_arns         = module.nlb.target_group_arns

  instance_refresh {
    strategy = "Rolling"
  }

  launch_template {
    id      = aws_launch_template.bigip_1arm.id
    version = "$Latest"
  }

  initial_lifecycle_hook {
    name                    = "${var.name_prefix}-bigip-1arm-launch"
    default_result          = "CONTINUE"
    heartbeat_timeout       = 60
    lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
    notification_target_arn = aws_sns_topic.bigip_1arm.arn
    role_arn                = aws_iam_role.bigip_1arm.arn
  }

  warm_pool {
    pool_state                  = "Stopped"
    min_size                    = 1
    max_group_prepared_capacity = 3
  }
}

resource "aws_sns_topic" "bigip_1arm" {
  name = "${var.name_prefix}-bigip-1arm"
}

resource "aws_sns_topic_subscription" "bigip_1arm" {
  topic_arn = aws_sns_topic.bigip_1arm.arn
  protocol  = "lambda"
  endpoint  = module.lifecycle_hook_lambda_function.lambda_function_arn
}

resource "aws_lambda_permission" "bigip_1arm" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.lifecycle_hook_lambda_function.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.bigip_1arm.arn
}

resource "aws_iam_role" "bigip_1arm" {
  name = "${var.name_prefix}-bigip-1arm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "autoscaling.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "${var.name_prefix}-bigip-1arm"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = ["sns:Publish"]
          Effect = "Allow"
          Resource = [
            aws_sns_topic.bigip_1arm.arn
          ]
        }
      ]
    })
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

  lb_tags = var.default_tags
}

module "lifecycle_hook_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "bigip-1arm-lifecycle-function"
  description   = "Lifecycle hook lambda function for BIG-IP 1arm configuration."
  handler       = "app.lambda_handler"
  runtime       = "python3.8"
  source_path   = "${path.module}/lifecycle-hook"
  tags          = var.default_tags

  attach_policy_json = true
  policy_json        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances"
            ],
            "Resource": ["*"]
        },
        {
            "Effect": "Allow",
            "Action": [
              "ssm:GetParameter",
              "ssm:GetParameters"
            ],
            "Resource": [
              "${aws_ssm_parameter.bigip_username.arn}",
              "${aws_ssm_parameter.bigip_password.arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
              "autoscaling:CompleteLifecycleAction"
            ],
            "Resource": [
              "${aws_autoscaling_group.bigip_1arm.arn}"
            ]
        } 
    ]
}
EOF
}
