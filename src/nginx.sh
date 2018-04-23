#!/bin/bash
Install_Nginx_Openssl()
{
    if [ "${Enable_Nginx_Openssl}" = 'y' ]; then
        #Download_Files ${Download_Mirror}/lib/openssl/${Openssl_Ver}.tar.gz ${Openssl_Ver}.tar.gz
        Download_Files http://distfiles.macports.org/openssl/openssl-1.0.2l.tar.gz ${Openssl_Ver}.tar.gz
        [[ -d "${Openssl_Ver}" ]] && rm -rf ${Openssl_Ver}
        tar zxf ${Openssl_Ver}.tar.gz
        Nginx_With_Openssl="--with-openssl=${cur_dir}/soft/${Openssl_Ver}"
    fi
}

#安装nginx
function Install_Nginx()
{
    echo "+------------------------------------------------------------------------+"
    echo "|                  Begin the installation for the nginx                  |"
    echo "+------------------------------------------------------------------------+"

    Echo_Blue "[+] Installing ${Nginx_Ver}... "

    add_usergroup_user www www

    cd ${cur_dir}/soft
    Install_Nginx_Openssl

    Tar_Cd ${Nginx_Ver}.tar.gz ${Nginx_Ver}
    if echo ${Nginx_Ver} | grep -Eqi 'nginx-[0-1].[5-8].[0-9]' || echo ${Nginx_Ver} | grep -Eqi 'nginx-1.9.[1-4]$'; then
        ./configure --user=www --group=www --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_spdy_module --with-http_gzip_static_module --with-ipv6 --with-http_sub_module ${Nginx_With_Openssl} ${NginxMAOpt} ${Nginx_Modules_Options}
    else
        ./configure --user=www --group=www --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module --with-ipv6 --with-http_sub_module ${Nginx_With_Openssl} ${NginxMAOpt} ${Nginx_Modules_Options}
    fi

    make && make install
    cd ../

    Echo_Blue "[+] Nginx installation completed "
}

#配置nginx
function Config_Nginx()
{
    Echo_Green "Config Nginx"

    ln -sf /usr/local/nginx/sbin/nginx /usr/bin/nginx

    rm -f /usr/local/nginx/conf/nginx.conf
    cd ${cur_dir}

    \cp conf/nginx.conf /usr/local/nginx/conf/nginx.conf

    \cp conf/pathinfo.conf /usr/local/nginx/conf/pathinfo.conf
    \cp conf/enable-php.conf /usr/local/nginx/conf/enable-php.conf
    \cp conf/enable-php-pathinfo.conf /usr/local/nginx/conf/enable-php-pathinfo.conf
    \cp conf/enable-ssl-example.conf /usr/local/nginx/conf/enable-ssl-example.conf

    mkdir -p ${Default_Website_Dir}
    chmod +w ${Default_Website_Dir}
    chown -R www:www ${Default_Website_Dir}

    \cp conf/index.html ${Default_Website_Dir}

    mkdir -p /home/wwwlogs
    chmod 777 /home/wwwlogs

    if [ "${Default_Website_Dir}" != "/home/wwwroot/default" ]; then
        sed -i "s#/home/wwwroot/default#${Default_Website_Dir}#g" /usr/local/nginx/conf/nginx.conf
    fi

    cat >${Default_Website_Dir}/.user.ini<<EOF
open_basedir=${Default_Website_Dir}:/tmp/:/proc/
EOF
        chmod 644 ${Default_Website_Dir}/.user.ini
        chattr +i ${Default_Website_Dir}/.user.ini
        cat >>/usr/local/nginx/conf/fastcgi.conf<<EOF
fastcgi_param PHP_ADMIN_VALUE "open_basedir=\$document_root/:/tmp/:/proc/";
EOF

    \cp init.d/init.d.nginx /etc/init.d/nginx
    chmod +x /etc/init.d/nginx

    Echo_Green "Config Nginx End"
}