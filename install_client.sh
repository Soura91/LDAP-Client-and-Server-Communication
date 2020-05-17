#!/bin/bash

PASSWORD_SET="abcd123"
#updates the system repository database
sudo apt update

#change the fronend to noninteractive, avoiding prompts for automation
export DEBIAN_FRONTEND=noninteractive
echo "
ldap_auth_config        ldap_auth_config/bindpw password abcd123
ldap_auth_config        ldap_auth_config/rootbindpw password abcd123
ldap-auth-config        ldap-auth-config/dbrootlogin    boolean true
ldap-auth-config        ldap-auth-config/pam_password   select  md5
ldap-auth-config        ldap-auth-config/move-to-debconf        boolean true
ldap_auth_config        ldap_auth_config/ldapns/base-dn string  dc=clemson,dc=cloudlab,dc=us
ldap_auth_config        ldap_auth_config/rootbinddn     string  cn=admin,dc=clemson,dc=cloudlab,dc=us
ldap_auth_config        ldap_auth_config/ldapns/ldap-server     string  ldap://192.168.1.1
ldap_auth_config        ldap_auth_config/ldapns/ldap_version    select  3
ldap_auth_config        ldap_auth_config/dblogin        boolean false
ldap_auth_config        ldap_auth_config/override       boolean true " | sudo debconf-get-selections

#installs libnss-ldap libpam-ldap ldap-utils along with all their dependencies
sudo apt install -y -q libnss-ldap -y libpam-ldap ldap-utils

#changes to ldap.conf, ldap.secret, nsswitch.conf, common-session, common-password

sudo sed -i 's/uri ldapi:\/\/\//uri ldap:\/\/192.168.1.1\//g' /etc/ldap.conf
sudo sed -i 's/base dc=example,dc=net/base dc=clemson,dc=cloudlab,dc=us/g' /etc/ldap.conf
sudo sed -i 's/rootbinddn cn=manager,dc=example,dc=net/rootbinddn cn=admin,dc=clemson,dc=cloudlab,dc=us/g' /etc/ldap.conf
sudo sed -i '/passwd:/ s/$/ ldap/' /etc/nsswitch.conf
sudo sed -i '/group:/ s/$/ ldap/' /etc/nsswitch.conf
sudo sed -i '/# end of pam-auth-update config/ i session optional pam_mkhomedir.so  skel=/etc/skel  umsak=077' /etc/pam.d/common-session
sudo sed -i 's/use_authtok//g' /etc/pam.d/common-password
sudo bash <<EOF
echo $PASSWORD_SET > /etc/ldap.secret
EOF
sudo chmod 600 /etc/ldap.secret

