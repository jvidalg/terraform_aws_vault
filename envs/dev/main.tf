provider "aws" {
  region  = "${var.aws_region}"
  profile = "mine"
}

terraform {
  backend "s3" {
    bucket         = "tf-remote-state-bucket-demo-aws-modules-jesus"
    key            = "envs/dev/terraform.tfstate"
    dynamodb_table = "terraform-state-lock-dynamo-modules-jesus"
    region         = "us-east-1"
  }
}

## Networking Resources --------------------------------------------------

module "networking" {
  source       = "../../modules/networking"
  vpc_cidr     = "${var.vpc_cidr}"
  public_cidrs = "${var.public_cidrs}"
  db_cidrs     = "${var.db_cidrs}"
  accessip     = "${var.accessip}"
  vault_cidrs  = "${var.vault_cidrs}"

  #lb_instances  = "${module.application.web_instances}"
}

## Application Resources --------------------------------------------------

module "application" {
  source = "../../modules/application"

  #instance_count  = "${var.instance_count}"
  key_name        = "${var.key_name}"
  public_key_path = "${var.public_key_path}"
  instance_type   = "${var.server_instance_type}"
  subnets         = "${module.networking.public_subnets}"
  security_group  = "${module.networking.public_sg}"
  subnet_ips      = "${module.networking.subnet_ips}"
  elb_sg          = "${module.networking.elb_sg}"

  #Data for user-data template

  vault_ips     = "${module.networking.consul_vault_ips}"
  db_subnets    ="${module.networking.db_subnets}"
  vault_subnets = "${module.networking.vault_subnets}"

}

## DB Resources --------------------------------------------------

module "database" {
  source = "../../modules/database"

  instance_class   = "${var.rds_instance_class}"
  db_subnets       = "${module.networking.db_subnets}"
  retention_period = "${var.rds_backup_period}"
  security_group   = "${module.networking.db_sg}"
  rds_username     = "${var.rds_username}"
  rds_password     = "${var.rds_password}"
  enable_replica   = "${var.enable_replica}"
}

## Vault Cluster (dependency of private)-----------------------------------

#module "vault-cluster" {
#  source = "../../modules/vault_cluster"

#  vpc_id                               = "${module.networking.vpc_id}"
#  cluster_name                         = "${var.vault_cluster_name}"
#  instance_type                        = "${var.vault_instance_type}"
#  cluster_size                         = "${var.vault_cluster_size}"
#  ami_id                               = "${var.vault_consul_ami}"
#  allowed_inbound_cidr_blocks          = "${var.public_cidrs}"
#  allowed_inbound_security_group_ids   = ["${module.networking.db_sg}", "${module.networking.public_sg}"]
#  allowed_inbound_security_group_count = "${var.allowed_inbound_security_group_count}"
#  user_data                            = "${var.user_data}"
#  ssh_key_name                         = "${var.key_name}"
#}

## Vault Private Cluster --------------------------------------------------

module "vault-private" {
  source = "../../modules/vault_private"

  vpc_id             = "${module.networking.vpc_id}"
  vault_cluster_name = "${var.vault_cluster_name}"
  vault_cluster_size = "${var.vault_cluster_size}"
  ssh_key_name       = "${var.key_name}"
  ami_id             = "${var.vault_consul_ami}"

  consul_cluster_name = "${var.consul_cluster_name}"
  consul_cluster_size = "${var.consul_cluster_size}"

  allowed_inbound_cidr_blocks          = ["${var.public_cidrs}", "${var.db_cidrs}", "0.0.0.0/0"]
  allowed_inbound_security_group_ids   = ["${module.networking.db_sg}", "${module.networking.public_sg}"]
  allowed_inbound_security_group_count = "${var.allowed_inbound_security_group_count}"
  ssh_key_name                         = "${var.key_name}"
  subnet_ids                           = "${module.networking.vault_subnets}"
}

## Storage Resource --------------------------------------------------
module "storage" {
  source       = "../../modules/storage"
  project_name = "${var.project_name}"
}
