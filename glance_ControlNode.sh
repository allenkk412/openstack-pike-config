#!/bin/bash

############## Image service config on ControlNode #############
##############            Version： ocata         #################


#### Prerequisites

# mysql -u root -p 
# mysql> CREATE DATABASE glance;
# mysql> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '123';
# mysql> GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '123';

. admin-openrc
openstack user create --domain default glance --password 123
openstack role add --project service --user glance admin
openstack service create --name glance --description "Openstack Image" image

# 创建glance的endpoint
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

#### Install and configure components
yum install -y openstack-glance wget

# 修改glance配置文件 /etc/glance/glance-api.conf
cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.bk

openstack-config --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:123@controller/glance

openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_name service
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken password 123

openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone

openstack-config --set /etc/glance/glance-api.conf glance_store stores file,http
openstack-config --set /etc/glance/glance-api.conf glance_store default_store file
openstack-config --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

# 修改glance配置文件 /etc/glance/glance-registry.conf
cp /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.bk

openstack-config --set /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:123@controller/glance

openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_type password
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken password 123

openstack-config --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

# 同步glance数据库
su -s /bin/sh -c "glance-manage db_sync" glance

# 启动glance并设置开机启动
systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl restart openstack-glance-api.service openstack-glance-registry.service
systemctl status openstack-glance-api.service openstack-glance-registry.service

# 验证glance安装
. admin-openrc
wget https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img

openstack image create "cirros" --file cirros-0.3.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public

openstack image list 