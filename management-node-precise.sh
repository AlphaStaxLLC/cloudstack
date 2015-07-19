cat >/etc/apt/sources.list.d/cloudstack.list <<EOM
deb http://cloudstack.apt-get.eu/ubuntu precise 4.2
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


#Create local NFS share

mkdir -p /export/primary /export/secondary
apt-get install -y nfs-kernel-server

IP=192.168.100.201
###############################################################setup NFS IP
cat >>/etc/fstab <<EOM
$IP:/export/primary   /mnt/primary    nfs rsize=8192,wsize=8192,timeo=14,intr,vers=3,noauto  0   2
$IP:/export/secondary /mnt/secondary  nfs rsize=8192,wsize=8192,timeo=14,intr,vers=3,noauto  0   2
EOM

cat >>/etc/exports <<EOM
/export/primary		$IP(rw,sync,no_root_squash,subtree_check)
/export/secondary 	$IP(rw,sync,no_root_squash,subtree_check)
EOM

exportfs -a

mkdir -p /mnt/primary /mnt/secondary
mount /mnt/primary
mount /mnt/secondary      


#iptables

apt-get install -y iptables-persistent


#Image installs for Cloudstack

#FOR KVM
#/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://download.cloud.com/templates/acton/acton-systemvm-02062012.qcow2.bz2 -h kvm -s 2938fh4t3u4t4 -F
#FOR XEN
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://d21ifhcun6b1t2.cloudfront.net/templates/4.2/systemvmtemplate-2013-07-12-master-xen.vhd.bz2 -h xenserver -s 2938fh4t3u4t4 -F
#FOR VMWARE
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://download.cloud.com/templates/burbank/burbank-systemvm-08012012.ova -h vmware -s 2938fh4t3u4t4  -F


#Restart Cloudstack

service cloudstack-management stop
service cloudstack-management start