variable "instance_class" {}

variable "retention_period" {}

variable "db_subnets" {
  type = "list"
}

variable "security_group" {}

variable "rds_password" {}

variable "rds_username" {}

variable "enable_replica" {}
