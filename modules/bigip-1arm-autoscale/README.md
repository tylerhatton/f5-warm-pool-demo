# bigip-1arm-autoscale

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| random | n/a |
| template | n/a |
| aws | n/a |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| key\_pair | Name of key pair to SSH into the F5 BIG-IP. | `string` | `null` |
| instance\_type | Size of F5 BIG-IP's EC2 instance. | `string` | `"t2.large"` |
| admin\_password | Admin password for F5 management console and SSH server. | `string` | `""` |
| hostname | Hostname of F5 BIG-IP. | `string` | `"demo-f5.example.com"` |
| vpc\_id | ID of the VPC where the F5 BIG-IP will reside. | `string` | n/a |
| external\_subnet\_id | ID of F5 BIG-IP's external subnet. | `string` | n/a |
| internal\_subnet\_id | ID of F5 BIG-IP's internal subnet. | `string` | n/a |
| provisioned\_modules | List of provisioned BIG-IP modules configured on the F5 BIG-IP. | `list(string)` | <pre>[<br>  "\"ltm\": \"nominal\""<br>]</pre> |
| name\_prefix | Prefix applied to name of resources | `string` | `""` |
| default\_tags | n/a | `map(any)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| admin\_password | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->