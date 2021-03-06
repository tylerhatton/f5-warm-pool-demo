variable "key_pair" {
  type        = string
  default     = null
  description = "Name of key pair to SSH into the F5 BIG-IP."
}

variable "instance_type" {
  type        = string
  default     = "m5.xlarge"
  description = "Size of F5 BIG-IP's EC2 instance."
}

variable "admin_username" {
  type        = string
  default     = "admin"
  description = "Admin username for F5 management console and SSH server."
  sensitive   = true
}

variable "admin_password" {
  type        = string
  default     = ""
  description = "Admin password for F5 management console and SSH server."
  sensitive   = true
}

variable "hostname" {
  type        = string
  default     = "demo-f5.example.com"
  description = "Hostname of F5 BIG-IP."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where the F5 BIG-IP will reside."
}

variable "external_subnet_id" {
  type        = string
  description = "ID of F5 BIG-IP's external subnet."
}

variable "internal_subnet_id" {
  type        = string
  description = "ID of F5 BIG-IP's internal subnet."
}

variable "name_prefix" {
  type        = string
  default     = ""
  description = "Prefix applied to name of resources"
}

variable "default_tags" {
  type    = map(any)
  default = {}
}

variable "desired_capacity" {
  type        = number
  default     = 2
  description = "Desired number of BIG-IPs in autoscale group"
}

variable "max_size" {
  type        = number
  default     = 5
  description = "Maximum number of BIG-IPs in autoscale group"
}

variable "min_size" {
  type        = number
  default     = 1
  description = "Minimum number of BIG-IPs in autoscale group"
}

variable "warm_pool_min_size" {
  type        = number
  default     = 1
  description = "Minimum number of BIG-IPs in the autoscale group's warm pool"
}

variable "warm_pool_max_prepared_capacity" {
  type        = number
  default     = 3
  description = "Maximum number of BIG-IPs in the autoscale group's warm pool"
}

variable "license_type" {
  type        = string
  default     = "PAYG"
  description = "Type of license used to license BIG-IP instances. BYOL or PAYG"
  validation {
    condition = (
      var.license_type == "PAYG" ||
      var.license_type == "BYOL"
    )
    error_message = "Variable license_type must be BYOL or PAYG."
  }
}

variable "bigiq_server" {
  type        = string
  default     = ""
  description = "Hostname or IP address of BIG-IQ server used to license BYOL BIG-IP instances."
}

variable "bigiq_license_pool_name" {
  type        = string
  default     = "default_pool"
  description = "Name of BIG-IQ license pool used to license BYOL instances."
}

variable "bigiq_username_secret_location" {
  type        = string
  default     = "bigiq_username"
  description = "Name of AWS Secrets Manager secret that contains the username used to license BYOL instances."
}

variable "bigiq_password_secret_location" {
  type        = string
  default     = "bigiq_password"
  description = "Name of AWS Secrets Manager secret that contains the password used to license BYOL instances."
}