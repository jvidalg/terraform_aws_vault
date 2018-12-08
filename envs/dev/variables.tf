variable "aws_region" {}

#------ storage variables

variable "project_name" {}

#-------networking variables

variable "vpc_cidr" {}

variable "public_cidrs" {
  type = "list"
}

variable "db_cidrs" {
  type = "list"
}

variable "accessip" {}

#variable "vpc_id" {}

#-------application variables

variable "key_name" {}

variable "public_key_path" {}

variable "server_instance_type" {}

variable "instance_count" {
  default = 1
}

variable "rds_instance_class" {}

variable "rds_backup_period" {}

variable "rds_password" {}

variable "rds_username" {}

variable "enable_replica" {}

##------vault variables

variable "vault_cluster_size" {}

variable "vault_cluster_name" {}

variable "vault_instance_type" {}

variable "vault_consul_ami" {}

#variable "allowed_inbound_cidr_blocks" {
#  type = "list"
#}

variable "vault_cidrs" {
  type = "list"
}

variable "allowed_inbound_security_group_count" {}
variable "subnet_count" {}

#variable "user_data" {}

##------consul variables

variable "consul_cluster_name" {}
variable "consul_cluster_size" {}
