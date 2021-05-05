output "admin_username" {
  value     = var.admin_username
  sensitive = true
}


output "admin_password" {
  value     = var.admin_password != "" ? var.admin_password : random_password.admin_password.result
  sensitive = true
}
