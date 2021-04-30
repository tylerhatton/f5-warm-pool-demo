variable "name_prefix" {
  type = string
  default = "default"
}

variable "owner" {
  type = string
  default = null
  description = "The name of the owner that will be tagged to the provisioned resources."
}