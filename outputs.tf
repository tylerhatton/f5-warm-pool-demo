output "jumpbox_ip" {
  value = module.jumpbox.jumpbox_ip
}

output "jumpbox_username" {
  value = module.jumpbox.jumpbox_username
}

output "jumpbox_password" {
  value = module.jumpbox.jumpbox_password
  sensitive = true
}