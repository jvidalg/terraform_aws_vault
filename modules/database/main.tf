resource "aws_db_instance" "mariadb" {
  #count             = 2
  allocated_storage = 10                      # 10 GB of storage, gives us more IOPS than a lower number
  engine            = "mariadb"
  engine_version    = "10.1.14"
  instance_class    = "${var.instance_class}" # use micro if you want to use the free tier
  identifier        = "mariadb"
  name              = "mariadb"
  username          = "${var.rds_username}"   # username
  password          = "${var.rds_password}"   # password

  db_subnet_group_name    = "${aws_db_subnet_group.tf_db_sg.name}"
  parameter_group_name    = "${aws_db_parameter_group.tf_db_pg.name}"
  multi_az                = "false"                                   # set to true to have high availability: 2 instances synchronized with each other
  vpc_security_group_ids  = ["${var.security_group}"]
  storage_type            = "gp2"
  backup_retention_period = "${var.retention_period}"
  skip_final_snapshot     = true

  tags {
    Name = "mariadb-instance"
  }
}

resource "aws_db_instance" "mariadb_replica" {
  count             = "${var.enable_replica ? 1 : 0}"
  allocated_storage = 10                              # 10 GB of storage, gives us more IOPS than a lower number
  engine            = "mariadb"
  engine_version    = "10.1.14"
  instance_class    = "${var.instance_class}"
  identifier        = "mariadb-replica"
  name              = "mariadb-replica"
  username          = "${var.rds_username}"           # username
  password          = "${var.rds_password}"           # password

  #db_subnet_group_name    = "${aws_db_subnet_group.tf_db_sg.name}"
  parameter_group_name    = "${aws_db_parameter_group.tf_db_pg.name}"
  multi_az                = "false"                                   # set to true to have high availability: 2 instances synchronized with each other
  vpc_security_group_ids  = ["${var.security_group}"]
  storage_type            = "gp2"
  backup_retention_period = "${var.retention_period}"
  skip_final_snapshot     = true

  #availability_zone       = "${aws_subnet.main-private-1.availability_zone}" # prefered AZ

  replicate_source_db = "${aws_db_instance.mariadb.id}"
  tags {
    Name = "mariadb-instance"
  }
}

#----------------

resource "aws_db_parameter_group" "tf_db_pg" {
  name   = "mariadb-params"
  family = "mariadb10.1"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "max_allowed_packet"
    value = "16777216"
  }
}

resource "aws_db_subnet_group" "tf_db_sg" {
  name       = "db-subnet-group"
  subnet_ids = ["${var.db_subnets}"]

  tags {
    Name = "My DB subnet group"
  }
}
