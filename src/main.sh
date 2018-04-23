#!/bin/bash

Color_Text()
{
  echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red()
{
  echo $(Color_Text "$1" "31")
}

Echo_Green()
{
  echo $(Color_Text "$1" "32")
}

Echo_Yellow()
{
  echo $(Color_Text "$1" "33")
}

Echo_Blue()
{
  echo $(Color_Text "$1" "34")
}

#添加用户组和用户
function add_usergroup_user()
{
    usergroup=$1
    #create group if not exists
    egrep "^${usergroup}" /etc/group >& /dev/null
    if [ $? -ne "0" ];then
        groupadd $usergroup
        if [ $? -eq "0" ]; then  #判断用户是否添加成功
            Echo_Yellow "Add user ${usergroup}."
        else
            Echo_Yellow "Can not add ${usergroup}."
            exit 1;
        fi
    else
        Echo_Yellow "usergroup exits"
    fi

    username=$2
    if id -u ${username} >/dev/null 2>&1; then
        Echo_Yellow "user exists"
    else
        #useradd ${username}
        useradd -g ${username} ${usergroup} -s /sbin/nologin -M
        #useradd -g ${username} ${usergroup} -s /sbin/nologin
        if [ $? -eq "0" ]; then  #判断用户是否添加成功
            Echo_Yellow "Add user ${username}."
        else
            Echo_Yellow "Can not add ${username}."
            exit 1;
        fi
    fi
}

Download_Files()
{
    local URL=$1
    local FileName=$2
    if [ -s "${FileName}" ]; then
        echo "${FileName} [found]"
    else
        echo "Notice: ${FileName} not found!!!download now..."
        wget -c --progress=bar:force --prefer-family=IPv4 --no-check-certificate ${URL}
    fi
}

Tar_Cd()
{
    local FileName=$1
    local DirName=$2
    cd ${cur_dir}/soft
    [[ -d "${DirName}" ]] && rm -rf ${DirName}
    echo "Uncompress ${FileName}..."
    pwd
    echo ${FileName}
    tar zxf ${FileName}
    echo "cd ${DirName}..."
    cd ${DirName}
}

Tarj_Cd()
{
    local FileName=$1
    local DirName=$2
    cd ${cur_dir}/soft
    [[ -d "${DirName}" ]] && rm -rf ${DirName}
    echo "Uncompress ${FileName}..."
    tar jxf ${FileName}
    echo "cd ${DirName}..."
    cd ${DirName}
}

Kill_PM()
{
    if ps aux | grep "yum" | grep -qv "grep"; then
        killall yum
    fi
}

Press_Install()
{
    echo ""
    Echo_Green "Press any key to install...or Press Ctrl+c to cancel"
    OLDCONFIG=`stty -g`
    stty -icanon -echo min 1 time 0
    dd count=1 2>/dev/null
    stty ${OLDCONFIG}
    Kill_PM
}

#加入开机启动
StartUp()
{
    init_name=$1
    echo "Add ${init_name} service at system startup..."

    chkconfig --add ${init_name}
    chkconfig ${init_name} on
}

#删除开机启动
Remove_StartUp()
{
    init_name=$1
    echo "Removing ${init_name} service at system startup..."

    chkconfig ${init_name} off
    chkconfig --del ${init_name}
}

Do_Query()
{
    echo "$1" >/tmp/.mysql.tmp
    Check_DB
    ${MySQL_Bin} --defaults-file=~/.my.cnf </tmp/.mysql.tmp
    return $?
}

Check_DB()
{
    if [[ -s /usr/local/mysql/bin/mysql && -s /usr/local/mysql/bin/mysqld_safe && -s /etc/my.cnf ]]; then
        MySQL_Bin="/usr/local/mysql/bin/mysql"
        MySQL_Config="/usr/local/mysql/bin/mysql_config"
        MySQL_Dir="/usr/local/mysql"
        Is_MySQL="y"
        DB_Name="mysql"
    else
        Is_MySQL="None"
        DB_Name="None"
    fi
}

TempMycnf_Clean()
{
    if [ -s ~/.my.cnf ]; then
        rm -f ~/.my.cnf
    fi
    if [ -s /tmp/.mysql.tmp ]; then
        rm -f /tmp/.mysql.tmp
    fi
}

Make_TempMycnf()
{
    cat >~/.my.cnf<<EOF
[client]
user=root
password='$1'
EOF
    chmod 600 ~/.my.cnf
}

Get_ARM()
{
    if uname -m | grep -Eqi "arm"; then
        Is_ARM='y'
    fi
}

Get_OS_Bit()
{
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
    else
        Is_64bit='n'
    fi
}