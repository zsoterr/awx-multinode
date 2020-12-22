#! /bin/sh
export ANSIBLE_HOST_KEY_CHECKING=False;hosts=`cat /etc/hosts |grep presi | cut -f2 -d " " `&& for i in $hosts ;do ping $i -c1 ;done
