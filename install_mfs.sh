#!/usr/bin/env bash

############################################################
# Effect : install moosefs
# OS environment: For Ubuntu 14.04 LTS Trusty and above
#
# author: zhihao0905
# creat_time: 2017-8-2
# modify time:2017-8-2/master()/by zhihao0905
# modify time:2017-10-16/master():drop something about mfsmastermdata /by zhihao0905
############################################################


help(){
       cat << EOF
Usage:
Options:
    --master        init mfs master
    --cgiserv       init mfs cgiserv service
    --logger        init mfs metalogger
    --chunk         init mfs chunk service
    --client        init mfs client
    --master_host|-mh identify mfsmaster host
EOF
}

init=0


while test $# -gt 0
do
    case $1 in
        --master)
        init=1
        shift
        ;;
        --cgiserv)
        init=2
        shift
        ;;
        --logger)
        init=3
        shift
        ;;
        --chunk)
        init=4
        shift
        ;;
        --client)
        init=5
        shift
        ;;
        --master_host|-mh)
        master_ip=$2
        shift
        ;;
        --help)
        help
        exit 0
        ;;
        *)
        echo >&2 "Invalid argument: $1"
        exit 0
        ;;
    esac
     shift
done

#mkdir /mfs_stuff && cd /mfs_stuff
log_no=1
#install_log='./mfs_install_'$log_no'.log'
install_log='./mfs_install.log'







function mk_log()
{
#    while [ -f $install_log ]
#    do
#        let log_no=log_no+1
#        install_log='./mfs_install_'$log_no'.log'
#        echo $install_log
#    done

    touch $install_log

    if [ -f $install_log ]; then
        echo -e "step.1 ====> $install_log make \033[32m succ \033[0m \n"
        echo "step.1 ====> $install_log make succ" >> $install_log
    else
        echo -e "step.1 ====> $install_log make \033[31m fail \033[0m \n"
        echo "step.1 ====> $install_log make fail" >> $install_log
        exit 0
    fi
}


function add_mfsmaster_dns()
{
    #add dns of mfsmaster
    moosefs_logger_open=`cat /etc/hosts | grep mfsmaster | wc -l`
    if [ $moosefs_logger_open -eq 0 ]; then
        sed -i "1i\\$master_ip mfsmaster" /etc/hosts
    fi

    moosefs_logger_open=`cat /etc/hosts | grep mfsmaster | wc -l`
    if [ $moosefs_logger_open -eq 1 ]; then
        echo -e "dns == step.1 ====> dns mfsmaster add \033[32m succ \033[0m \n"
        echo "dns == step.1 ====> dns mfsmaster add succ " >> $install_log
    else
        echo -e "dns == step.1 ====> dns mfsmaster add \033[31m fail \033[0m \n"
        echo "dns == step.1 ====> dns mfsmaster add fail" >> $install_log
        exit 0
    fi

}

function print_date()
{
    echo '-------------------'`date`'---------------------' >> $install_log
}


function modify_rsyslog()
{
    #download rsyslog
    apt-get install rsyslog -y

    rsyslog_status=`dpkg -l rsyslog | grep 'ii  rsyslog ' | grep -v grep | wc -l`

    if [ $rsyslog_status -ne 0 ];then
        echo -e "rsyslog == step.1 ====> rsyslog install \033[32m succ \033[0m \n"
        echo "rsyslog == step.1 ====> rsyslog install succ" >> $install_log
    else
        echo -e "rsyslog == step.1 ====> rsyslog install \033[31m fail \033[0m \n"
        echo "rsyslog == step.1 ====> rsyslog install fail" >> $install_log
        exit 0
    fi

    #add mfs syslog
    mfslog_status=`cat /etc/rsyslog.conf | grep '*.info;mail.none;authpriv.none;cron.none' | grep -v grep | wc -l`
    if [ $mfslog_status -eq 0 ]; then
        echo "*.info;mail.none;authpriv.none;cron.none                /var/log/messages" >> /etc/rsyslog.conf
    fi

    #keeplog_status=`cat /etc/rsyslog.conf | grep '/var/log/keepalived' | grep -v grep | wc -l`
    mfslog_status=`cat /etc/rsyslog.conf | grep '*.info;mail.none;authpriv.none;cron.none' | grep -v grep | wc -l`
    if [ $mfslog_status -ne 0 ];then
        echo -e "rsyslog == step.2 ====> moosefs /etc/rsyslog.conf append \033[32m succ \033[0m \n"
        echo "rsyslog == step.2 ====> moosefs /etc/rsyslog.conf append succ" >> $install_log
    else
        echo -e "rsyslog == step.2 ====> moosefs /etc/rsyslog.conf append \033[31m fail \033[0m \n"
        echo "rsyslog == step.2 ====> moosefs /etc/rsyslog.conf append fail" >> $install_log
        exit 0
    fi

    #restart rsyslog
    /etc/init.d/rsyslog restart

    rsys_status=`killall -0 rsyslogd && echo $?`
    if [ $rsys_status -eq 0 ]; then
        echo -e "rsyslog == step.3 ====> moosefs rsyslog restart \033[32m succ \033[0m \n"
        echo "rsyslog == step.3 ====> moosefs rsyslog restart succ" >> $install_log
    else
        echo -e "rsyslog == step.3 ====> moosefs rsyslog restart \033[31m fail \033[0m \n"
        echo "rsyslog == step.3 ====> moosefs rsyslog restart fail" >> $install_log
        exit 0
    fi
}



function add_key()
{
    #Add the key
    add_key_status=`wget -O - http://ppa.moosefs.com/moosefs.key | apt-key add -`

    if [ $add_key_status == 'OK' ]; then
        echo -e "step.2 ====> key add \033[32m succ \033[0m \n"
        echo "step.2 ====> key add succ" >> $install_log
    else
        echo -e "step.2 ====> key add \033[31m fail \033[0m \n"
        echo "step.2 ====> key add fail" >> $install_log
        exit 0
    fi


    #And add the appropriate entry in /etc/apt/sources.list.d/moosefs.list
    echo "deb http://ppa.moosefs.com/moosefs-3/apt/ubuntu/trusty trusty main" > /etc/apt/sources.list.d/moosefs.list

    moosefs_list_status=0
    moosefs_list_status=`cat /etc/apt/sources.list.d/moosefs.list | grep moosefs-3 | wc -l`
    if [ $moosefs_list_status -eq 1 ];then
        echo -e "step.3 ====> moosefs.list add \033[32m succ \033[0m \n"
        echo "step.3 ====> moosefs.list add succ" >> $install_log
    else
        echo -e "step.3 ====> moosefs.list add \033[31m fail \033[0m \n"
        echo "step.3 ====> moosefs.list add fail" >> $install_log
        exit 0
    fi

    #update source
    apt-get update
}

function master()
{
    ##For Master Servers
    #download
    apt-get install moosefs-master=3.0.97-1 -y

    moosefs_master_status=`dpkg -l moosefs-master | grep 'ii  moosefs-master ' | wc -l`

    if [ $moosefs_master_status -ne 0 ];then
        echo -e "master == step.1 ====> moosefs-master install \033[32m succ \033[0m \n"
        echo "master == step.1 ====> moosefs-master install succ" >> $install_log
    else
        echo -e "master == step.1 ====> moosefs-master install \033[31m fail \033[0m \n"
        echo "master == step.1 ====> moosefs-master install fail" >> $install_log
        exit 0
    fi



    apt-get install moosefs-cli=3.0.97-1 -y

    moosefs_cli_status=`dpkg -l moosefs-cli | grep 'ii  moosefs-cli ' | wc -l`

    if [ $moosefs_cli_status -ne 0 ];then
        echo -e "master == step.2 ====> moosefs-cli install \033[32m succ \033[0m \n"
        echo "master == step.2 ====> moosefs-cli install succ" >> $install_log
    else
        echo -e "master == step.2 ====> moosefs-cli install \033[31m fail \033[0m \n"
        echo "master == step.2 ====> moosefs-cli install fail" >> $install_log
        exit 0
    fi

    #make config
    cp /etc/mfs/mfsmaster.cfg.sample /etc/mfs/mfsmaster.cfg
    cp /etc/mfs/mfsexports.cfg.sample /etc/mfs/mfsexports.cfg
    cp /etc/mfs/mfstopology.cfg.sample /etc/mfs/mfstopology.cfg

    if [ -e /etc/mfs/mfsmaster.cfg ]; then
        echo -e "master == step.3 ====> /etc/mfs/mfsmaster.cfg make \033[32m succ \033[0m \n"
        echo "master == step.3 ====> /etc/mfs/mfsmaster.cfg make succ" >> $install_log
    else
        echo -e "master == step.3 ====> /etc/mfs/mfsmaster.cfg make \033[31m fail \033[0m \n"
        echo "master == step.3 ====> /etc/mfs/mfsmaster.cfg make fail" >> $install_log
        exit 0
    fi

    if [ -e /etc/mfs/mfsexports.cfg ]; then
        echo -e "master == step.4 ====> /etc/mfs/mfsexports.cfg make \033[32m succ \033[0m \n"
        echo "master == step.4 ====> /etc/mfs/mfsexports.cfg make succ" >> $install_log
    else
        echo -e "master == step.4 ====> /etc/mfs/mfsexports.cfg make \033[31m fail \033[0m \n"
        echo "master == step.4 ====> /etc/mfs/mfsexports.cfg make fail" >> $install_log
        exit 0
    fi

    if [ -e /etc/mfs/mfstopology.cfg ]; then
        echo -e "master == step.5 ====> /etc/mfs/mfstopology.cfg make \033[32m succ \033[0m \n"
        echo "master == step.5 ====> /etc/mfs/mfstopology.cfg make succ" >> $install_log
    else
        echo -e "master == step.5 ====> /etc/mfs/mfstopology.cfg make \033[31m fail \033[0m \n"
        echo "master == step.5 ====> /etc/mfs/mfstopology.cfg make fail" >> $install_log
        exit 0
    fi

    #modify moosefs-master config
    if [ -e /etc/default/moosefs-master ]; then
        echo -e "master == step.6 ====> /etc/default/moosefs-master make \033[32m succ \033[0m \n"
        echo "master == step.6 ====> /etc/default/moosefs-master make succ" >> $install_log
    else
        echo -e "master == step.6 ====> /etc/default/moosefs-master make \033[31m fail \033[0m \n"
        echo "master == step.6 ====> /etc/default/moosefs-master make fail" >> $install_log
        exit 0
    fi

    sed -i 's/^MFSMASTER_ENABLE=false/#MFSMASTER_ENABLE=false/g' /etc/default/moosefs-master
    moosefs_master_open=`cat /etc/default/moosefs-master | grep MFSMASTER_ENABLE=true | wc -l`
    if [ $moosefs_master_open -eq 0 ]; then
        echo "MFSMASTER_ENABLE=true" >> /etc/default/moosefs-master
    fi

    moosefs_master_open=`cat /etc/default/moosefs-master | grep MFSMASTER_ENABLE=true | wc -l`
    if [ $moosefs_master_open -eq 1 ]; then
        echo -e "master == step.7 ====> moosefs master open \033[32m succ \033[0m \n"
        echo "master == step.7 ====> moosefs master open succ " >> $install_log
    else
        echo -e "master == step.7 ====> moosefs master open \033[31m fail \033[0m \n"
        echo "master == step.7 ====> moosefs master open fail" >> $install_log
        exit 0
    fi
    
    
# delete 
:<<eof


    #make dir : /mfsmastermdata
    mdatadir=/mfsmastermdata
    mkdir -p $mdatadir
    if [ -d $mdatadir ]; then
        echo -e "master == step.7 ====> $mdatadir make \033[32m succ \033[0m \n"
        echo "master == step.7 ====> $mdatadir make succ" >> $install_log
    else
        echo -e "master == step.7 ====> $mdatadir make \033[31m fail \033[0m \n"
        echo "master == step.7 ====> $mdatadir make fail" >> $install_log
        exit 0
    fi
    #change authority
    chown -R mfs:mfs /mfsmastermdata
    #mfsmfs
    owner=`stat -c %G%U /mfsmastermdata`
    if [ $owner == 'mfsmfs' ]; then
        echo -e "master == step.8 ====> $mdatadir owner change \033[32m succ \033[0m \n"
        echo "master == step.8 ====> $mdatadir owner change succ" >> $install_log
    else
        echo -e "master == step.8 ====> $mdatadir owner change \033[31m fail \033[0m \n"
        echo "master == step.8 ====> $mdatadir owner change fail" >> $install_log
        exit 0
    fi

    #modify mfsmaster.cfg
    mfsmastermdata_exist=`cat /etc/mfs/mfsmaster.cfg | egrep "mfsmastermdata" | wc -l`
    if [ $mfsmastermdata_exist -eq 0 ]; then
        sed -i '/#[[:space:]]DATA_PATH[[:space:]]=[[:space:]]\/var\/lib\/mfs/iDATA_PATH\ =\ \/mfsmastermdata' /etc/mfs/mfsmaster.cfg
    fi

    mfsmastermdata_exist=`cat /etc/mfs/mfsmaster.cfg | egrep "mfsmastermdata" | wc -l`
    if [ $mfsmastermdata_exist -eq 1 ]; then
        echo -e "master == step.9 ====> modify mfsmaster.cfg DATA_PATH \033[32m succ \033[0m \n"
        echo "master == step.9 ====> modify mfsmaster.cfg DATA_PATH succ" >> $install_log
    else
        echo -e "master == step.9 ====> modify mfsmaster.cfg DATA_PATH \033[31m fail \033[0m \n"
        echo "master == step.9 ====> modify mfsmaster.cfg DATA_PATH fail" >> $install_log
        exit 0
    fi

eof




    #open port : 9419 for logger; 9420 for chunk; 9421 for client
    port_9419=`iptables -L | egrep "dpt:9419" | wc -l`
    port_9420=`iptables -L | egrep "dpt:9420" | wc -l`
    port_9421=`iptables -L | egrep "dpt:9421" | wc -l`
    
    if [ $port_9419 -eq 0 ]; then
        sed -i '/COMMIT/i\-A INPUT -p tcp -m state --state NEW -m tcp --dport 9419 -j ACCEPT' /etc/iptables.rules
    fi

    if [ $port_9420 -eq 0 ]; then
        sed -i '/COMMIT/i\-A INPUT -p tcp -m state --state NEW -m tcp --dport 9420 -j ACCEPT' /etc/iptables.rules
    fi

    if [ $port_9421 -eq 0 ]; then
    sed -i '/COMMIT/i\-A INPUT -p tcp -m state --state NEW -m tcp --dport 9421 -j ACCEPT' /etc/iptables.rules
    fi

    iptables-restore < /etc/iptables.rules

    port_open=`iptables -L | egrep "dpt:9419|dpt:9420|dpt:9421" | wc -l`
    if [ $port_open -eq 3 ]; then
        echo -e "master == step.8 ====> port 9419,9420,9421 open \033[32m succ \033[0m \n"
        echo "master == step.8 ====> port 9419,9420,9421 open succ" >> $install_log
    else
        echo -e "master == step.8 ====> port 9419,9420,9421 open \033[31m fail \033[0m \n"
        echo "master == step.8 ====> port 9419,9420,9421 open fail" >> $install_log
        exit 0
    fi
}

function cgiserv()
{
    ##For Cgiserv Servers
    #download
    apt-get install moosefs-cgiserv=3.0.97-1 -y

    moosefs_cgiserv_status=`dpkg -l moosefs-cgiserv | grep 'ii  moosefs-cgiserv ' | wc -l`

    if [ $moosefs_cgiserv_status -ne 0 ];then
        echo -e "cgiserv == step.1 ====> moosefs-cgiserv install \033[32m succ \033[0m \n"
        echo "cgiserv == step.1 ====> moosefs-cgiserv install succ" >> $install_log
    else
        echo -e "cgiserv == step.1 ====> moosefs-cgiserv install \033[31m fail \033[0m \n"
        echo "cgiserv == step.1 ====> moosefs-cgiserv install fail" >> $install_log
        exit 0
    fi

    #open cgiserv
    sed -i 's/^MFSCGISERV_ENABLE=false/#MFSCGISERV_ENABLE=false/g' /etc/default/moosefs-cgiserv

    moosefs_cgiserv_open=`cat /etc/default/moosefs-cgiserv | grep MFSMASTER_ENABLE=true | wc -l`
    if [ $moosefs_cgiserv_open -eq 0 ];then
        echo "MFSCGISERV_ENABLE=true" >> /etc/default/moosefs-cgiserv
    fi

    moosefs_cgiserv_open=`cat /etc/default/moosefs-cgiserv | grep MFSCGISERV_ENABLE=true | wc -l`
    if [ $moosefs_cgiserv_open -eq 1 ]; then
        echo -e "cgiserv == step.2 ====> moosefs cgiserv open \033[32m succ \033[0m \n"
        echo "cgiserv == step.2 ====> moosefs cgiserv open succ " >> $install_log
    else
        echo -e "cgiserv == step.2 ====> moosefs cgiserv open \033[31m fail \033[0m \n"
        echo "cgiserv == step.2 ====> moosefs cgiserv open fail" >> $install_log
        exit 0
    fi

    #open port : 9425 for cgiserv
    port_9425=`iptables -L | egrep "dpt:9425" | wc -l`

    if [ $port_9425 -eq 0 ]; then
        sed -i '/COMMIT/i\-A INPUT -p tcp -m state --state NEW -m tcp --dport 9425 -j ACCEPT' /etc/iptables.rules
    fi

    iptables-restore < /etc/iptables.rules

    port_open=`iptables -L | egrep "dpt:9425" | wc -l`
    if [ $port_open -eq 1 ]; then
        echo -e "cgiserv == step.3 ====> port 9425 open \033[32m succ \033[0m \n"
        echo "cgiserv == step.3 ====> port 9425 open succ" >> $install_log
    else
        echo -e "cgiserv == step.3 ====> port 9425 open \033[31m fail \033[0m \n"
        echo "cgiserv == step.3 ====> port 9425 open fail" >> $install_log
        exit 0
    fi

}

function logger()
{
    ##For logger Servers
    #download
    apt-get install moosefs-metalogger=3.0.97-1 -y

    moosefs_metalogger_status=`dpkg -l moosefs-metalogger | grep 'ii  moosefs-metalogger ' | wc -l`

    if [ $moosefs_metalogger_status -ne 0 ];then
        echo -e "logger == step.1 ====> moosefs-metalogger install \033[32m succ \033[0m \n"
        echo "logger == step.1 ====> moosefs-metalogger install succ" >> $install_log
    else
        echo -e "logger == step.1 ====> moosefs-metalogger install \033[31m fail \033[0m \n"
        echo "logger == step.1 ====> moosefs-metalogger install fail" >> $install_log
        exit 0
    fi


    #make config
    cp /etc/mfs/mfsmetalogger.cfg.sample /etc/mfs/mfsmetalogger.cfg

    if [ -e /etc/mfs/mfsmetalogger.cfg ]; then
        echo -e "logger == step.2 ====> /etc/mfs/mfsmetalogger.cfg make \033[32m succ \033[0m \n"
        echo "logger == step.2 ====> /etc/mfs/mfsmetalogger.cfg make succ" >> $install_log
    else
        echo -e "logger == step.2 ====> /etc/mfs/mfsmetalogger.cfg make \033[31m fail \033[0m \n"
        echo "logger == step.2 ====> /etc/mfs/mfsmetalogger.cfg make fail" >> $install_log
        exit 0
    fi

    #open mfsmetalogger
    sed -i 's/^MFSMETALOGGER_ENABLE=false/#MFSMETALOGGER_ENABLE=false/g' /etc/default/moosefs-metalogger
    moosefs_logger_open=`cat /etc/default/moosefs-metalogger | grep MFSMETALOGGER_ENABLE=true | wc -l`
    if [ $moosefs_logger_open -eq 0 ]; then
        echo "MFSMETALOGGER_ENABLE=true" >> /etc/default/moosefs-metalogger
    fi

    moosefs_logger_open=`cat /etc/default/moosefs-metalogger | grep MFSMETALOGGER_ENABLE=true | wc -l`
    if [ $moosefs_logger_open -eq 1 ]; then
        echo -e "logger == step.3 ====> moosefs logger open \033[32m succ \033[0m \n"
        echo "logger == step.3 ====> moosefs logger open succ " >> $install_log
    else
        echo -e "logger == step.3 ====> moosefs logger open \033[31m fail \033[0m \n"
        echo "logger == step.3 ====> moosefs logger open fail" >> $install_log
        exit 0
    fi

}


function chunk()
{
    ##For chunk Servers
    #download
    apt-get install moosefs-chunkserver=3.0.97-1 -y

    moosefs_chunk_status=`dpkg -l moosefs-chunkserver | grep 'ii  moosefs-chunkserver ' | wc -l`

    if [ $moosefs_chunk_status -ne 0 ];then
        echo -e "chunk == step.1 ====> moosefs-chunkserver install \033[32m succ \033[0m \n"
        echo "chunk == step.1 ====> moosefs-chunkserver install succ" >> $install_log
    else
        echo -e "chunk == step.1 ====> moosefs-chunkserver install \033[31m fail \033[0m \n"
        echo "chunk == step.1 ====> moosefs-chunkserver install fail" >> $install_log
        exit 0
    fi


    #make config
    cp /etc/mfs/mfschunkserver.cfg.sample /etc/mfs/mfschunkserver.cfg

    if [ -e /etc/mfs/mfschunkserver.cfg ]; then
        echo -e "chunk == step.2 ====> /etc/mfs/mfschunkserver.cfg make \033[32m succ \033[0m \n"
        echo "chunk == step.2 ====> /etc/mfs/mfschunkserver.cfg make succ" >> $install_log
    else
        echo -e "chunk == step.2 ====> /etc/mfs/mfschunkserver.cfg make \033[31m fail \033[0m \n"
        echo "chunk == step.2 ====> /etc/mfs/mfschunkserver.cfg make fail" >> $install_log
        exit 0
    fi

    cp /etc/mfs/mfshdd.cfg.sample /etc/mfs/mfshdd.cfg

    if [ -e /etc/mfs/mfshdd.cfg ]; then
        echo -e "chunk == step.3 ====> /etc/mfs/mfshdd.cfg make \033[32m succ \033[0m \n"
        echo "chunk == step.3 ====> /etc/mfs/mfshdd.cfg make succ" >> $install_log
    else
        echo -e "chunk == step.3 ====> /etc/mfs/mfshdd.cfg make \033[31m fail \033[0m \n"
        echo "chunk == step.3 ====> /etc/mfs/mfshdd.cfg make fail" >> $install_log
        exit 0
    fi


    #open moosefs-chunkserver
    sed -i 's/^MFSCHUNKSERVER_ENABLE=false/#MFSCHUNKSERVER_ENABLE=false/g' /etc/default/moosefs-chunkserver
    moosefs_chunk_open=`cat /etc/default/moosefs-chunkserver | grep MFSCHUNKSERVER_ENABLE=true | wc -l`
    if [ $moosefs_chunk_open -eq 0 ]; then
        echo "MFSCHUNKSERVER_ENABLE=true" >> /etc/default/moosefs-chunkserver
    fi

    moosefs_chunk_open=`cat /etc/default/moosefs-chunkserver | grep MFSCHUNKSERVER_ENABLE=true | wc -l`
    if [ $moosefs_chunk_open -eq 1 ]; then
        echo -e "chunk == step.4 ====> moosefs logger open \033[32m succ \033[0m \n"
        echo "chunk == step.4 ====> moosefs logger open succ " >> $install_log
    else
        echo -e "chunk == step.4 ====> moosefs logger open \033[31m fail \033[0m \n"
        echo "chunk == step.4 ====> moosefs logger open fail" >> $install_log
        exit 0
    fi

    #make data dir
    datadir=/mnt/mfschunk
    mkdir -p $datadir
    if [ -d $datadir ]; then
        echo -e "chunk == step.5 ====> $datadir make \033[32m succ \033[0m \n"
        echo "chunk == step.5 ====> $datadir make succ" >> $install_log
    else
        echo -e "chunk == step.5 ====> $datadir make \033[31m fail \033[0m \n"
        echo "chunk == step.5 ====> $datadir make fail" >> $install_log
        exit 0
    fi

    #change authority
    chmod 770 /mnt/mfschunk
    chown -R mfs:mfs /mnt/mfschunk
    #drwxr-xr-x
    auth=`ls -ld /mnt/mfschunk | awk '{print $1}'`
    if [ $auth == 'drwxrwx---' ]; then
        echo -e "chunk == step.6 ====> $datadir auth change \033[32m succ \033[0m \n"
        echo "chunk == step.6 ====> $datadir auth change succ" >> $install_log
    else
        echo -e "chunk == step.6 ====> $datadir auth change \033[31m fail \033[0m \n"
        echo "chunk == step.6 ====> $datadir auth change fail" >> $install_log
        exit 0
    fi
    #mfsmfs
    owner=`stat -c %G%U /mnt/mfschunk`
    if [ $owner == 'mfsmfs' ]; then
        echo -e "chunk == step.7 ====> $datadir owner change \033[32m succ \033[0m \n"
        echo "chunk == step.7 ====> $datadir owner change succ" >> $install_log
    else
        echo -e "chunk == step.7 ====> $datadir owner change \033[31m fail \033[0m \n"
        echo "chunk == step.7 ====> $datadir owner change fail" >> $install_log
        exit 0
    fi

    #open port : 9422 for chunk
    port_9422=`iptables -L | egrep "dpt:9422" | wc -l`

    if [ $port_9422 -eq 0 ]; then
        sed -i '/COMMIT/i\-A INPUT -p tcp -m state --state NEW -m tcp --dport 9422 -j ACCEPT' /etc/iptables.rules
    fi

    iptables-restore < /etc/iptables.rules

    port_open=`iptables -L | egrep "dpt:9422" | wc -l`
    if [ $port_open -eq 1 ]; then
        echo -e "chunk == step.8 ====> port 9422 open \033[32m succ \033[0m \n"
        echo "chunk == step.8 ====> port 9422 open succ" >> $install_log
    else
        echo -e "chunk == step.8 ====> port 9422 open \033[31m fail \033[0m \n"
        echo "chunk == step.8 ====> port 9422 open fail" >> $install_log
        exit 0
    fi





}


function client()
{
    ##For Master client
    #download
    apt-get install moosefs-client=3.0.97-1 -y

    moosefs_client_status=`dpkg -l moosefs-client | grep 'ii  moosefs-client ' | wc -l`

    if [ $moosefs_client_status -ne 0 ];then
        echo -e "client == step.1 ====> moosefs-client install \033[32m succ \033[0m \n"
        echo "client == step.1 ====> moosefs-client install succ" >> $install_log
    else
        echo -e "client == step.1 ====> moosefs-client install \033[31m fail \033[0m \n"
        echo "client == step.1 ====> moosefs-client install fail" >> $install_log
        exit 0
    fi


    #make config
    cp /etc/mfs/mfsmount.cfg.sample /etc/mfs/mfsmount.cfg

    if [ -e /etc/mfs/mfsmount.cfg ]; then
        echo -e "client == step.2 ====> /etc/mfs/mfsmount.cfg make \033[32m succ \033[0m \n"
        echo "client == step.2 ====> /etc/mfs/mfsmount.cfg make succ" >> $install_log
    else
        echo -e "client == step.2 ====> /etc/mfs/mfsmount.cfg make \033[31m fail \033[0m \n"
        echo "client == step.2 ====> /etc/mfs/mfsmount.cfg make fail" >> $install_log
        exit 0
    fi

    #append mount dir info in /etc/mfs/mfsmount.cfg
    moosefs_client_mount=`cat /etc/mfs/mfsmount.cfg | grep mfs_filedata | wc -l`
    if [ $moosefs_client_mount -eq 0 ]; then
        echo "/mfs_filedata" >> /etc/mfs/mfsmount.cfg
    fi

    moosefs_client_mount=`cat /etc/mfs/mfsmount.cfg | grep mfs_filedata | wc -l`
    if [ $moosefs_client_mount -eq 1 ];then
        echo -e "client == step.3 ====> moosefs-client mount info append \033[32m succ \033[0m \n"
        echo "client == step.3 ====> moosefs-client mount  info append succ" >> $install_log
    else
        echo -e "client == step.3 ====> moosefs-client mount  info append \033[31m fail \033[0m \n"
        echo "client == step.3 ====> moosefs-client mount  info append fail" >> $install_log
        exit 0
    fi

    #make dir /mfs_filedata
    filedata_dir=/mfs_filedata
    mkdir -p $filedata_dir
    if [ -d $filedata_dir ]; then
        echo -e "client == step.4 ====> $filedata_dir make \033[32m succ \033[0m \n"
        echo "client == step.4 ====> $filedata_dir make succ" >> $install_log
    else
        echo -e "client == step.4 ====> $filedata_dir make \033[31m fail \033[0m \n"
        echo "client == step.4 ====> $filedata_dir make fail" >> $install_log
        exit 0
    fi

    #mount /mfs_filedata
    mfsmount_status=`df -h | grep mfsmaster|wc -l`
    if [ $mfsmount_status -eq 0 ];then

        mfsmount /mfs_filedata -H mfsmaster
    fi

    mfsmount_status=`df -h | grep mfsmaster|wc -l`
    if [ $mfsmount_status -eq 1 ];then
        echo -e "client == step.5 ====> moosefs-client mount \033[32m succ \033[0m \n"
        echo "client == step.5 ====> moosefs-client mount succ" >> $install_log
    else
        echo -e "client == step.5 ====> moosefs-client mount \033[31m fail \033[0m \n"
        echo "client == step.5 ====> moosefs-client mount fail" >> $install_log
        exit 0
    fi

}



function main()
{
    print_date
    mk_log

    if [ $init -eq 1 ];then
        add_key
        add_mfsmaster_dns
        master
        modify_rsyslog
    elif [ $init -eq 2 ];then
        add_key
        add_mfsmaster_dns
        cgiserv
        modify_rsyslog
    elif [ $init -eq 3 ];then
        add_key
        add_mfsmaster_dns
        logger
        modify_rsyslog
    elif [ $init -eq 4 ];then
        add_key
        add_mfsmaster_dns
        chunk
        modify_rsyslog
    elif [ $init -eq 5 ];then
        add_key
        add_mfsmaster_dns
        client
        modify_rsyslog
    #else
    #    echo -e "Invalid argument: $1 \n"
    fi
}

main
