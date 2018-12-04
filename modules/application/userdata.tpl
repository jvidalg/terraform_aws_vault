#!/bin/bash
yum install httpd -y
echo -e "Hostname: $(hostname)
<br>
IP: $(hostname -i)
<br>
Public Subnets : ${subnets}
<br>
Vault Subnets : ${vault_ips}
<br>
DB Subnets IDs : ${db_subnets}
<br>
Vault Subnet IDs : ${vault_subnets}
<br>"  >> /var/www/html/index.html
echo -e '<img src="https://github.com/jvidalg/terraform_aws_vault/blob/assets/terraform_demo.001.png" alt="Architecture"/>' >> /var/www/html/index.html

service httpd start
chkconfig httpd on
