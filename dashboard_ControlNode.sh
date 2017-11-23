#!/bin/bash

############## Networking service config on ControlNode #############

# Install and configure components

yum install -y openstack-dashboard

# 配置 /etc/openstack-dashboard/local_settings

cp /etc/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings.bk
cp ./local_settings /etc/openstack-dashboard/local_settings

# 重启httpd服务器和会话存储

systemctl restart httpd.service memcached.service
systemctl status httpd.service memcached.service
