data "aws_availability_zones" "available" {}

data "aws_ami" "server_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*-x86_64-gp2"]
  }
}

resource "aws_key_pair" "tf_auth" {
  key_name   = "${var.key_name}"
  #public_key = "${file(var.public_key_path)}"
  public_key = "${var.public_key_path}"

}

data "template_file" "user-init" {
  #count    = 2
  template = "${file("${path.module}/userdata.tpl")}"

  vars {

    #firewall_subnets = "${element(var.subnet_ips, count.index)}"
    #subnets = "${var.subnet_ips}"
    subnets = "${join(", ", var.subnet_ips)}"
    vault_ips = "${join(", ", var.vault_ips)}"
    db_subnets = "${join(", ", var.db_subnets)}"
    vault_subnets = "${join(", ", var.vault_subnets)}"

  }
}

#resource "aws_instance" "tf_server" {
#  count         = "${var.instance_count}"
#  instance_type = "${var.instance_type}"
#  ami           = "${data.aws_ami.server_ami.id}"

#  tags {
#    Name = "tf_server-${count.index +1}"
#  }

#  key_name               = "${aws_key_pair.tf_auth.id}"
#  vpc_security_group_ids = ["${var.security_group}"]
#  subnet_id              = "${element(var.subnets, count.index)}"
#  user_data              = "${data.template_file.user-init.*.rendered[count.index]}"
#}

#-------------------------------LC & ASG

resource "aws_launch_configuration" "tf_alc" {
  image_id        = "${data.aws_ami.server_ami.id}"
  instance_type   = "${var.instance_type}"
  security_groups = ["${var.security_group}"]
  key_name        = "${aws_key_pair.tf_auth.id}"
  user_data       = "${data.template_file.user-init.rendered}"
  #user_data       = "${data.template_file.user-init.*.rendered[count.index]}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "tf_asg" {
  launch_configuration = "${aws_launch_configuration.tf_alc.id}"
  vpc_zone_identifier  = ["${var.subnets}"]

  min_size          = 2
  max_size          = 10
  load_balancers    = ["${aws_elb.tf_elb.name}"]
  health_check_type = "ELB"
  tag {
    key                 = "Name"
    value               = "tf_asg"
    propagate_at_launch = true
  }
}

#-------------------------- ELB

resource "aws_elb" "tf_elb" {
  name            = "terraform-tf-elb"
  security_groups = ["${var.elb_sg}"]
  subnets         = ["${var.subnets}"]

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "TCP"
      lb_port           = "80"
      lb_protocol       = "TCP"
    },
    {
      instance_port     = "80"
      instance_protocol = "TCP"
      lb_port           = "80"
      lb_protocol       = "TCP"
    },
  ]

  health_check = [
    {
      target              = "HTTP:80/"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]

  cross_zone_load_balancing   = false
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "terraform - elb"
  }
}

#---------------------------- Cloud Watch

resource "aws_autoscaling_policy" "tf_asp" {
  name                   = "terraform-tf-asp"
  scaling_adjustment     = 4
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.tf_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "tf_cwma" {
  alarm_name          = "terraform-tf-cwma"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.tf_asg.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.tf_asp.arn}"]
}
