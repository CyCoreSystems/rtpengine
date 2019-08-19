#!/bin/bash

: ${RTE_TABLE:=0}

function install_module() {
   dkms autoinstall 
   modprobe xt_RTPENGINE.ko
}

function install_iptables() {
   if [ $(iptables -L INPUT |grep RTPENGINE |grep -c id:${RTE_TABLE}) -eq 0 ]; then
      iptables -I INPUT -p udp -j RTPENGINE --id ${RTE_TABLE}
   fi
}

if [ $1 == "rtpengine" ]; then
   shift
   echo "del $RTE_TABLE" > /proc/rtpengine/control
   exec rtpengine --table=$RTE_TABLE $@
else
   exec $@
fi
