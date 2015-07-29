#!/bin/bash

cat >/etc/apt/sources.list.d/cloudstack.list <<EOM
deb http://cloudstack.apt-get.eu/ubuntu trusty 4.5
EOM
wget -O - http://cloudstack.apt-get.eu/release.asc|apt-key add -

apt-get update



#NTP Configuration

apt-get install -y ntp

cat >/etc/ntp.conf <<EOM
server us.pool.ntp.org
EOM

service ntp restart


#Install Cloudstack Agent
apt-get install lxc cloudstack-agent -y


#Set Agent Configuration
sed -i "s/hypervisor.type=.*/hypervisor.type=lxc/g" /etc/cloudstack/agent/agent.properties

#Configure libvirt
sed -i "s/#listen_tls.*/listen_tls = 0/g" /etc/libvirt/libvirtd.conf
sed -i "s/#listen_tcp.*/listen_tcp = 1/g" /etc/libvirt/libvirtd.conf
sed -i "s/#tcp_port.*/tcp_port = \"16509\"/g" /etc/libvirt/libvirtd.conf
sed -i "s/#auth_tcp.*/auth_tcp = \"none\"/g" /etc/libvirt/libvirtd.conf
sed -i "s/#mdns_adv.*/mdns_adv = 0/g" /etc/libvirt/libvirtd.conf

sed -i "s/libvirtd_opts.*/libvirtd_opts=\"-d -l\"/g" /etc/default/libvirt-bin

#Configure VNC
sed -i "s/#vnc_listen.*/vnc_listen = "0.0.0.0"/g" /etc/libvirt/qemu.conf

service libvirt-bin restart

#Configure Apparmor
ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper /etc/apparmor.d/disable/
apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd
apparmor_parser -R /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper