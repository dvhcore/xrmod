#!/bin/bash
# =========================================
# Vless Websocket By Vinstechmy
# Support Custom/Multipath For Vless WS
# Version    : 1.0
# Script By  : Vinstechmy
# (C) Copyright 2025 By Vinstechmy
# =========================================
clear
#Color
RED="\033[31m"
export NC='\e[0m'
export DEFBOLD='\e[39;1m'
export RB='\e[31;1m'
export GB='\e[32;1m'
export YB='\e[33;1m'
export BB='\e[34;1m'
export MB='\e[35;1m'
export CB='\e[35;1m'
export WB='\e[37;1m'

if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
fi
if [ "$(systemd-detect-virt)" == "openvz" ]; then
		echo "OpenVZ is not supported"
		exit 1
fi

echo -e ""
echo -e "\e[94m              .-----------------------------------------------.    "
echo -e "\e[94m              |          Installing Autoscript Begin          |    "
echo -e "\e[94m              '-----------------------------------------------'    "
echo -e "\e[0m"
echo ""
sleep 3
clear

if [ -f "/usr/local/etc/xray/domain" ]; then
echo "Script Already Installed"
exit 0
fi

secs_to_human() {
    echo "Installation time : $(( ${1} / 3600 )) hours $(( (${1} / 60) % 60 )) minute's $(( ${1} % 60 )) seconds"
}
start=$(date +%s)

#update
apt update -y
apt full-upgrade -y
apt dist-upgrade -y
apt install sudo -y
apt install socat curl screen cron neofetch screenfetch netfilter-persistent vnstat fail2ban -y
apt-get --reinstall --fix-missing install -y bzip2 gzip coreutils wget screen rsyslog iftop htop net-tools zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr libxml-parser-perl neofetch git lsof
apt-get remove --purge ufw firewalld -y
apt-get remove --purge exim4 -y
mkdir /backup
mkdir /user
clear

# install resolvconf service
apt install resolvconf -y

rm -rf /etc/resolv.conf
cat > /etc/resolv.conf <<-RSV1
nameserver 1.1.1.1
nameserver 1.0.0.1
RSV1

# Make Folder Log XRAY
mkdir -p /var/log/xray
chmod +x /var/log/xray

# Make Folder XRAY
mkdir -p /usr/local/etc/xray

# Make Folder Config Logs
mkdir -p /usr/local/etc/xray/configlogs

#Download XRAY Core v1.7.5.1 MSSVPN Custom
wget -q -O /usr/local/bin/xray "https://github.com/dn4i/dn4i.github.io/releases/download/Dray-Mod1/xray-25.0.15-mod" && chmod 755 /usr/local/bin/xray

cd

cd /usr/local/bin

wget https://dn4i.github.io/cleaner-script/geoip.dat && chmod 755 geoip.dat;

wget https://dn4i.github.io/cleaner-script/geosite.dat && chmod 755 geosite.dat;

cd


#Server Info
curl -s ipinfo.io/city >> /usr/local/etc/xray/city
curl -s ipinfo.io/org | cut -d " " -f 2-10 >> /usr/local/etc/xray/org
curl -s ipinfo.io/timezone >> /usr/local/etc/xray/timezone
clear

cd
clear

# Install Speedtest
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest
clear

# set time GMT +8 Kuala Lumpur
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

clear

# Insert Domain Features
touch /usr/local/etc/xray/domain
echo -e "${RED}♦️${NC} ${green}Vless Websocket Autoscript By Vinstechmy${NC} ${RED}♦️${NC}"
echo ""
echo "Please Insert Your Domain Before Proceed Installing"
echo " "
read -rp "Insert Domain : " -e dns
if [ -z $dns ]; then
echo -e "Please Insert Domain!"
else
echo "$dns" > /usr/local/etc/xray/domain
echo "DNS=$dns" > /var/lib/dnsvps.conf
fi
clear

# Install Cert Domain For XRAY 
systemctl stop nginx
domain=$(cat /usr/local/etc/xray/domain)
curl https://get.acme.sh | sh
source ~/.bashrc
cd .acme.sh
bash acme.sh --issue -d $domain --server letsencrypt --keylength ec-256 --fullchain-file /usr/local/etc/xray/xray.crt --key-file /usr/local/etc/xray/xray.key --standalone --force

# Random UUID For XRAY
uuid=$(cat /proc/sys/kernel/random/uuid)

#INSTALLING WEBSOCKET TLS
cat> /usr/local/etc/xray/config.json << END
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "level": 0,
            "email": ""
#tls
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless-tls"
        },
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/usr/local/etc/xray/xray.crt",
              "keyFile": "/usr/local/etc/xray/xray.key"
            }
          ]
        }
      }
     }
  ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
		]
}
END

# // INSTALLING WEBSOCKET NONE-TLS
cat> /usr/local/etc/xray/none.json << END
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
     "port": "80",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "level": 0,
            "email": ""
#none
          }
        ],
        "decryption": "none"
      },
      "encryption": "none",
      "streamSettings": {
        "network": "ws",
	"security": "none",
        "wsSettings": {
          "path": "/vless-ntls",
          "headers": {
            "Host": ""
          }
         },
        "quicSettings": {},
        "sockopt": {
          "mark": 0,
          "tcpFastOpen": true
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
		]
}
END

#Remove Old Service
rm -rf /etc/systemd/system/xray.service.d
rm -rf /etc/systemd/system/xray@.service.d

#XRAY Service
cat> /etc/systemd/system/xray.service << END
[Unit]
Description=XRAY-MULTIPORT SERVICE
Documentation=https://t.me/Vinstechmy https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartSec=3s
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

END

#XRAY Service
cat> /etc/systemd/system/xray@.service << END
[Unit]
Description=Xray Service
Documentation=https://t.me/Vinstechmy https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/%i.json
Restart=on-failure
RestartSec=3s
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

END

# enable xray ws tls
echo -e "[ ${GB}OK${NC} ] Restarting XRAY Core Service"
systemctl daemon-reload
systemctl enable xray.service
systemctl start xray.service
systemctl restart xray.service

# enable xray ws ntls
systemctl daemon-reload
systemctl enable xray@none.service
systemctl start xray@none.service
systemctl restart xray@none.service

sleep 1

# Blokir TORRENT
iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

# Github Profile Repo
Git_Profile="https://raw.githubusercontent.com/vinstechmy/VlessWebsocket/main"
echo -e "[ ${GB}INFO${NC} ] Download Autoscript Files Into VPS"
echo ""
sleep 1

#MENU
wget -O /usr/bin/menu "${Git_Profile}/MENU/menu.sh" && chmod +x /usr/bin/menu
wget -O /usr/bin/menu-vless "${Git_Profile}/MENU/menu-vless.sh" && chmod +x /usr/bin/menu-vless
wget -O /usr/bin/backupmenu "${Git_Profile}/MENU/backupmenu.sh" && chmod +x /usr/bin/backupmenu

#XRAY
wget -O /usr/bin/add-vless "${Git_Profile}/XRAY/add-vless.sh" && chmod +x /usr/bin/add-vless
wget -O /usr/bin/del-vless "${Git_Profile}/XRAY/del-vless.sh" && chmod +x /usr/bin/del-vless
wget -O /usr/bin/cek-vless "${Git_Profile}/XRAY/cek-vless.sh" && chmod +x /usr/bin/cek-vless
wget -O /usr/bin/renew-vless "${Git_Profile}/XRAY/renew-vless.sh" && chmod +x /usr/bin/renew-vless
wget -O /usr/bin/user-vless "${Git_Profile}/XRAY/user-vless.sh" && chmod +x /usr/bin/user-vless
wget -O /usr/bin/trial-vless "${Git_Profile}/XRAY/trial-vless.sh" && chmod +x /usr/bin/trial-vless


#OTHERS
wget -O /usr/bin/limit "${Git_Profile}/OTHERS/limit-speed.sh" && chmod +x /usr/bin/limit
wget -O /usr/bin/add-host "${Git_Profile}/OTHERS/add-host.sh" && chmod +x /usr/bin/add-host
wget -O /usr/bin/cekport "${Git_Profile}/OTHERS/cekport.sh" && chmod +x /usr/bin/cekport
wget -O /usr/bin/certxray "${Git_Profile}/OTHERS/certxray.sh" && chmod +x /usr/bin/certxray
wget -O /usr/bin/dns "${Git_Profile}/OTHERS/dns.sh" && chmod +x /usr/bin/dns
wget -O /usr/bin/get-backres "${Git_Profile}/OTHERS/get-backres.sh" && chmod +x /usr/bin/get-backres
wget -O /usr/bin/restart "${Git_Profile}/OTHERS/restart.sh" && chmod +x /usr/bin/restart
wget -O /usr/bin/status "${Git_Profile}/OTHERS/status.sh" && chmod +x /usr/bin/status
wget -O /usr/bin/cleaner "${Git_Profile}/OTHERS/logcleaner.sh" && chmod +x /usr/bin/cleaner
wget -O /usr/bin/xp "${Git_Profile}/OTHERS/xp.sh" && chmod +x /usr/bin/xp
wget -O /usr/bin/ram "${Git_Profile}/OTHERS/ram.sh" && chmod +x /usr/bin/ram
wget -O /usr/bin/nf "https://raw.githubusercontent.com/vinstechmy/MediaUnlockerTest/main/media.sh" && chmod +x /usr/bin/nf


# Installing RAM & CPU Monitor
#curl https://raw.githubusercontent.com/xxxserxxx/gotop/master/scripts/download.sh | bash && chmod +x gotop && sudo mv gotop /usr/local/bin/

echo -e "[ ${GB}INFO${NC} ] Autoscript Files Successfully Download !"
echo ""
sleep 2
clear

# Crontab settings
echo "0 6 * * * root reboot" >> /etc/crontab
echo "0 6 * * * root /usr/bin/xp" >> /etc/crontab
echo "*/2 * * * * root /usr/bin/cleaner" >> /etc/crontab

#Set Log Cleaner
if [ ! -f "/etc/cron.d/cleaner" ]; then
cat> /etc/cron.d/cleaner << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/2 * * * * root /usr/bin/cleaner
END
fi

systemctl restart cron
systemctl restart sshd

cat > /root/.profile << END
# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n || true
clear
menu
END

# remove unnecessary files
cd
apt autoclean -y
apt -y remove --purge unscd
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove bind9*;
apt-get -y remove sendmail*
apt autoremove -y

#Autoscript Version
echo "1.0" > /home/ver

clear
echo ""
echo -e "${RB}      .-------------------------------------------.${NC}"
echo -e "${RB}      |${NC}      ${CB}Installation Has Been Completed${NC}      ${RB}|${NC}"
echo -e "${RB}      '-------------------------------------------'${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "          ${WB}Vless Websocket Autoscript By Vinstechmy${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "  ${WB}»»» Protocol Service «««  |  »»» Network Protocol «««${NC}  "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Vless Websocket TLS${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Vless Websocket Non TLS${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "             ${WB}»»» Server Information «««${NC}                 "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Timezone                : Asia/Kuala_Lumpur (GMT +8)${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Fail2Ban                : [ON]${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Deflate                 : [ON]${NC}"
echo -e "  ${RB}♦️${NC} ${YB}IPtables                : [ON]${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Auto-Reboot             : [ON]${NC}"
echo -e "  ${RB}♦️${NC} ${YB}IPV6                    : [OFF]${NC}"
echo -e ""
echo -e "  ${RB}♦️${NC} ${YB}Autoreboot On 06.00 GMT +8${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Autobackup On 12:05 GMT +8${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Backup VPS Data Via Telegram Bot${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Backup & Restore VPS Data${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Automatic Delete Expired Account${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Bandwith Monitor${NC}"
echo -e "  ${RB}♦️${NC} ${YB}RAM & CPU Monitor${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Check Login User${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Check Created Config${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Automatic Clear Log${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Media Checker${NC}"
echo -e "  ${RB}♦️${NC} ${YB}DNS Changer${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "              ${WB}»»» Network Port Service «««${NC}             "
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo -e "  ${RB}♦️${NC} ${YB}TLS                    : 443${NC}"
echo -e "  ${RB}♦️${NC} ${YB}Non TLS                : 80${NC}"
echo -e "${BB}————————————————————————————————————————————————————————${NC}"
echo ""
secs_to_human "$(($(date +%s) - ${start}))"
echo ""
echo -ne "${YB}[ WARNING ] Reboot now ? (Y/N)${NC} : "
read REDDIR
if [ "$REDDIR" == "${REDDIR#[Yy]}" ]; then
    rm -r setup.sh
	clear
    menu
else
    rm -r install.sh
    reboot
fi
