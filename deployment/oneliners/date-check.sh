#! /bin/sh
for i in `cat /etc/hosts |grep 192 | cut -f2 -d " "|grep -v tools`; do echo $i&&ssh $i -p 2222 "date";done
