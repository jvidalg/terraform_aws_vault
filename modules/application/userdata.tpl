#!/bin/bash
yum install httpd -y
echo "Hostname: $(hostname)" >> /var/www/html/index.html
echo "IP: $(hostname -i)" >> /var/www/html/index.html
echo "Subnet for Firewall: ${firewall_subnets}" >> /var/www/html/index.html
service httpd start
chkconfig httpd on