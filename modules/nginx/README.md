# Nginx Terraform Module

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| vpc\_id | ID of VPC to house NGINX instance. | `string` | n/a |
| subnet\_id | ID of subnet to house NGINX instance. | `string` | n/a |
| key\_pair | Name of AWS key pair used to authenticate into NGINX instance. | `string` | `""` |
| name\_prefix | Prefix prepended to names of generated resources. | `string` | n/a |
| default\_tags | n/a | `map(any)` | `{}` |
| instance\_type | Size of NGINX's EC2 instance. | `string` | `"t2.large"` |
| desired\_capacity | Desired number of Nginx instances in autoscaling group. | `number` | `2` |
| min\_size | Minimum number of Nginx instances in autoscaling group. | `number` | `1` |
| max\_size | Maximum number of Nginx instances in autoscaling group. | `number` | `5` |

## Outputs

No output.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->