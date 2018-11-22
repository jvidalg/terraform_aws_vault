aws_region = "us-west-2"
project_name = "tf-storage"
vpc_cidr = "10.123.0.0/16"
public_cidrs = [
    "10.123.1.0/24",
    "10.123.2.0/24"
    ]
accessip = "0.0.0.0/0"
db_cidrs = [
    "10.123.3.0/24",
    "10.123.4.0/24"
    ]
vault_cidrs = [
    "10.123.5.0/24",
    "10.123.6.0/24"
    ]
#-----Application----

key_name = "pub_key"
public_key_path = "/Users/jesusgomez/keys/terraform/tf_key.pub"
server_instance_type = "t2.micro"

#-----RDS-------

rds_instance_class = "db.t2.small"
rds_backup_period = "30"
rds_username = "root"
rds_password = "administrator_password"
enable_replica = true

#-----Vault-----

vault_cluster_size = 2
vault_cluster_name = "vault_cluster_demo"
vault_instance_type = "t2.micro"
vault_consul_ami = "ami-05f9731a852c60873"
allowed_inbound_security_group_count = 2

user_data = ""
