#!/bin/bash
# Program:
#       Insert Percona Cluster Database with Centos 7
#		在CentOS 最小化安裝後，執行
# LICENSE: MIT
# History:
# 2016/08/25	Lman<lman@brain-c.com>	First release

# 数据库密码
export dbpw=qwer
# 节点名称 ; percona1 or percona2
export nodename=percona1
echo -e "10.0.0.41 percona1\n10.0.0.42 percona2" >> /etc/hosts

yum -y update
yum -y install epel-release
yum -y install socat
yum -y remove mariadb-libs
yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm
yum -y install Percona-XtraDB-Cluster-server-56 Percona-XtraDB-Cluster-client-56 Percona-XtraDB-Cluster-shared-56 percona-toolkit percona-xtrabackup Percona-XtraDB-Cluster-galera-3 rsync nc
systemctl start mysql
mysql -u root -e "create user sstuser@'%' identified by 'mypass@'"
CREATE USER 'sstuser'@'localhost' IDENTIFIED BY 's3cret';
mysql -u root -e "grant all on *.* to sstuser@'%' identified by 'mypass@'"
mysql -u root -e "flush privileges"
mysql -u root -e "use mysql ;delete from user where user=''"
mysqladmin -u root password $dbpw

sed -i "s/wsrep_.*$//g" /etc/my.cnf
if [ $nodename == 'percona1' ] ; then 
	sed -i "s/log_bin/log_bin\nwsrep_cluster_address\t = gcomm:\/\/\nwsrep_provider\t = \/usr\/lib64\/galera3\/libgalera_smm.so\nwsrep_slave_threads\t = 8\nwsrep_cluster_name\t = Cluster Percona XtraDB\nwsrep_node_name\t = percona1\nwsrep_node_address\t = percona1\nwsrep_sst_method\t = xtrabackup-v2\nwsrep_sst_auth\t = sstuser:mypass@\ndefault_storage_engine=InnoDB\ninnodb_autoinc_lock_mode=2/" /etc/my.cnf
	systemctl stop mysql
	systemctl start mysql@bootstrap
else
	sed -i "s/log_bin/log_bin\nwsrep_cluster_address\t = gcomm:\/\/percona1,percona2\nwsrep_provider\t = \/usr\/lib64\/galera3\/libgalera_smm.so\nwsrep_slave_threads\t = 8\nwsrep_cluster_name\t = Cluster Percona XtraDB\nwsrep_node_name\t = percona2\nwsrep_node_address\t = percona2\nwsrep_sst_method\t = xtrabackup-v2\nwsrep_sst_auth\t = sstuser:mypass@\ndefault_storage_engine=InnoDB\ninnodb_autoinc_lock_mode=2/" /etc/my.cnf
	#systemctl stop mysql
	#systemctl start mysql
fi
#show status like 'wsrep%';