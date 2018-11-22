#------networking/variables.tf

variable "vpc_cidr" {}

variable "public_cidrs" {
  type = "list"
}

variable "db_cidrs" {
  type = "list"
}

variable "vault_cidrs" {
  type = "list"
}

variable "accessip" {}
