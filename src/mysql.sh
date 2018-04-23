#!/bin/bash

MySQL_Sec_Setting()
{
    DB_Root_Password="123456"

    if [ -d "/proc/vz" ];then
        ulimit -s unlimited
    fi

    StartUp mysql
    /etc/init.d/mysql start

    ln -sf /usr/local/mysql/bin/mysql /usr/bin/mysql
    ln -sf /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
    ln -sf /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
    ln -sf /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe
    ln -sf /usr/local/mysql/bin/mysqlcheck /usr/bin/mysqlcheck

    /usr/local/mysql/bin/mysqladmin -u root password "${DB_Root_Password}"
    if [ $? -ne 0 ]; then
        echo "failed, try other way..."
        cat >~/.emptymy.cnf<<EOF
[client]
user=root
password=''
EOF
        if echo "${mysql_version}" | grep -Eqi '^5.7.'; then
            /usr/local/mysql/bin/mysql --defaults-file=~/.emptymy.cnf -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${DB_Root_Password}');"
            [ $? -eq 0 ] && echo "Set password Sucessfully." || echo "Set password failed!"
        else
            /usr/local/mysql/bin/mysql --defaults-file=~/.emptymy.cnf -e "UPDATE mysql.user SET Password=PASSWORD('${DB_Root_Password}') WHERE User='root';"
            [ $? -eq 0 ] && echo "Set password Sucessfully." || echo "Set password failed!"
            /usr/local/mysql/bin/mysql --defaults-file=~/.emptymy.cnf -e "FLUSH PRIVILEGES;"
            [ $? -eq 0 ] && echo "FLUSH PRIVILEGES Sucessfully." || echo "FLUSH PRIVILEGES failed!"
        fi
        rm -f ~/.emptymy.cnf
    fi
    /etc/init.d/mysql restart

    Make_TempMycnf "${DB_Root_Password}"
    Do_Query ""
    if [ $? -eq 0 ]; then
        echo "OK, MySQL root password correct."
    fi

    echo "Update root password..."
    if echo "${mysql_version}" | grep -Eqi '^5.7.'; then
        Do_Query "UPDATE mysql.user SET authentication_string=PASSWORD('${DB_Root_Password}') WHERE User='root';"
    else
        Do_Query "UPDATE mysql.user SET Password=PASSWORD('${DB_Root_Password}') WHERE User='root';"
    fi
    [ $? -eq 0 ] && echo " ... Success." || echo " ... Failed!"

    echo "Remove anonymous users..."
    Do_Query "DELETE FROM mysql.user WHERE User='';"
    Do_Query "DROP USER ''@'%';"
    [ $? -eq 0 ] && echo " ... Success." || echo " ... Failed!"

    echo "Disallow root login remotely..."
    Do_Query "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    [ $? -eq 0 ] && echo " ... Success." || echo " ... Failed!"

    echo "Remove test database..."
    Do_Query "DROP DATABASE test;"
    [ $? -eq 0 ] && echo " ... Success." || echo " ... Failed!"

    echo "Reload privilege tables..."
    Do_Query "FLUSH PRIVILEGES;"
    [ $? -eq 0 ] && echo " ... Success." || echo " ... Failed!"

    /etc/init.d/mysql restart
    /etc/init.d/mysql stop
}

MySQL_Opt()
{
    MemTotal=`free -m | grep Mem | awk '{print  $2}'`

    if [[ ${MemTotal} -gt 1024 && ${MemTotal} -lt 2048 ]]; then
        sed -i "s#^key_buffer_size.*#key_buffer_size = 32M#" /etc/my.cnf
        sed -i "s#^table_open_cache.*#table_open_cache = 128#" /etc/my.cnf
        sed -i "s#^sort_buffer_size.*#sort_buffer_size = 768K#" /etc/my.cnf
        sed -i "s#^read_buffer_size.*#read_buffer_size = 768K#" /etc/my.cnf
        sed -i "s#^myisam_sort_buffer_size.*#myisam_sort_buffer_size = 8M#" /etc/my.cnf
        sed -i "s#^thread_cache_size.*#thread_cache_size = 16#" /etc/my.cnf
        sed -i "s#^query_cache_size.*#query_cache_size = 16M#" /etc/my.cnf
        sed -i "s#^tmp_table_size.*#tmp_table_size = 32M#" /etc/my.cnf
        sed -i "s#^innodb_buffer_pool_size.*#innodb_buffer_pool_size = 128M#" /etc/my.cnf
        sed -i "s#^innodb_log_file_size.*#innodb_log_file_size = 32M#" /etc/my.cnf
        sed -i "s#^performance_schema_max_table_instances.*#performance_schema_max_table_instances = 1000" /etc/my.cnf
    elif [[ ${MemTotal} -ge 2048 && ${MemTotal} -lt 4096 ]]; then
        sed -i "s#^key_buffer_size.*#key_buffer_size = 64M#" /etc/my.cnf
        sed -i "s#^table_open_cache.*#table_open_cache = 256#" /etc/my.cnf
        sed -i "s#^sort_buffer_size.*#sort_buffer_size = 1M#" /etc/my.cnf
        sed -i "s#^read_buffer_size.*#read_buffer_size = 1M#" /etc/my.cnf
        sed -i "s#^myisam_sort_buffer_size.*#myisam_sort_buffer_size = 16M#" /etc/my.cnf
        sed -i "s#^thread_cache_size.*#thread_cache_size = 32#" /etc/my.cnf
        sed -i "s#^query_cache_size.*#query_cache_size = 32M#" /etc/my.cnf
        sed -i "s#^tmp_table_size.*#tmp_table_size = 64M#" /etc/my.cnf
        sed -i "s#^innodb_buffer_pool_size.*#innodb_buffer_pool_size = 256M#" /etc/my.cnf
        sed -i "s#^innodb_log_file_size.*#innodb_log_file_size = 64M#" /etc/my.cnf
        sed -i "s#^performance_schema_max_table_instances.*#performance_schema_max_table_instances = 2000" /etc/my.cnf
    elif [[ ${MemTotal} -ge 4096 && ${MemTotal} -lt 8192 ]]; then
        sed -i "s#^key_buffer_size.*#key_buffer_size = 128M#" /etc/my.cnf
        sed -i "s#^table_open_cache.*#table_open_cache = 512#" /etc/my.cnf
        sed -i "s#^sort_buffer_size.*#sort_buffer_size = 2M#" /etc/my.cnf
        sed -i "s#^read_buffer_size.*#read_buffer_size = 2M#" /etc/my.cnf
        sed -i "s#^myisam_sort_buffer_size.*#myisam_sort_buffer_size = 32M#" /etc/my.cnf
        sed -i "s#^thread_cache_size.*#thread_cache_size = 64#" /etc/my.cnf
        sed -i "s#^query_cache_size.*#query_cache_size = 64M#" /etc/my.cnf
        sed -i "s#^tmp_table_size.*#tmp_table_size = 64M#" /etc/my.cnf
        sed -i "s#^innodb_buffer_pool_size.*#innodb_buffer_pool_size = 512M#" /etc/my.cnf
        sed -i "s#^innodb_log_file_size.*#innodb_log_file_size = 128M#" /etc/my.cnf
        sed -i "s#^performance_schema_max_table_instances.*#performance_schema_max_table_instances = 4000" /etc/my.cnf
    elif [[ ${MemTotal} -ge 8192 && ${MemTotal} -lt 16384 ]]; then
        sed -i "s#^key_buffer_size.*#key_buffer_size = 256M#" /etc/my.cnf
        sed -i "s#^table_open_cache.*#table_open_cache = 1024#" /etc/my.cnf
        sed -i "s#^sort_buffer_size.*#sort_buffer_size = 4M#" /etc/my.cnf
        sed -i "s#^read_buffer_size.*#read_buffer_size = 4M#" /etc/my.cnf
        sed -i "s#^myisam_sort_buffer_size.*#myisam_sort_buffer_size = 64M#" /etc/my.cnf
        sed -i "s#^thread_cache_size.*#thread_cache_size = 128#" /etc/my.cnf
        sed -i "s#^query_cache_size.*#query_cache_size = 128M#" /etc/my.cnf
        sed -i "s#^tmp_table_size.*#tmp_table_size = 128M#" /etc/my.cnf
        sed -i "s#^innodb_buffer_pool_size.*#innodb_buffer_pool_size = 1024M#" /etc/my.cnf
        sed -i "s#^innodb_log_file_size.*#innodb_log_file_size = 256M#" /etc/my.cnf
        sed -i "s#^performance_schema_max_table_instances.*#performance_schema_max_table_instances = 6000" /etc/my.cnf
    elif [[ ${MemTotal} -ge 16384 && ${MemTotal} -lt 32768 ]]; then
        sed -i "s#^key_buffer_size.*#key_buffer_size = 512M#" /etc/my.cnf
        sed -i "s#^table_open_cache.*#table_open_cache = 2048#" /etc/my.cnf
        sed -i "s#^sort_buffer_size.*#sort_buffer_size = 8M#" /etc/my.cnf
        sed -i "s#^read_buffer_size.*#read_buffer_size = 8M#" /etc/my.cnf
        sed -i "s#^myisam_sort_buffer_size.*#myisam_sort_buffer_size = 128M#" /etc/my.cnf
        sed -i "s#^thread_cache_size.*#thread_cache_size = 256#" /etc/my.cnf
        sed -i "s#^query_cache_size.*#query_cache_size = 256M#" /etc/my.cnf
        sed -i "s#^tmp_table_size.*#tmp_table_size = 256M#" /etc/my.cnf
        sed -i "s#^innodb_buffer_pool_size.*#innodb_buffer_pool_size = 2048M#" /etc/my.cnf
        sed -i "s#^innodb_log_file_size.*#innodb_log_file_size = 512M#" /etc/my.cnf
        sed -i "s#^performance_schema_max_table_instances.*#performance_schema_max_table_instances = 8000" /etc/my.cnf
    elif [[ ${MemTotal} -ge 32768 ]]; then
        sed -i "s#^key_buffer_size.*#key_buffer_size = 1024M#" /etc/my.cnf
        sed -i "s#^table_open_cache.*#table_open_cache = 4096#" /etc/my.cnf
        sed -i "s#^sort_buffer_size.*#sort_buffer_size = 16M#" /etc/my.cnf
        sed -i "s#^read_buffer_size.*#read_buffer_size = 16M#" /etc/my.cnf
        sed -i "s#^myisam_sort_buffer_size.*#myisam_sort_buffer_size = 256M#" /etc/my.cnf
        sed -i "s#^thread_cache_size.*#thread_cache_size = 512#" /etc/my.cnf
        sed -i "s#^query_cache_size.*#query_cache_size = 512M#" /etc/my.cnf
        sed -i "s#^tmp_table_size.*#tmp_table_size = 512M#" /etc/my.cnf
        sed -i "s#^innodb_buffer_pool_size.*#innodb_buffer_pool_size = 4096M#" /etc/my.cnf
        sed -i "s#^innodb_log_file_size.*#innodb_log_file_size = 1024M#" /etc/my.cnf
        sed -i "s#^performance_schema_max_table_instances.*#performance_schema_max_table_instances = 10000" /etc/my.cnf
    fi
}

Check_MySQL_Data_Dir()
{
    if [ -d "${MySQL_Data_Dir}" ]; then
        datetime=$(date +"%Y%m%d%H%M%S")
        mkdir -p /root/mysql-data-dir-backup${datetime}/
        \cp ${MySQL_Data_Dir}/* /root/mysql-data-dir-backup${datetime}/
        rm -rf ${MySQL_Data_Dir}/*
    else
        mkdir -p ${MySQL_Data_Dir}
    fi
}

Install_MySQL_56()
{
    Echo_Blue "[+] Installing ${Mysql_Ver}..."

    rm -f /etc/my.cnf
    Tar_Cd ${Mysql_Ver}.tar.gz ${Mysql_Ver}

    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1

    make && make install

    Echo_Blue "[+] Ending ${Mysql_Ver}..."

    #groupadd mysql
    #useradd -s /sbin/nologin -M -g mysql mysql

    #添加mysql用户和组
    add_usergroup_user mysql mysql

    cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = ${MySQL_Data_Dir}
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
query_cache_size = 8M
tmp_table_size = 16M
performance_schema_max_table_instances = 500

explicit_defaults_for_timestamp = true
#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
expire_logs_days = 10

#loose-innodb-trx=0
#loose-innodb-locks=0
#loose-innodb-lock-waits=0
#loose-innodb-cmp=0
#loose-innodb-cmp-per-index=0
#loose-innodb-cmp-per-index-reset=0
#loose-innodb-cmp-reset=0
#loose-innodb-cmpmem=0
#loose-innodb-cmpmem-reset=0
#loose-innodb-buffer-page=0
#loose-innodb-buffer-page-lru=0
#loose-innodb-buffer-pool-stats=0
#loose-innodb-metrics=0
#loose-innodb-ft-default-stopword=0
#loose-innodb-ft-inserted=0
#loose-innodb-ft-deleted=0
#loose-innodb-ft-being-deleted=0
#loose-innodb-ft-config=0
#loose-innodb-ft-index-cache=0
#loose-innodb-ft-index-table=0
#loose-innodb-sys-tables=0
#loose-innodb-sys-tablestats=0
#loose-innodb-sys-indexes=0
#loose-innodb-sys-columns=0
#loose-innodb-sys-fields=0
#loose-innodb-sys-foreign=0
#loose-innodb-sys-foreign-cols=0

default_storage_engine = InnoDB
#innodb_file_per_table = 1
#innodb_data_home_dir = ${MySQL_Data_Dir}
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = ${MySQL_Data_Dir}
#innodb_buffer_pool_size = 16M
#innodb_log_file_size = 5M
#innodb_log_buffer_size = 8M
#innodb_flush_log_at_trx_commit = 1
#innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
EOF

    InstallInnodb=y

    if [ "${InstallInnodb}" = "y" ]; then
        sed -i 's:^#innodb:innodb:g' /etc/my.cnf
    else
        sed -i '/^default_storage_engine/d' /etc/my.cnf
        sed -i '/skip-external-locking/i\innodb=OFF\nignore-builtin-innodb\nskip-innodb\ndefault_storage_engine = MyISAM\ndefault_tmp_storage_engine = MyISAM' /etc/my.cnf
        sed -i 's/^#loose-innodb/loose-innodb/g' /etc/my.cnf
    fi

    Echo_Yellow "[+] Setting Option..."
    MySQL_Opt

    Echo_Yellow "[+] Check_MySQL_Data_Dir..."
    Check_MySQL_Data_Dir

    chown -R mysql:mysql ${MySQL_Data_Dir}
    /usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=${MySQL_Data_Dir} --user=mysql
    chgrp -R mysql /usr/local/mysql/.

    #加入开机启动
    \cp support-files/mysql.server /etc/init.d/mysql
    chmod 755 /etc/init.d/mysql

    #加入动态动态链接库
    cat > /etc/ld.so.conf.d/mysql.conf<<EOF
    /usr/local/mysql/lib
    /usr/local/lib
EOF
    ldconfig

    ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
    ln -sf /usr/local/mysql/include/mysql /usr/include/mysql

    Echo_Yellow "[+] MySQL_Sec_Setting..."
    MySQL_Sec_Setting
}