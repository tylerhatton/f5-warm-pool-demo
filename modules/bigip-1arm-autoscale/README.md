# bigip-1arm-autoscale

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_template"></a> [template](#provider\_template) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lifecycle_hook_lambda_function"></a> [lifecycle\_hook\_lambda\_function](#module\_lifecycle\_hook\_lambda\_function) | terraform-aws-modules/lambda/aws | n/a |
| <a name="module_nlb"></a> [nlb](#module\_nlb) | terraform-aws-modules/alb/aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.bigip_1arm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_iam_instance_profile.bigip_1arm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.bigip_1arm_lf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.bigip_1arm_lh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.bigip_1arm_lt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_lambda_permission.bigip_1arm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_launch_template.bigip_1arm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_s3_bucket.bigip_1arm_as3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_object.bigip_1arm_as3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_secretsmanager_secret.bigip_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.bigip_username](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.bigip_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.bigip_username](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.bigip_1arm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_sns_topic.bigip_1arm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.bigip_1arm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [random_password.admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.bucket_prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.secret_prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_ami.latest_f5_image](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_secretsmanager_secret_version.bigiq_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_version.bigiq_username](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [template_file.user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_key_pair"></a> [key\_pair](#input\_key\_pair) | Name of key pair to SSH into the F5 BIG-IP. | `string` | `null` |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Size of F5 BIG-IP's EC2 instance. | `string` | `"m5.xlarge"` |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | Admin username for F5 management console and SSH server. | `string` | `"admin"` |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Admin password for F5 management console and SSH server. | `string` | `""` |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Hostname of F5 BIG-IP. | `string` | `"demo-f5.example.com"` |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where the F5 BIG-IP will reside. | `string` | n/a |
| <a name="input_external_subnet_id"></a> [external\_subnet\_id](#input\_external\_subnet\_id) | ID of F5 BIG-IP's external subnet. | `string` | n/a |
| <a name="input_internal_subnet_id"></a> [internal\_subnet\_id](#input\_internal\_subnet\_id) | ID of F5 BIG-IP's internal subnet. | `string` | n/a |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix applied to name of resources | `string` | `""` |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | n/a | `map(any)` | `{}` |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | Desired number of BIG-IPs in autoscale group | `number` | `2` |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of BIG-IPs in autoscale group | `number` | `5` |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of BIG-IPs in autoscale group | `number` | `1` |
| <a name="input_warm_pool_min_size"></a> [warm\_pool\_min\_size](#input\_warm\_pool\_min\_size) | Minimum number of BIG-IPs in the autoscale group's warm pool | `number` | `1` |
| <a name="input_warm_pool_max_prepared_capacity"></a> [warm\_pool\_max\_prepared\_capacity](#input\_warm\_pool\_max\_prepared\_capacity) | Maximum number of BIG-IPs in the autoscale group's warm pool | `number` | `3` |
| <a name="input_license_type"></a> [license\_type](#input\_license\_type) | Type of license used to license BIG-IP instances. BYOL or PAYG | `string` | `"PAYG"` |
| <a name="input_bigiq_server"></a> [bigiq\_server](#input\_bigiq\_server) | Hostname or IP address of BIG-IQ server used to license BYOL BIG-IP instances. | `string` | `""` |
| <a name="input_bigiq_license_pool_name"></a> [bigiq\_license\_pool\_name](#input\_bigiq\_license\_pool\_name) | Name of BIG-IQ license pool used to license BYOL instances. | `string` | `"default_pool"` |
| <a name="input_bigiq_username_secret_location"></a> [bigiq\_username\_secret\_location](#input\_bigiq\_username\_secret\_location) | Name of AWS Secrets Manager secret that contains the username used to license BYOL instances. | `string` | `"bigiq_username"` |
| <a name="input_bigiq_password_secret_location"></a> [bigiq\_password\_secret\_location](#input\_bigiq\_password\_secret\_location) | Name of AWS Secrets Manager secret that contains the password used to license BYOL instances. | `string` | `"bigiq_password"` |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_username"></a> [admin\_username](#output\_admin\_username) | n/a |
| <a name="output_admin_password"></a> [admin\_password](#output\_admin\_password) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->