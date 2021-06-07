variable "name_prefix" {
  type    = string
  default = "default"
}

variable "owner" {
  type        = string
  default     = null
  description = "The name of the owner that will be tagged to the provisioned resources."
}

variable "key_pair" {
  type        = string
  default     = null
  description = "Name of AWS key pair to be used to access EC2 instances."
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