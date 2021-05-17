# F5 Warm Pool Demo
A basic demonstration of using warm pool and lifecycle events to speed up the scaling of BIG-IP instances in AWS.
![Lifecycle Hooks Diagram](images/1.png)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.15.1 |
| aws | >= 3.27.0 |
| random | >= 3.1.0 |
| template | >= 2.2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.27.0 |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| name\_prefix | n/a | `string` | `"default"` |
| owner | The name of the owner that will be tagged to the provisioned resources. | `string` | `null` |
| key\_pair | Name of AWS key pair to be used to access EC2 instances. | `string` | `null` |
| license\_type | Type of license used to license BIG-IP instances. BYOL or PAYG | `string` | `"PAYG"` |
| bigiq\_server | Hostname or IP address of BIG-IQ server used to license BYOL BIG-IP instances. | `string` | `""` |

## Outputs

| Name | Description |
|------|-------------|
| bigip\_admin\_username | n/a |
| bigip\_admin\_password | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->