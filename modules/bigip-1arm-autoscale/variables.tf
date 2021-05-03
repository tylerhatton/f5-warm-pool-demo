variable "key_pair" {
  type        = string
  default     = null
  description = "Name of key pair to SSH into the F5 BIG-IP."
}

variable "instance_type" {
  type        = string
  default     = "t2.large"
  description = "Size of F5 BIG-IP's EC2 instance."
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

variable "provisioned_modules" {
  type        = list(string)
  default     = ["\"ltm\": \"nominal\""]
  description = "List of provisioned BIG-IP modules configured on the F5 BIG-IP."
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
