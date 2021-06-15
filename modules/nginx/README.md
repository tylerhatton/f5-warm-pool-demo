# Nginx Terraform Module

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.nginx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_launch_template.nginx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.nginx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of VPC to house NGINX instance. | `string` | n/a |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | ID of subnet to house NGINX instance. | `string` | n/a |
| <a name="input_key_pair"></a> [key\_pair](#input\_key\_pair) | Name of AWS key pair used to authenticate into NGINX instance. | `string` | `""` |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix prepended to names of generated resources. | `string` | n/a |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | n/a | `map(any)` | `{}` |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Size of NGINX's EC2 instance. | `string` | `"t3.small"` |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | Desired number of Nginx instances in autoscaling group. | `number` | `2` |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of Nginx instances in autoscaling group. | `number` | `1` |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of Nginx instances in autoscaling group. | `number` | `5` |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->