#!/bin/sh
ifconfig eth0 down
ifconfig eth0 hw ether 00:0a:35:00:01:21
ifconfig eth0 192.168.1.10 up

/media/card0/udc.sh start
sleep 1
ifconfig usb0 192.168.1.9 up

cd /media/card0
firmware=`peek 0x40000000`
firmware=$[ $(($firmware))>>16 ]
if [[ $firmware == 1 ]];then
    echo "Load Y320 SDR app ..."
    echo -1 > /proc/sys/kernel/sched_rt_runtime_us
    echo 50000000 > /proc/sys/net/ipv4/tcp_rmem
    echo 10485760 > /proc/sys/net/ipv4/tcp_wmem
    echo 50000000 > /proc/sys/net/core/rmem_max
    echo 10485760 > /proc/sys/net/core/wmem_max
    ./yunsdr_trx.elf &
else
    modprobe pl330_user_module
    sleep 1
    echo "Load Y320 802.11a app ..."
    ./y320-proxy-tdd.elf &
fi
