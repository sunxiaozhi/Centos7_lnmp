#!/bin/bash

#安装必需库
CentOS_Dependent()
{
    \cp /etc/yum.conf /etc/yum.conf.lnmp
    sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf

    Echo_Blue "[+] Yum installing dependent packages..."
    for packages in make cmake gcc gcc-c++ gcc-g77 flex bison file libtool libtool-libs autoconf kernel-devel patch wget crontabs libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel unzip tar bzip2 bzip2-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel libcurl libcurl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal gettext gettext-devel ncurses-devel gmp-devel pspell-devel unzip libcap diffutils ca-certificates net-tools libc-client-devel psmisc libXpm-devel git-core c-ares-devel libicu-devel libxslt libxslt-devel xz;
    do yum -y install $packages; done

    mv -f /etc/yum.conf.lnmp /etc/yum.conf
}

CentOS_RemoveAMP()
{
    Echo_Blue "[-] Yum remove packages..."
    rpm -qa|grep httpd
    rpm -e httpd httpd-tools --nodeps
    rpm -qa|grep mysql
    rpm -e mysql mysql-libs --nodeps
    rpm -qa|grep php
    rpm -e php-mysql php-cli php-gd php-common php --nodeps

    Remove_Error_Libcurl

    yum -y remove httpd*
    yum -y remove mysql-server mysql mysql-libs
    yum -y remove php*
    yum clean all
}

Remove_Error_Libcurl()
{
    if [ -s /usr/local/lib/libcurl.so ]; then
        rm -f /usr/local/lib/libcurl*
    fi
}

Install_Autoconf()
{
    Echo_Blue "[+] Installing ${Autoconf_Ver}"
    Tar_Cd ${Autoconf_Ver}.tar.gz ${Autoconf_Ver}
    ./configure --prefix=/usr/local/autoconf-2.13
    make && make install
    cd ${cur_dir}/soft/
    rm -rf ${cur_dir}/soft/${Autoconf_Ver}
}

Install_Libiconv()
{
    Echo_Blue "[+] Installing ${Libiconv_Ver}"
    Tar_Cd ${Libiconv_Ver}.tar.gz ${Libiconv_Ver}
    patch -p0 < ${cur_dir}/soft/patch/libiconv-glibc-2.16.patch
    ./configure --enable-static
    make && make install
    cd ${cur_dir}/soft/
    rm -rf ${cur_dir}/soft/${Libiconv_Ver}
}

Install_Libmcrypt()
{
    Echo_Blue "[+] Installing ${LibMcrypt_Ver}"
    Tar_Cd ${LibMcrypt_Ver}.tar.gz ${LibMcrypt_Ver}
    ./configure
    make && make install
    /sbin/ldconfig
    cd libltdl/
    ./configure --enable-ltdl-install
    make && make install
    ln -sf /usr/local/lib/libmcrypt.la /usr/lib/libmcrypt.la
    ln -sf /usr/local/lib/libmcrypt.so /usr/lib/libmcrypt.so
    ln -sf /usr/local/lib/libmcrypt.so.4 /usr/lib/libmcrypt.so.4
    ln -sf /usr/local/lib/libmcrypt.so.4.4.8 /usr/lib/libmcrypt.so.4.4.8
    ldconfig
    cd ${cur_dir}/soft/
    rm -rf ${cur_dir}/soft/${LibMcrypt_Ver}
}

Install_Mcrypt()
{
    Echo_Blue "[+] Installing ${Mcypt_Ver}"
    Tar_Cd ${Mcypt_Ver}.tar.gz ${Mcypt_Ver}
    ./configure
    make && make install
    cd ${cur_dir}/soft/
    rm -rf ${cur_dir}/soft/${Mcypt_Ver}
}

Install_Mhash()
{
    Echo_Blue "[+] Installing ${Mhash_Ver}"
    Tarj_Cd ${Mhash_Ver}.tar.bz2 ${Mhash_Ver}
    ./configure
    make && make install
    ln -sf /usr/local/lib/libmhash.a /usr/lib/libmhash.a
    ln -sf /usr/local/lib/libmhash.la /usr/lib/libmhash.la
    ln -sf /usr/local/lib/libmhash.so /usr/lib/libmhash.so
    ln -sf /usr/local/lib/libmhash.so.2 /usr/lib/libmhash.so.2
    ln -sf /usr/local/lib/libmhash.so.2.0.1 /usr/lib/libmhash.so.2.0.1
    ldconfig
    cd ${cur_dir}/soft/
    rm -rf ${cur_dir}/soft/${Mhash_Ver}
}

Install_Freetype()
{
    Echo_Blue "[+] Installing ${Freetype_Ver}"
    Tarj_Cd ${Freetype_Ver}.tar.bz2 ${Freetype_Ver}
    ./configure --prefix=/usr/local/freetype
    make && make install

    cat > /etc/ld.so.conf.d/freetype.conf<<EOF
/usr/local/freetype/lib
EOF
    ldconfig
    ln -sf /usr/local/freetype/include/freetype2 /usr/local/include
    ln -sf /usr/local/freetype/include/ft2build.h /usr/local/include
    cd ${cur_dir}/soft/
    rm -rf ${cur_dir}/soft/${Freetype_Ver}
}

Install_Curl()
{
    Echo_Blue "[+] Installing ${Curl_Ver}"
    Tarj_Cd ${Curl_Ver}.tar.bz2 ${Curl_Ver}
    ./configure --prefix=/usr/local/curl --enable-ares --without-nss --with-ssl
    make && make install
    cd ${cur_dir}/soft/
    rm -rf ${cur_dir}/soft/${Curl_Ver}
    Remove_Error_Libcurl
}

Install_Pcre()
{
    Cur_Pcre_Ver=`pcre-config --version`
    if echo "${Cur_Pcre_Ver}" | grep -vEqi '^8.';then
        Echo_Blue "[+] Installing ${Pcre_Ver}"
        Tarj_Cd ${Pcre_Ver}.tar.bz2 ${Pcre_Ver}
        ./configure
        make && make install
        cd ${cur_dir}/soft/
        rm -rf ${cur_dir}/soft/${Pcre_Ver}
    fi
}

Install_Icu4c()
{
    if [ ! -s /usr/bin/icu-config ] || /usr/bin/icu-config --version | grep '^3.'; then
        Echo_Blue "[+] Installing ${Libicu4c_Ver}"
        cd ${cur_dir}/src
        Download_Files ${Download_Mirror}/lib/icu4c/${Libicu4c_Ver}-src.tgz ${Libicu4c_Ver}-src.tgz
        Tar_Cd ${Libicu4c_Ver}-src.tgz icu/source
        ./configure --prefix=/usr
        make && make install
        cd ${cur_dir}/soft/
        rm -rf ${cur_dir}/soft/icu
    fi
}

CentOS_Lib_Opt()
{
    Get_OS_Bit

    if [ "${Is_64bit}" = "y" ] ; then
        ln -sf /usr/lib64/libpng.* /usr/lib/
        ln -sf /usr/lib64/libjpeg.* /usr/lib/
    fi

    ulimit -v unlimited

    if [ `grep -L "/lib"    '/etc/ld.so.conf'` ]; then
        echo "/lib" >> /etc/ld.so.conf
    fi

    if [ `grep -L '/usr/lib'    '/etc/ld.so.conf'` ]; then
        echo "/usr/lib" >> /etc/ld.so.conf
        #echo "/usr/lib/openssl/engines" >> /etc/ld.so.conf
    fi

    if [ -d "/usr/lib64" ] && [ `grep -L '/usr/lib64'    '/etc/ld.so.conf'` ]; then
        echo "/usr/lib64" >> /etc/ld.so.conf
        #echo "/usr/lib64/openssl/engines" >> /etc/ld.so.conf
    fi

    if [ `grep -L '/usr/local/lib'    '/etc/ld.so.conf'` ]; then
        echo "/usr/local/lib" >> /etc/ld.so.conf
    fi

    ldconfig

    cat >>/etc/security/limits.conf<<eof
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
eof

    echo "fs.file-max=65535" >> /etc/sysctl.conf
}