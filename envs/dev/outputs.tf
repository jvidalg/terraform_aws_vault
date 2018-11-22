#----root/outputs.tf-----

#----storage outputs------

output "Bucket Name" {
  value = "${module.storage.bucketname}"
}

#---Networking Outputs -----

output "Public Subnets" {
  value = "${join(", ", module.networking.public_subnets)}"
}
output "DB Subnets" {
  value = "${join(", ", module.networking.db_subnets)}"
}

output "Vault Subnets" {
  value = "${join(", ", module.networking.vault_subnets)}"
}

output "Subnet IPs" {
  value = "${join(", ", module.networking.subnet_ips)}"
}

output "Public Security Group" {
  value = "${module.networking.public_sg}"
}

#---Application Outputs ------

#output "Public Instance IDs" {
#  value = "${module.application.server_id}"
#}

#output "Public Instance IPs" {
#  value = "${module.application.server_ip}"
#}

output "ELB URL" {
  value = "${module.application.lb_url}"
}
