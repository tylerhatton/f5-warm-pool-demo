output "bigip_admin_username" {
  value     = module.bigip_1arm_autoscale.admin_username
  sensitive = true
}

output "bigip_admin_password" {
  value     = module.bigip_1arm_autoscale.admin_password
  sensitive = true
}
