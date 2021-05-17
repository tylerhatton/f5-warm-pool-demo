locals {
  admin_password = var.admin_password != "" ? var.admin_password : random_password.admin_password.result
  ami_name       = var.license_type == "PAYG" ? "F5 BIGIP-15.1.2.1-0.0.10 PAYG-Best 1Gbps*" : "F5 BIGIP-15.1.2.1-0.0.10 BYOL-All Modules 2Boot*"
}

/*
* BIG-IP Username and Password
*/

resource "random_password" "admin_password" {
  length  = 16
  special = false
}

resource "random_string" "secret_prefix" {
  length  = 5
  special = false
}

resource "aws_secretsmanager_secret" "bigip_username" {
  name = "${random_string.secret_prefix.result}-bigip_username"
}

resource "aws_secretsmanager_secret_version" "bigip_username" {
  secret_id     = aws_secretsmanager_secret.bigip_username.id
  secret_string = var.admin_username
}

resource "aws_secretsmanager_secret" "bigip_password" {
  name = "${random_string.secret_prefix.result}-bigip_password"
}

resource "aws_secretsmanager_secret_version" "bigip_password" {
  secret_id     = aws_secretsmanager_secret.bigip_password.id
  secret_string = local.admin_password
}

/*
* BIG-IP Launch Template and Autoscale group
*/

data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.tpl")

  vars = {
    admin_password_secret          = aws_secretsmanager_secret.bigip_password.id
    bigiq_username_secret_location = var.bigiq_username_secret_location
    bigiq_password_secret_location = var.bigiq_password_secret_location
    bigiq_server                   = var.bigiq_server
    license_pool                   = var.bigiq_license_pool_name
    license_type                   = var.license_type
  }
}

data "aws_ami" "latest_f5_image" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = [local.ami_name]
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
    from_port   = 80
    to_port     = 80
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

  iam_instance_profile {
    name = aws_iam_instance_profile.bigip_1arm.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(tomap({ "Name" = "F5_LTM" }), var.default_tags)
  }
}

resource "aws_iam_instance_profile" "bigip_1arm" {
  name = "bigip_1arm"
  role = aws_iam_role.bigip_1arm_lt.name
}

data "aws_secretsmanager_secret_version" "bigiq_username" {
  secret_id = var.bigiq_username_secret_location
}

data "aws_secretsmanager_secret_version" "bigiq_password" {
  secret_id = var.bigiq_password_secret_location
}

resource "aws_iam_role" "bigip_1arm_lt" {
  name        = "${var.name_prefix}-bigip-1arm-lt"
  description = "AWS role assigned to BIG-IP devices"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "${var.name_prefix}-bigip-1arm-lt"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = ["secretsmanager:GetSecretValue"]
          Effect = "Allow"
          Resource = [
            aws_secretsmanager_secret.bigip_password.arn,
            data.aws_secretsmanager_secret_version.bigiq_username.arn,
            data.aws_secretsmanager_secret_version.bigiq_password.arn
          ]
        },
        {
          Action = [
            "ec2:DescribeInstances",
            "ec2:DescribeInstanceStatus",
            "ec2:DescribeAddresses",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeNetworkInterfaceAttribute",
            "ec2:DescribeRouteTables"
          ]
          Effect   = "Allow"
          Resource = ["*"]
        }
      ]
    })
  }
}

resource "aws_autoscaling_group" "bigip_1arm" {
  name                      = "${var.name_prefix}-bigip-1arm-asg"
  vpc_zone_identifier       = [var.external_subnet_id]
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_grace_period = 600
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
    default_result          = "ABANDON"
    heartbeat_timeout       = 840
    lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
    notification_target_arn = aws_sns_topic.bigip_1arm.arn
    role_arn                = aws_iam_role.bigip_1arm_lh.arn
  }

  initial_lifecycle_hook {
    name                    = "${var.name_prefix}-bigip-1arm-terminate"
    default_result          = "CONTINUE"
    heartbeat_timeout       = 60
    lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
    notification_target_arn = aws_sns_topic.bigip_1arm.arn
    role_arn                = aws_iam_role.bigip_1arm_lh.arn
  }

  warm_pool {
    pool_state                  = "Stopped"
    min_size                    = var.warm_pool_min_size
    max_group_prepared_capacity = var.warm_pool_max_prepared_capacity
  }
}

/*
* Autoscale Lifecycle hook
*/

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

resource "aws_iam_role" "bigip_1arm_lh" {
  name        = "${var.name_prefix}-bigip-1arm-lh"
  description = "IAM Role for autoscaling to call SNS for BIG-IP autoscale lifecycle hook"

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
    name = "${var.name_prefix}-bigip-1arm-lh"

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

module "lifecycle_hook_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "bigip-1arm-lifecycle-function"
  description   = "Lifecycle hook lambda function for BIG-IP 1arm configuration."
  handler       = "app.lambda_handler"
  runtime       = "python3.8"
  source_path   = "${path.module}/lifecycle-hook"
  create_role   = false
  lambda_role   = aws_iam_role.bigip_1arm_lf.arn
  timeout       = 900
  tags          = var.default_tags

  environment_variables = {
    USER_SECRET_LOCATION       = aws_secretsmanager_secret.bigip_username.id
    PASS_SECRET_LOCATION       = aws_secretsmanager_secret.bigip_password.id
    AS3_BUCKET_NAME            = aws_s3_bucket.bigip_1arm_as3.id
    LICENSE_TYPE               = var.license_type
    BIGIQ_LICENSE_POOL_NAME    = var.bigiq_license_pool_name
    BIGIQ_SERVER               = var.bigiq_server
    BIGIQ_USER_SECRET_LOCATION = var.bigiq_username_secret_location
    BIGIQ_PASS_SECRET_LOCATION = var.bigiq_password_secret_location
  }
}

resource "aws_iam_role" "bigip_1arm_lf" {
  name        = "${var.name_prefix}-bigip-1arm-lf"
  description = "IAM Role for Lambda to call required resources for BIG-IP autoscale lifecycle hook lambda function"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "${var.name_prefix}-bigip-1arm-lf"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["ec2:DescribeInstances"]
          Effect   = "Allow"
          Resource = ["*"]
        },
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = ["*"]
        },
        {
          Action = ["secretsmanager:GetSecretValue"]
          Effect = "Allow"
          Resource = [
            aws_secretsmanager_secret.bigip_username.arn,
            aws_secretsmanager_secret.bigip_password.arn,
            data.aws_secretsmanager_secret_version.bigiq_username.arn,
            data.aws_secretsmanager_secret_version.bigiq_password.arn
          ]
        },
        {
          Action   = ["s3:ListBucket"]
          Effect   = "Allow"
          Resource = [aws_s3_bucket.bigip_1arm_as3.arn]
        },
        {
          Action   = ["s3:GetObject"]
          Effect   = "Allow"
          Resource = ["${aws_s3_bucket.bigip_1arm_as3.arn}/*"]
        },
        {
          Action   = ["autoscaling:CompleteLifecycleAction"]
          Effect   = "Allow"
          Resource = ["*"]
        }
      ]
    })
  }
}

/*
* NLB
*/

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

/*
* AS3 S3 Bucket
*/

resource "random_string" "bucket_prefix" {
  length  = 5
  special = false
  upper   = false
}

resource "aws_s3_bucket" "bigip_1arm_as3" {
  bucket = "${var.name_prefix}-${random_string.bucket_prefix.result}-bigip-1arm-as3"
  acl    = "private"
  tags   = var.default_tags
}

resource "aws_s3_bucket_object" "bigip_1arm_as3" {
  for_each = fileset("${path.module}/as3", "**/*.json")

  bucket = aws_s3_bucket.bigip_1arm_as3.bucket
  key    = "as3-declarations/${each.value}"
  source = "${path.module}/as3/${each.value}"
}
