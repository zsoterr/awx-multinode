#! /bin/sh
for i in `cat /etc/hosts |grep presi | cut -f2 -d " "|grep -v tools`; do echo $i&&ssh $i -p 2222 "df -h";done
