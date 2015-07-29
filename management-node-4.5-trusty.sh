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

apt-get install -y pm-utils



#Mysql installation

sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password 2938fh4t3u4t4'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password 2938fh4t3u4t4'

apt-get install -y mysql-server

cat >>/etc/mysql/conf.d/cloudstack.cnf <<EOM
[mysqld]
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=600
max_connections=350
log-bin=mysql-bin
binlog-format = 'ROW'
EOM

service mysql restart



#Install Cloudstack Management

apt-get install -y cloudstack-management

wget http://download.cloud.com.s3.amazonaws.com/tools/vhd-util

cp ./vhd-util /usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver/vhd-util

cloudstack-setup-databases cloud:2938fh4t3u4t4@localhost --deploy-as=root:2938fh4t3u4t4 -e file -m 2938fh4t3u4t4 -k 2938fh4t3u4t4

cloudstack-setup-management


#Connect to Secondary to load templates

IP=storage.skilab.com
###############################################################setup NFS IP
cat >>/etc/fstab <<EOM
$IP:/nfs/SECONDARY /mnt/secondary  nfs rsize=8192,wsize=8192,timeo=14,intr,vers=3,noauto  0   2
EOM

mkdir -p /mnt/secondary
mount /mnt/secondary


#iptables

apt-get install -y iptables-persistent


#Image installs for Cloudstack

#FOR KVM
#/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://cloudstack.apt-get.eu/systemvm/4.5/systemvm64template-4.5-kvm.qcow2.bz2 -h kvm -s 2938fh4t3u4t4 -F
#FOR XEN
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://cloudstack.apt-get.eu/systemvm/4.5/systemvm64template-4.5-xen.vhd.bz2 -h xenserver -s 2938fh4t3u4t4 -F
#FOR VMWARE
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://cloudstack.apt-get.eu/systemvm/4.5/systemvm64template-4.5-vmware.ova -h vmware -s 2938fh4t3u4t4  -F
#FOR LXC
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://cloudstack.apt-get.eu/systemvm/4.5/systemvm64template-4.5-kvm.qcow2.bz2 -h lxc -s 2938fh4t3u4t4  -F

#Restart Cloudstack

service cloudstack-management stop
service cloudstack-management start

udpate-rc.d cloudstack-management defaults
