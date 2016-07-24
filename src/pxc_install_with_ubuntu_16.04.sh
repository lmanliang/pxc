#!/bin/bash
# Program:
#       Insert Percona Cluster Database with Ubuntu 16.04
#		在 Ubuntu 最小化安裝後，執行
#
# LICENSE: MIT
# History:
# 2016/08/25	Lman<lman@brain-c.com>	First release

# 数据库密码
dbpw=qwer
# 节点名称 ; percona1 or percona2
nodename=percona1

invoke-rc.d apparmor stop
update-rc.d -f apparmor remove

echo -e "10.0.0.41 percona1\n10.0.0.42 percona2" >> /etc/hosts
apt install sshguard
apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
echo -e "deb http://repo.percona.com/apt xenial main\ndeb-src http://repo.percona.com/apt xenial main\n" >> /etc/apt/sources.list
sleep 3
apt update
sleep 3
apt upgrade
sleep 3
export DEBIAN_FRONTEND=noninteractive
apt -y install percona-xtradb-cluster-56
mysqladmin -u root password $dbpw
mysql -u root -pqwer  -e "CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"
mysql -u root -pqwer  -e "CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"
mysql -u root -pqwer  -e "CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"
mysql -u root -pqwer  -e "CREATE USER 'sstuser'@'localhost' IDENTIFIED BY 's3cretPass'"
mysql -u root -pqwer  -e "GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'sstuser'@'localhost';"
mysql -u root -pqwer  -e "FLUSH PRIVILEGES;"

if [ $nodename == 'percona1' ] ; then 
	echo -e '[mysqld]\ndatadir=/var/lib/mysql\nuser=mysql\nwsrep_provider=/usr/lib/libgalera_smm.so\nwsrep_cluster_address=gcomm://percona1,percona2\nbinlog_format=ROW\ndefault_storage_engine=InnoDB\ninnodb_autoinc_lock_mode=2\nwsrep_node_address=precona1\nwsrep_sst_method=xtrabackup-v2\nwsrep_cluster_name=my_ubuntu_cluster\nwsrep_sst_auth="sstuser:s3cretPass"\n' > /etc/mysql/conf.d/mysqld.cnf
	service mysql stop
	/etc/init.d/mysql bootstrap-pxc
else 
    echo -e "[mysqld]\ndatadir=/var/lib/mysql\nuser=mysql\nwsrep_provider=/usr/lib/libgalera_smm.so\nwsrep_cluster_address=gcomm://percona1,percona2\nbinlog_format=ROW\ndefault_storage_engine=InnoDB\ninnodb_autoinc_lock_mode=2\nwsrep_node_address=$nodename\nwsrep_cluster_name=my_ubuntu_cluster\nwsrep_sst_method=xtrabackup-v2\nwsrep_sst_auth=\"sstuser:s3cretPass\"\n"  > /etc/mysql/conf.d/mysqld.cnf
    /etc/init.d/mysql start
fi


#show status like 'wsrep%';