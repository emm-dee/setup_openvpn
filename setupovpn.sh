#!/bin/bash

#pass in your domain name and hostname when executing
domain_name=${1}
domain_name=${2}

# Reserved for cloud-init Terraform deploy script template
sudo hostname ${hostname}.${domain_name}
sudo echo "127.0.1.1 ${hostname}.${domain_name}" >> /etc/hosts
sudo echo ${hostname}.${domain_name} > /etc/hostname

sudo ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
sudo dpkg-reconfigure -f noninteractive tzdata

## MANUAL build
###################
sudo apt-get update
sudo apt-get install -y openvpn easy-rsa openvpn-auth-ldap zip nagios-nrpe-server nagios-plugins
sudo mkdir /etc/openvpn/auth
sudo mkdir /etc/openvpn/easy-rsa/
sudo cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
sudo su -c "DEBIAN_FRONTEND=noninteractive apt-get upgrade -y"
sudo sed -i 's/\#net.ipv4.ip_forward\=1/net.ipv4.ip_forward\=1/g' /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
sudo groupadd vpnusers

### IPTABLES IS OPEN FOR BUILD STEPS
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A INPUT -p icmp -j ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -s 0.0.0.0/0 -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate NEW,ESTABLISHED,RELATED -p udp -s 0.0.0.0/0 --dport 43961 -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate NEW,ESTABLISHED,RELATED -p tcp -s 0.0.0.0/0 --dport 22 -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo su -c "DEBIAN_FRONTEND=noninteractive apt-get -yq install iptables-persistent"
sudo su -c "iptables-save > /etc/iptables/rules.v4"



sudo mkdir /etc/openvpn/tmp
sudo touch /etc/openvpn/server.conf
sudo chmod 777 /etc/openvpn/server.conf
sudo chmod 777 /etc/openvpn
sudo echo "port 43961" > /etc/openvpn/server.conf
sudo echo "proto udp" >> /etc/openvpn/server.conf
sudo echo "dev tun" >> /etc/openvpn/server.conf
sudo echo "ca ca.crt" >> /etc/openvpn/server.conf
sudo echo "cert nmavpnserver.crt" >> /etc/openvpn/server.conf
sudo echo "key nmavpnserver.key" >> /etc/openvpn/server.conf
sudo echo "dh dh4096.pem" >> /etc/openvpn/server.conf
sudo echo "topology subnet" >> /etc/openvpn/server.conf
sudo echo "server 10.10.199.0 255.255.255.0" >> /etc/openvpn/server.conf
sudo echo "ifconfig-pool-persist ipp.txt" >> /etc/openvpn/server.conf
sudo echo "push \"route 10.10.0.0 255.255.0.0\"" >> /etc/openvpn/server.conf
sudo echo "push \"dhcp-option  DOMAIN-SEARCH ${domain_name}\"" >> /etc/openvpn/server.conf
sudo echo "push \"dhcp-option DNS 10.10.21.254\"" >> /etc/openvpn/server.conf
sudo echo "push \"dhcp-option DNS 10.1.253.18\"" >> /etc/openvpn/server.conf
sudo echo "keepalive 10 120" >> /etc/openvpn/server.conf
sudo echo "tmp-dir \"/etc/openvpn/tmp/\"" >> /etc/openvpn/server.conf
sudo echo "plugin /etc/openvpn/openvpn-plugin-auth-pam.so /etc/pam.d/login" >> /etc/openvpn/server.conf
sudo echo "username-as-common-name" >> /etc/openvpn/server.conf
sudo echo "client-cert-not-required" >> /etc/openvpn/server.conf
sudo echo "comp-lzo" >> /etc/openvpn/server.conf
sudo echo "persist-key" >> /etc/openvpn/server.conf
sudo echo "persist-tun" >> /etc/openvpn/server.conf
sudo echo "status openvpn-status.log" >> /etc/openvpn/server.conf
sudo echo "verb 3" >> /etc/openvpn/server.conf
sudo echo "cipher AES-256-CBC" >> /etc/openvpn/server.conf
sudo chmod 755 /etc/openvpn
sudo chown root:root /etc/openvpn/server.conf
sudo chmod 755 /etc/openvpn/server.conf
sudo cp /usr/lib/openvpn/openvpn-plugin-auth-pam.so /etc/openvpn/
sudo chmod 766 /etc/openvpn/tmp
sudo mkdir -p /home/ubuntu/clientkeys/zipfiles/keys/

sudo sed -i 's/KEY\_COUNTRY.*/KEY\_COUNTRY\=\"US\"/' /etc/openvpn/easy-rsa/vars
sudo sed -i 's/KEY\_PROVINCE.*/KEY\_PROVINCE\=\"CA\"/' /etc/openvpn/easy-rsa/vars
sudo sed -i 's/KEY\_CITY.*/KEY\_CITY\=\"Somewhere\"/' /etc/openvpn/easy-rsa/vars
sudo sed -i 's/KEY\_ORG.*/KEY\_ORG\=\"Site\"/' /etc/openvpn/easy-rsa/vars
sudo sed -i 's/KEY\_EMAIL.*/KEY\_EMAIL\=\"noreply@example.com\"/' /etc/openvpn/easy-rsa/vars
sudo sed -i 's/KEY\_OU.*/KEY\_OU\=\"Dev\"/' /etc/openvpn/easy-rsa/vars
sudo sed -i 's/KEY\_NAME.*/KEY\_NAME\=\"vpnserver\"/' /etc/openvpn/easy-rsa/vars
sudo sed -i 's/KEY\_SIZE.*/KEY\_SIZE\=\"4096\"/' /etc/openvpn/easy-rsa/vars
sudo sed -i 's/pkitool\"\ \-\-interact/pkitool\"/' /etc/openvpn/easy-rsa/build-ca
sudo sed -i 's/pkitool\"\ \-\-interact/pkitool\"/' /etc/openvpn/easy-rsa/build-key-server

sudo su -c "cd /etc/openvpn/easy-rsa/ && source vars && ./clean-all && ./build-ca && ./build-key-server nmavpnserver && ./build-dh"
sudo cp -p /etc/openvpn/easy-rsa/keys/nmavpnserver.crt /etc/openvpn/
sudo cp -p /etc/openvpn/easy-rsa/keys/nmavpnserver.key /etc/openvpn/
sudo cp -p /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn/
sudo cp -p /etc/openvpn/easy-rsa/keys/dh4096.pem /etc/openvpn/

sudo shutdown -r now
#sudo su -c "cd /etc/openvpn/easy-rsa/ && source vars && ./build-key nmavpnclient"

