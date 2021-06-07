# F5 Warm Pool Demo
A basic demonstration of using warm pool and lifecycle events to speed up and streamline the scaling of BIG-IP instances in AWS.
![Architecture diagram](images/2.png)



## Getting Started

To provision the demo infrastructure defined in this repository, you will need a current version of [HashiCorp Terraform](https://www.terraform.io/downloads.html) and working [AWS Access Key and Access Secret](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys)

Once installed, clone down this repository and provision the infrastructure using Terraform by running the following command in the repository's root directory:

```
$ terraform apply
```

The template will use PAYG or AWS pay-as-you-go licensing by default. To use BYOL licensing with BIG-IQ, create a Terraform variables file in the repoitory's root directory called **terraform.tfvars** and populate the file with the following variables:

```
license_type                   = "BYOL"
bigiq_server                   = "(Your BIG-IQ Instance's hostname or IP)"
bigiq_license_pool_name        = "(Name of BIG-IQ license pool being used to license BIG-IP)"
bigiq_username_secret_location = "(Username to authenticate into BIG-IQ and get license)"
bigiq_password_secret_location = "(Password to authenticate into BIG-IQ and get license)"
```

## What gets built?

As part of the Terraform template, here is a high level overview of what is provisioned:

* VPC with a private and public subnet.
* AWS Managed NAT Gateway
* EC2 Auto Scaling Group containing 3x F5 BIG-IP VEs. 1 of 3 BIG-IPs is part of the warm pool and stopped by default.
* NLB to load balance across Auto Scaling Group instances.
* SNS topic to handle Auto Scaling Group lifecycle hooks.
* Lambda function to handle and process lifecycle events sent by SNS.
* S3 bucket to store F5 AS3 configurations.
* A bunch of IAM policies and roles to provide permissions across the various AWS services utilized.
* A couple security group to enable network communicate of AWS services and F5 BIG-IP.

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
| bigiq\_license\_pool\_name | Name of BIG-IQ license pool used to license BYOL instances. | `string` | `"default_pool"` |
| bigiq\_username\_secret\_location | Name of AWS Secrets Manager secret that contains the username used to license BYOL instances. | `string` | `"bigiq_username"` |
| bigiq\_password\_secret\_location | Name of AWS Secrets Manager secret that contains the password used to license BYOL instances. | `string` | `"bigiq_password"` |

## Outputs

| Name | Description |
|------|-------------|
| bigip\_admin\_username | n/a |
| bigip\_admin\_password | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->