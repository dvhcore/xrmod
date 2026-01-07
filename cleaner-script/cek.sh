#!/bin/bash
clear
#echo -e " Tunggu 5 detik "
#echo -e " Get Information User"
#echo -n > /var/log/xray/access.log
#sleep 5
clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "     =[ Vless User Login ]=         "
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
data=( `cat /usr/local/etc/xray/config.json | grep '###' | cut -d ' ' -f 2 | sort`);
for user in "${data[@]}"
do
ehh=$(cat /var/log/xray/access.log | grep "$user" | cut -d " " -f 3 | sed 's/tcp://g' | cut -d ":" -f 1 | sort | uniq);
cekcek=$(echo -e "$ehh" | wc -w);
#if [[ $cekcek -gt 0 ]]; then
#quota=$(printf "%.3f" `echo $(cat /etc/funny/vless/$user)/1024/1024/1024 |bc -l`)
echo -e "\e[33;1mUser\e[32;1m  : $user"
echo -e "\e[33;1mLogin\e[32;1m : $cekcek IP Login "
echo -e "\e[33;1mIP\e[32;1m    :
$ehh"
#echo -e "\e[33;1mQuota\e[32;1m : $quota GB"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo "slot" >> /root/system
#else
#echo > /dev/null
#fi
done
aktif=$(cat /root/system | wc -l)
echo -e "$aktif User Online"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
sed -i "d" /root/system
