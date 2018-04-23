#!/bin/bash
#配置防火墙
Add_Iptables_Rules()
{
    #add iptables firewall rules
    if [ -s /sbin/iptables ]; then
        /sbin/iptables -I INPUT 1 -i lo -j ACCEPT
        /sbin/iptables -I INPUT 2 -m state --state ESTABLISHED,RELATED -j ACCEPT
        /sbin/iptables -I INPUT 3 -p tcp --dport 22 -j ACCEPT
        /sbin/iptables -I INPUT 4 -p tcp --dport 80 -j ACCEPT
        /sbin/iptables -I INPUT 5 -p tcp --dport 443 -j ACCEPT
        /sbin/iptables -I INPUT 6 -p tcp --dport 3306 -j DROP
        /sbin/iptables -I INPUT 7 -p icmp -m icmp --icmp-type 8 -j ACCEPT
        if [ "$PM" = "yum" ]; then
            service iptables save
            if [ -s /usr/sbin/firewalld ]; then
                systemctl stop firewalld
                systemctl disable firewalld
            fi
        elif [ "$PM" = "apt" ]; then
            iptables-save > /etc/iptables.rules
            cat >/etc/network/if-post-down.d/iptables<<EOF
#!/bin/bash
iptables-save > /etc/iptables.rules
EOF
            chmod +x /etc/network/if-post-down.d/iptables
            cat >/etc/network/if-pre-up.d/iptables<<EOF
#!/bin/bash
iptables-restore < /etc/iptables.rules
EOF
            chmod +x /etc/network/if-pre-up.d/iptables
        fi
    fi
}

Add_Startup()
{
    type=$1

    echo "Add Startup and Starting ${type}"

    if [ "${type}" = "mysql" ]; then
        StartUp mysql
        /etc/init.d/mysql start
    elif [ ${type} == 'nginx' ]; then
        StartUp nginx
        /etc/init.d/nginx start
    elif [ ${type} == 'php' ]; then
        StartUp php-fpm
        /etc/init.d/php-fpm start
    fi
}

#检测nginx安装是否成功
Check_Nginx_Files()
{
    isNginx=""
    echo "============================== Check install =============================="
    echo "Checking ..."
    if [[ -s /usr/local/nginx/conf/nginx.conf && -s /usr/local/nginx/sbin/nginx ]]; then
        Echo_Green "Nginx: OK"
        isNginx="ok"
    else
        Echo_Red "Error: Nginx install failed."
    fi
}

#检测mysql安装是否成功
Check_DB_Files()
{
    isDB=""

    if [[ -s /usr/local/mysql/bin/mysql && -s /usr/local/mysql/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        Echo_Green "MySQL: OK"
        isDB="ok"
    else
        Echo_Red "Error: MySQL install failed."
    fi
}

#检测php安装是否成功
Check_PHP_Files()
{
    isPHP=""
    if [ "${Stack}" = "lnmp" ]; then
        if [[ -s /usr/local/php/sbin/php-fpm && -s /usr/local/php/etc/php.ini && -s /usr/local/php/bin/php ]]; then
            Echo_Green "PHP: OK"
            Echo_Green "PHP-FPM: OK"
            isPHP="ok"
        else
            Echo_Red "Error: PHP install failed."
        fi
    else
        if [[ -s /usr/local/php/bin/php && -s /usr/local/php/etc/php.ini ]]; then
            Echo_Green "PHP: OK"
            isPHP="ok"
        else
            Echo_Red "Error: PHP install failed."
        fi
    fi
}

#删除软件包
Clean_Src_Dir()
{
    echo "Clean src directory..."

    rm -rf ${cur_dir}/soft/${Mysql_Ver}

    rm -rf ${cur_dir}/soft/${Php_Ver}

    rm -rf ${cur_dir}/soft/${Nginx_Ver}
}

Print_Sucess_Info()
{
    Clean_Src_Dir
    echo "+------------------------------------------------------------------------+"
    echo "|          LNMP V${LNMP_Ver} for ${DISTRO} Linux Server, Written by Licess          |"
    echo "+------------------------------------------------------------------------+"
    echo "|           For more information please visit https://lnmp.org           |"
    echo "+------------------------------------------------------------------------+"
    echo "|    lnmp status manage: lnmp {start|stop|reload|restart|kill|status}    |"
    echo "+------------------------------------------------------------------------+"
    echo "|  phpMyAdmin: http://IP/phpmyadmin/                                     |"
    echo "|  phpinfo: http://IP/phpinfo.php                                        |"
    echo "|  Prober:  http://IP/p.php                                              |"
    echo "+------------------------------------------------------------------------+"
    echo "|  Add VirtualHost: lnmp vhost add                                       |"
    echo "+------------------------------------------------------------------------+"
    echo "|  Default directory: ${Default_Website_Dir}                              |"
    if [ "${DBSelect}" != "0" ]; then
        echo "+------------------------------------------------------------------------+"
        echo "|  MySQL/MariaDB root password: ${DB_Root_Password}                          |"
    fi
    echo "+------------------------------------------------------------------------+"
    \cp ${cur_dir}/conf/lnmp /bin/lnmp
    chmod +x /bin/lnmp

    lnmp status
    if [ -s /bin/ss ]; then
        ss -ntl
    else
        netstat -ntl
    fi
    stop_time=$(date +%s)
    #echo "Install lnmp takes $(((stop_time-start_time)/60)) minutes."
    Echo_Green "Install lnmp V${LNMP_Ver} completed! enjoy it."
}

Print_Failed_Info()
{
    if [ -s /bin/lnmp ]; then
        rm -f /bin/lnmp
    fi
    Echo_Red "Sorry, Failed to install LNMP!"
}

#检测lnmp的安装
Check_LNMP_Install()
{
    Check_Nginx_Files
    Check_DB_Files
    Check_PHP_Files
    if [[ "${isNginx}" = "ok" && "${isDB}" = "ok" && "${isPHP}" = "ok" ]]; then
        Print_Sucess_Info
    fi
    #else
    #    Print_Failed_Info
    #fi
}


