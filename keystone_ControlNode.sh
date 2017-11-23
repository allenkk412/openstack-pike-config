##############            Version Ocata         #################

#mysql -u root -p
#
#CREATE DATABASE keystone;
#
#GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
#  IDENTIFIED BY 'KEYSTONE_DBPASS';
#GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
#  IDENTIFIED BY 'KEYSTONE_DBPASS';

yum install -y openstack-keystone httpd mod_wsgi openstack-utils
cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bk

openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:123@controller/keystone
openstack-config --set /etc/keystone/keystone.conf token provider fernet
su -s /bin/sh -c "keystone-manage db_sync" keystone

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password 123 \
  --bootstrap-admin-url http://controller:35357/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

sed -i "s/#ServerName www.example.com:80/ServerName controller/" /etc/httpd/conf/httpd.conf
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

systemctl enable httpd.service
systemctl start httpd.service
systemctl status httpd.service


export OS_USERNAME=admin
export OS_PASSWORD=123
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3


# 创建域、项目、用户和角色

openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password 123 demo
openstack role create user
openstack role add --project demo --user demo user



#Edit the /etc/keystone/keystone-paste.ini file and remove admin_token_auth from the [pipeline:public_api], 
#[pipeline:admin_api], and [pipeline:api_v3] sections.

unset OS_AUTH_URL OS_PASSWORD

openstack --os-auth-url http://controller:35357/v3 \
  --os-project-domain-name default \
  --os-user-domain-name default \
  --os-project-name admin \
  --os-username admin token issue \
  --os-password 123
  
  openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name default \
  --os-user-domain-name default \
  --os-project-name demo \
  --os-username demo token issue \
  --os-password 123
 
 
# vi admin-openrc 
 
#export OS_PROJECT_DOMAIN_NAME=Default
#export OS_USER_DOMAIN_NAME=Default
#export OS_PROJECT_NAME=admin
#export OS_USERNAME=admin
#export OS_PASSWORD=123
#export OS_AUTH_URL=http://controller:35357/v3
#export OS_IDENTITY_API_VERSION=3
#export OS_IMAGE_API_VERSION=2

# vi demo-openrc
# export OS_PROJECT_DOMAIN_NAME=Default
# export OS_USER_DOMAIN_NAME=Default
# export OS_PROJECT_NAME=demo
# export OS_USERNAME=demo
# export OS_PASSWORD=123
# export OS_AUTH_URL=http://controller:5000/v3
# export OS_IDENTITY_API_VERSION=3
# export OS_IMAGE_API_VERSION=2