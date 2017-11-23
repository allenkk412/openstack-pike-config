#!/bin/bash

# http://blog.csdn.net/linshenyuan1213/article/details/78131590
# https://docs.openstack.org/mistral/latest/configuration/index.html

# mysql -u root -p123 
# mysql> CREATE DATABASE mistral;
# mysql> GRANT ALL PRIVILEGES ON mistral.* TO  mistral'@'localhost' IDENTIFIED BY '123';
# mysql> GRANT ALL PRIVILEGES ON mistral.* TO  mistral'@'%' IDENTIFIED BY '123';

. admin-openrc
openstack user create --domain default mistral --password 123
openstack role add --project service --user mistral admin

# 创建mistral的endpoint
openstack service create --name mistral --description "mistral Project" workflowv2  

openstack endpoint create --region RegionOne workflowv2 public http://controller:8989/v2
openstack endpoint create --region RegionOne workflowv2 internal http://controller:8989/v2
openstack endpoint create --region RegionOne workflowv2 admin http://controller:8989/v2

# 通过 yum list|grep mistral 将所有的包安装
yum install -y python2-mistralclient openstack-mistral*  puppet-mistral* python2-mistral-lib*  python-mistral*