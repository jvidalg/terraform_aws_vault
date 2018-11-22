#-----compute/outputs.tf

#output "server_id" {
#  value = "${join(", ", aws_instance.tf_server.*.id)}"
#}

#output "server_ip" {
#  value = "${join(", ", aws_instance.tf_server.*.public_ip)}"
#}

#output "web_instances" {
#  value = "${aws_instance.tf_server.*.id}"
#}

output "lb_url" {
  value = "${element(concat(aws_elb.tf_elb.*.dns_name, list("")), 0)}"
}
