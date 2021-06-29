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
| instance\_type | Size of F5 BIG-IP's EC2 instance. | `string` | `"m5.xlarge"` |
| admin\_username | Admin username for F5 management console and SSH server. | `string` | `"admin"` |
| admin\_password | Admin password for F5 management console and SSH server. | `string` | `""` |
| hostname | Hostname of F5 BIG-IP. | `string` | `"demo-f5.example.com"` |
| vpc\_id | ID of the VPC where the F5 BIG-IP will reside. | `string` | n/a |
| external\_subnet\_id | ID of F5 BIG-IP's external subnet. | `string` | n/a |
| internal\_subnet\_id | ID of F5 BIG-IP's internal subnet. | `string` | n/a |
| name\_prefix | Prefix applied to name of resources | `string` | `""` |
| default\_tags | n/a | `map(any)` | `{}` |
| desired\_capacity | Desired number of BIG-IPs in autoscale group | `number` | `2` |
| max\_size | Maximum number of BIG-IPs in autoscale group | `number` | `5` |
| min\_size | Minimum number of BIG-IPs in autoscale group | `number` | `1` |
| warm\_pool\_min\_size | Minimum number of BIG-IPs in the autoscale group's warm pool | `number` | `1` |
| warm\_pool\_max\_prepared\_capacity | Maximum number of BIG-IPs in the autoscale group's warm pool | `number` | `3` |
| license\_type | Type of license used to license BIG-IP instances. BYOL or PAYG | `string` | `"PAYG"` |
| bigiq\_server | Hostname or IP address of BIG-IQ server used to license BYOL BIG-IP instances. | `string` | `""` |
| bigiq\_license\_pool\_name | Name of BIG-IQ license pool used to license BYOL instances. | `string` | `"default_pool"` |
| bigiq\_username\_secret\_location | Name of AWS Secrets Manager secret that contains the username used to license BYOL instances. | `string` | `"bigiq_username"` |
| bigiq\_password\_secret\_location | Name of AWS Secrets Manager secret that contains the password used to license BYOL instances. | `string` | `"bigiq_password"` |

## Outputs

| Name | Description |
|------|-------------|
| admin\_username | n/a |
| admin\_password | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->