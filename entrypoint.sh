#!/bin/bash
set +e

: ${RTE_TABLE:=0}

function install_module() {
   if [ $(lsmod |grep -c xt_RTPENGINE) -gt 0 ]; then
      return
   fi

   echo "Installing kernel module..."
   dkms autoinstall 
   depmod -a
   insmod /lib/modules/$(uname -r)/updates/dkms/xt_RTPENGINE.ko
}

function install_iptables() {
   echo "Installing IPTables hook..."
   if [ $(iptables -L INPUT |grep RTPENGINE |grep -c id:${RTE_TABLE}) -eq 0 ]; then
      iptables -I INPUT -p udp -j RTPENGINE --id ${RTE_TABLE}
   fi
   if [ $(ip6tables -L INPUT |grep RTPENGINE |grep -c id:${RTE_TABLE}) -eq 0 ]; then
      ip6tables -I INPUT -p udp -j RTPENGINE --id ${RTE_TABLE}
   fi
}

function remove_old_table() {
   if [ $(cat /proc/rtpengine/list |grep -c "^${RTE_TABLE}$") -gt 0 ]; then
      echo "Deleting old RTE table ${RTE_TABLE}..."
      echo "del $RTE_TABLE" > /proc/rtpengine/control
   fi
}

install_module

# first arg is `-f` or `--some-option`
# or first arg is `something.conf`
if [ "${1#-}" != "$1" ] ; then
	set -- rtpengine "$@"
fi

if [ "$1" == "rtpengine" ]; then
   remove_old_table
   install_iptables

   shift

   echo "Starting RTPEngine..."
   exec rtpengine --table=$RTE_TABLE $@
else
   echo "Starting provided command..."
   exec $@
fi
