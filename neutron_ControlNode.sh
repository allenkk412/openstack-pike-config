#!/bin/bash

############## Networking service config on ControlNode #############
##############            Version： Ocata        #################

#### Prerequisites
# mysql -u root -p123
# CREATE DATABASE neutron;
# GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '123';
# GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '123';

. admin-openrc

openstack user create --domain default neutron --password 123
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "Openstack Networking Service" network

# 创建neutron的endpoint
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696

#### 配置网络选项2：Self-service networks
yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch ebtables

# 修改neutron的配置文件 /etc/neutron/neutron.conf
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bk

openstack-config --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:123@controller/neutron

openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips true
openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:123@controller
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password 123

# configure Networking to notify Compute of network topology changes:
# 配置当网络拓扑改变时，给nova发送通知
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes  true

openstack-config --set /etc/neutron/neutron.conf nova auth_url http://controller:35357
openstack-config --set /etc/neutron/neutron.conf nova auth_type password
openstack-config --set /etc/neutron/neutron.conf nova project_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova user_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova region_name RegionOne
openstack-config --set /etc/neutron/neutron.conf nova project_name service
openstack-config --set /etc/neutron/neutron.conf nova username nova
openstack-config --set /etc/neutron/neutron.conf nova password 123

openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

# 配置 /etc/neutron/plugins/ml2/ml2_conf.ini
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True

# 配置 /etc/neutron/plugins/ml2/openvswitch_agent.ini
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings 
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs tunnel_bridge br-tun
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip 10.0.0.11
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population true
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group true
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

# 配置 /etc/neutron/l3_agent.ini
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge br-ex
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver

# 配置 /etc/neutron/dhcp_agent.ini
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true

##### Configure the metadata agent 
# 配置 /etc/neutron/metadata_agent.ini
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip controller
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret 123

#### 配置nova使用neutron
# 配置 /etc/nova/nova.conf
openstack-config --set /etc/nova/nova.conf neutron url http://controller:9696
openstack-config --set /etc/nova/nova.conf neutron auth_url http://controller:35357
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password 123
openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy True
openstack-config --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret 123

# 创建符号链接，neutron初始化脚本期望一个
# 指向 ML2插件配置文件 /etc/neutron/plugins/ml2/ml2_conf.ini. 的符号链接 /etc/neutron/plugin.ini
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

# 同步数据库
 su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

# 重启nova-api
systemctl restart openstack-nova-api.service

# 启动neutron并设置开机启动
systemctl enable neutron-server.service \
  neutron-openvswitch-agent neutron-dhcp-agent.service \
  neutron-metadata-agent.service neutron-l3-agent.service

systemctl start neutron-server.service \
  neutron-openvswitch-agent neutron-dhcp-agent.service \
  neutron-metadata-agent.service neutron-l3-agent.service

systemctl status neutron-server.service \
  neutron-openvswitch-agent neutron-dhcp-agent.service \
  neutron-metadata-agent.service neutron-l3-agent.service

# 执行验证

. admin-openrc
openstack extension list --network
openstack network agent list

#neutron ext-list
#neutron agent-list