#!/bin/bash

# http://blog.csdn.net/linshenyuan1213/article/details/78120623

# mysql -u root -p123 
# mysql> CREATE DATABASE tacker;
# mysql> GRANT ALL PRIVILEGES ON tacker.* TO  tacker'@'localhost' IDENTIFIED BY '123';
# mysql> GRANT ALL PRIVILEGES ON tacker.* TO  tacker'@'%' IDENTIFIED BY '123';

. admin-openrc
openstack user create --domain default tacker --password 123
openstack role add --project service --user tacker admin

openstack service create --name tacker --description "Tacker Project" nfv-orchestration
           
openstack endpoint create --region RegionOne nfv-orchestration public http://controller:9890/
openstack endpoint create --region RegionOne nfv-orchestration internal http://controller:9890/
openstack endpoint create --region RegionOne nfv-orchestration admin http://controller:9890/

yum install -y openstack-tacker openstack-tacker-common puppet-tacker python-tacker python2-tackerclient