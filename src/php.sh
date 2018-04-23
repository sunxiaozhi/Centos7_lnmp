#!/bin/bash

Ln_PHP_Bin()
{
    ln -sf /usr/local/php/bin/php /usr/bin/php
    ln -sf /usr/local/php/bin/phpize /usr/bin/phpize
    ln -sf /usr/local/php/bin/pear /usr/bin/pear
    ln -sf /usr/local/php/bin/pecl /usr/bin/pecl
    ln -sf /usr/local/php/sbin/php-fpm /usr/bin/php-fpm

    rm -f /usr/local/php/conf.d/*
}

Pear_Pecl_Set()
{
    pear config-set php_ini /usr/local/php/etc/php.ini
    pecl config-set php_ini /usr/local/php/etc/php.ini
}

#安装composer
Install_Composer()
{
    curl -sS --connect-timeout 30 -m 60 https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    if [ $? -eq 0 ]; then
        echo "Composer install successfully."
    else
        if [ -s /usr/local/php/bin/php ]; then
            wget --prefer-family=IPv4 --no-check-certificate -T 120 -t3 ${Download_Mirror}/web/php/composer/composer.phar -O /usr/local/bin/composer
            if [ $? -eq 0 ]; then
                echo "Composer install successfully."
            else
                echo "Composer install failed!"
            fi
            chmod +x /usr/local/bin/composer
        fi
    fi
}

#检测curl是否安装
Check_Curl()
{
    if [ -s /usr/local/curl/bin/curl ]; then
        Echo_Green "Curl ...ok"
    else
        Install_Curl
    fi
}

#安装php7
Install_PHP_7()
{
    Echo_Blue "[+] Installing ${Php_Ver}"

    add_usergroup_user www www

    PHP_with_curl

    Tar_Cd ${Php_Ver}.tar.gz ${Php_Ver}

    ./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --with-config-file-scan-dir=/usr/local/php/conf.d --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --with-xsl --enable-opcache ${with_curl} ${PHP_Modules_Options}

    #可能是因为机器没有安装libiconv之类的库，怕编译出错，所以不为php加入iconv模块吧。
    Echo_Yellow "php make start"
    make ZEND_EXTRA_LIBS='-liconv'
    Echo_Yellow "php make end"

    Echo_Yellow "php make install start"
    make install
    Echo_Yellow "php make install end"

    Ln_PHP_Bin

    echo "Copy new php configure file..."
    mkdir -p /usr/local/php/{etc,conf.d}
    \cp php.ini-production /usr/local/php/etc/php.ini

    cd ${cur_dir}
    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' /usr/local/php/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' /usr/local/php/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' /usr/local/php/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' /usr/local/php/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' /usr/local/php/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' /usr/local/php/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' /usr/local/php/etc/php.ini

    Pear_Pecl_Set
    Install_Composer

    echo "Install ZendGuardLoader for PHP 7.0..."
    echo "unavailable now."

    echo "Write ZendGuardLoader to php.ini..."
    cat >/usr/local/php/conf.d/002-zendguardloader.ini<<EOF
[Zend ZendGuard Loader]
;php7 do not support zendguardloader,after support you can uncomment the following line.
;zend_extension=/usr/local/zend/ZendGuardLoader.so
;zend_loader.enable=1
;zend_loader.disable_licensing=0
;zend_loader.obfuscation_level_support=3
;zend_loader.license_path=
EOF

    echo "Creating new php-fpm configure file..."
    cat >/usr/local/php/etc/php-fpm.conf<<EOF
[global]
pid = /usr/local/php/var/run/php-fpm.pid
error_log = /usr/local/php/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF

    echo "Copy php-fpm init.d file..."
    \cp ${cur_dir}/soft/${Php_Ver}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
    chmod +x /etc/init.d/php-fpm
}

#优化配置php-fpm配置文件参数
LNMP_PHP_Opt()
{
    MemTotal=`free -m | grep Mem | awk '{print  $2}'`

    if [[ ${MemTotal} -gt 1024 && ${MemTotal} -le 2048 ]]; then
        sed -i "s#pm.max_children.*#pm.max_children = 20#" /usr/local/php/etc/php-fpm.conf
        sed -i "s#pm.start_servers.*#pm.start_servers = 10#" /usr/local/php/etc/php-fpm.conf
        sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 10#" /usr/local/php/etc/php-fpm.conf
        sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 20#" /usr/local/php/etc/php-fpm.conf
    elif [[ ${MemTotal} -gt 2048 && ${MemTotal} -le 4096 ]]; then
        sed -i "s#pm.max_children.*#pm.max_children = 40#" /usr/local/php/etc/php-fpm.conf
        sed -i "s#pm.start_servers.*#pm.start_servers = 20#" /usr/local/php/etc/php-fpm.conf
        sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 20#" /usr/local/php/etc/php-fpm.conf
        sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 40#" /usr/local/php/etc/php-fpm.conf
    elif [[ ${MemTotal} -gt 4096 && ${MemTotal} -le 8192 ]]; then
        sed -i "s#pm.max_children.*#pm.max_children = 60#" /usr/local/php/etc/php-fpm.conf
        sed -i "s#pm.start_servers.*#pm.start_servers = 30#" /usr/local/php/etc/php-fpm.conf
        sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 30#" /usr/local/php/etc/php-fpm.conf
        sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 60#" /usr/local/php/etc/php-fpm.conf
    elif [[ ${MemTotal} -gt 8192 ]]; then
        sed -i "s#pm.max_children.*#pm.max_children = 80#" /usr/local/php/etc/php-fpm.conf
        sed -i "s#pm.start_servers.*#pm.start_servers = 40#" /usr/local/php/etc/php-fpm.conf
        sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 40#" /usr/local/php/etc/php-fpm.conf
        sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 80#" /usr/local/php/etc/php-fpm.conf
    fi
}

Creat_PHP_Tools()
{
    echo "Create PHP Info Tool..."
    cat >${Default_Website_Dir}/phpinfo.php<<EOF
<?php
phpinfo();
?>
EOF

    echo "Copy PHP Prober..."
    cd ${cur_dir}/soft
    tar zxf p.tar.gz
    \cp p.php ${Default_Website_Dir}/p.php

    \cp ${cur_dir}/conf/index.html ${Default_Website_Dir}/index.html
    #\cp ${cur_dir}/conf/lnmp.gif ${Default_Website_Dir}/lnmp.gif

    #if [ ${PHPSelect} -ge 4 ]; then
        #echo "Copy Opcache Control Panel..."
        #\cp ${cur_dir}/conf/ocp.php ${Default_Website_Dir}/ocp.php
    #fi
    echo "============================Install PHPMyAdmin================================="
    [[ -d ${Default_Website_Dir}/phpmyadmin ]] && rm -rf ${Default_Website_Dir}/phpmyadmin
    tar Jxf ${PhpMyAdmin_Ver}.tar.xz
    mv ${PhpMyAdmin_Ver} ${Default_Website_Dir}/phpmyadmin
    \cp ${cur_dir}/conf/config.inc.php ${Default_Website_Dir}/phpmyadmin/config.inc.php
    sed -i 's/LNMPORG/LNMP.org_0'$RANDOM`date '+%s'`$RANDOM'9_VPSer.net/g' ${Default_Website_Dir}/phpmyadmin/config.inc.php
    mkdir ${Default_Website_Dir}/phpmyadmin/{upload,save}
    chmod 755 -R ${Default_Website_Dir}/phpmyadmin/
    chown www:www -R ${Default_Website_Dir}/phpmyadmin/
    echo "============================phpMyAdmin install completed======================="
}

PHP_with_curl()
{
    Get_ARM
    DISTRO='CentOS'

    if [[ "${DISTRO}" = "CentOS" && "${Is_ARM}" = "y" ]];then
        with_curl='--with-curl=/usr/local/curl'
    else
        with_curl='--with-curl'
    fi
}

PHP_with_openssl()
{
    if /usr/bin/openssl version | grep -Eqi "OpenSSL 1.1.*"; then
        if ( [ "${PHPSelect}" != "" ] &&  echo "${PHPSelect}" | grep -vEqi "6|7" ) || ( [ "${php_version}" != "" ] && echo "${php_version}" | grep -vEqi '^7.' ); then
            Install_Openssl
            with_openssl='--with-openssl=/usr/local/openssl'
        else
            with_openssl='--with-openssl'
        fi
    else
        with_openssl='--with-openssl'
    fi
}