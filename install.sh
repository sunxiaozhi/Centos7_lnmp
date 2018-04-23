#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#判断用户是否是root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi

#获取当前路径
cur_dir=$(pwd)

#LNMP版本号
LNMP_Ver=0.1

#引入文件
. lnmp.conf
. src/init.sh
. src/main.sh
. src/mysql.sh
. src/php.sh
. src/nginx.sh
. src/version.sh
. src/end.sh

clear
echo "+------------------------------------------------------------------------+"
echo "|               LNMP V${LNMP_Ver} for Centos Linux Server                |"
echo "+------------------------------------------------------------------------+"
echo "|             A tool to auto-compile & install LNMP on Linux             |"
echo "+------------------------------------------------------------------------+"

#初始化
function Init_Install()
{
    Press_Install

    CentOS_RemoveAMP

    #yum安装必需库
    CentOS_Dependent

    Install_Autoconf
    Install_Libiconv
    Install_Libmcrypt
    Install_Mhash
    Install_Mcrypt
    Install_Freetype
    Install_Curl
    Install_Pcre
    Install_Icu4c
}

#安装lnmp
function LNMP_Install()
{
    Init_Install

    Install_Only_Mysql

    Install_Only_PHP

    Install_Only_Nginx

    Creat_PHP_Tools

    Add_Iptables_Rules

    Check_LNMP_Install
}

#只安装mysql
function Install_Only_Mysql()
{
    Echo_Green "Install MySQL"
    sleep 1
    Install_MySQL_56
    TempMycnf_Clean

    Add_Startup mysql
}

#只安装nginx
function Install_Only_Nginx()
{
    Echo_Green "Install Nginx"
    sleep 1
    Install_Nginx
    Config_Nginx

    Add_Startup nginx
}

#只安装php
function Install_Only_PHP()
{
    Echo_Green "Install PHP"
    sleep 1
    Install_PHP_7
    LNMP_PHP_Opt

    Add_Startup php
}

Installation=$1
if [ "${Installation}" = "" ]; then
    Installation="lnmp"
else
    Installation=$1
fi

case "${Installation}" in
    "lnmp")
        LNMP_Install 2>&1 | tee /root/lnmp-install.log
        ;;
    "mysql")
        Init_Install
        Install_Only_Mysql 2>&1 | tee /root/mysql-install.log
        ;;
    "nginx")
        Init_Install
        Install_Only_Nginx 2>&1 | tee /root/nginx-install.log
        ;;
    "php")
        Init_Install
        Install_Only_PHP 2>&1 | tee /root/php-install.log
        ;;
    "php-tools")
        Creat_PHP_Tools 2>&1 | tee /root/php-tools-install.log
        ;;
    *)
        Echo_Red "Usage: $0 {lnmp|nginx|mysql}"
        ;;
esac