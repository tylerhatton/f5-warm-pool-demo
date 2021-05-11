variable "vpc_id" {
  description = "ID of VPC to house NGINX instance."
  type        = string
}

variable "subnet_id" {
  description = "ID of subnet to house NGINX instance."
  type        = string
}

variable "key_pair" {
  description = "Name of AWS key pair used to authenticate into NGINX instance."
  default     = ""
  type        = string
}

variable "name_prefix" {
  description = "Prefix prepended to names of generated resources."
  type        = string
}

variable "default_tags" {
  type    = map(any)
  default = {}
}

variable "instance_type" {
  type        = string
  default     = "t3.small"
  description = "Size of NGINX's EC2 instance."
}

variable "desired_capacity" {
  description = "Desired number of Nginx instances in autoscaling group."
  default     = 2
  type        = number
}

variable "min_size" {
  description = "Minimum number of Nginx instances in autoscaling group."
  default     = 1
  type        = number
}

variable "max_size" {
  description = "Maximum number of Nginx instances in autoscaling group."
  default     = 5
  type        = number
}
