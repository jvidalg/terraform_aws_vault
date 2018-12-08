#-----compute/variables.tf

variable "key_name" {}

variable "public_key_path" {}

#variable "public_key" {}

variable "subnet_ips" {
  type = "list"
}

#variable "instance_count" {}

variable "instance_type" {}

variable "security_group" {}

variable "subnets" {
  type = "list"
}

variable "elb_sg" {}

variable "vault_ips" {
    type = "list"
}

variable "db_subnets" {
    type = "list"
}

variable "vault_subnets" {
    type = "list"
}
