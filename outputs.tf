output "jumpbox_ip" {
  value = module.jumpbox.jumpbox_ip
}

output "jumpbox_username" {
  value = module.jumpbox.jumpbox_username
}

output "jumpbox_password" {
  value     = module.jumpbox.jumpbox_password
  sensitive = true
}

output "bigip_admin_username" {
  value     = module.bigip_1arm_autoscale.admin_username
  sensitive = true
}

output "bigip_admin_password" {
  value     = module.bigip_1arm_autoscale.admin_password
  sensitive = true
}