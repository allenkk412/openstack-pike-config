#!/bin/bash

############## Compute service config on ComputeNode #############
##############            Version Ocata         #################

#### Install and configure components
yum install -y openstack-nova-compute openstack-utils openstack-selinux python-openstackclient

# 修改nova的配置文件 /etc/nova/nova.conf
cp /etc/nova/nova.conf /etc/nova/nova.conf.bk

openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
openstack-config --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:123@controller
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip 10.0.0.31
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

openstack-config --set /etc/nova/nova.conf api auth_strategy keystone

openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password 123

openstack-config --set /etc/nova/nova.conf vnc enabled True
openstack-config --set /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0
openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address 10.0.0.31
openstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://controller:6080/vnc_auto.html

openstack-config --set /etc/nova/nova.conf glance api_servers http://controller:9292

openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

openstack-config --set /etc/nova/nova.conf placement os_region_name RegionOne
openstack-config --set /etc/nova/nova.conf placement project_domain_name Default
openstack-config --set /etc/nova/nova.conf placement project_name service
openstack-config --set /etc/nova/nova.conf placement auth_type password
openstack-config --set /etc/nova/nova.conf placement user_domain_name Default
openstack-config --set /etc/nova/nova.conf placement auth_url http://controller:35357/v3
openstack-config --set /etc/nova/nova.conf placement username placement
openstack-config --set /etc/nova/nova.conf placement password 123

# 启动nova及其依赖项，并设置开机启动
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service
systemctl status libvirtd.service openstack-nova-compute.service

# 验证nova的安装
. admin-openrc
openstack compute service list