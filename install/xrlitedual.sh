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

#Install Update & Dependencies
apt install curl socat xz-utils zip pwgen openssl wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release cron bash-completion net-tools -y
apt install sudo git make htop resolvconf dnsutils lsb-release socat curl screen xz-utils bash-completion screenfetch pwgen openssl cron vnstat fail2ban nano iptables -y

#Automate Iptables Setting
echo "iptables-persistent iptables-persistent/autosave_v4 boolean false" | sudo debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean false" | sudo debconf-set-selections

#Install Iptables Persistent
apt-get install iptables-persistent netfilter-persistent -y

#setting resolvconf
systemctl disable systemd-resolved

rm -rf /etc/resolv.conf
cat > /etc/resolv.conf <<-RSV1
nameserver 1.1.1.1
nameserver 1.0.0.1
RSV1
chattr +i /etc/resolv.conf

#Continue Update
apt-get --reinstall --fix-missing install -y bzip2 gzip coreutils wget screen rsyslog iftop htop net-tools zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr libxml-parser-perl cron screenfetch git lsof
apt-get autoremove --purge bind9 exim4 ufw modemmanager firewalld -y
mkdir /backup
mkdir /user
clear

# Make Folder Log XRAY
mkdir -p /var/log/xray
chmod +x /var/log/xray

# Make Folder XRAY
mkdir -p /usr/local/etc/xray

# Make Folder Config Logs
mkdir -p /usr/local/etc/xray/configlogs

#DOWNLOAD XRAY1
wget -q -O /usr/local/bin/xray1 "https://github.com/dvhcore/xrmod/releases/download/XR172-MOD/XR172MOD" && chmod 755 /usr/local/bin/xray1

#DOWNLOAD XRAY2
wget -q -O /usr/local/bin/xray2 "https://github.com/dvhcore/xrmod/releases/download/XR25E-MOD/XR25EMOD" && chmod 755 /usr/local/bin/xray2

#DOWNLOAD GEOIP
wget -O /usr/local/bin/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat

#DOWNLOAD GEOSITE
wget -O /usr/local/bin/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat

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
timedatectl set-timezone Asia/Kuala_Lumpur
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

# Install Nginx
apt install nginx -y
rm /var/www/html/*.html
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
systemctl restart nginx
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

# Nginx directory file download
mkdir -p /home/vps/public_html
cd
chown -R www-data:www-data /home/vps/public_html

# Random UUID For XRAY
uuid=$(cat /proc/sys/kernel/random/uuid)

# // INSTALLING WEBSOCKET NONE-TLS
cat > /usr/local/etc/xray/config.json <<XRTLS
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
     {
       "port": 80,
       "listen": "0.0.0.0",
       "tag": "tcpnone",
       "protocol": "vless",
       "settings": {
         "clients": [
           {
             "email": "general@vless-tcp",
             "id": "${uuid}",
             "level": 0
           }
         ],
         "decryption": "none",
         "fallbacks": [
           {
             "dest": 10001,
             "xver": 1
           },
           {
             "dest": 10001,
             "path": "/vless",
             "xver": 1
           }
         ]
       },
       "streamSettings": {
         "network": "tcp",
         "security": "none"
       },
       "sniffing": {
         "enabled": true,
         "destOverride": ["http", "tls","quic"]
       }
     },
     {
       "port": 10001,
       "listen": "127.0.0.1",
       "tag": "wsnone-in",
       "protocol": "vless",
       "settings": {
          "clients": [
            {
              "email": "general@vless-ws",
              "id": "${uuid}",
              "level": 0
#tls
            }
          ],
          "decryption": "none"
       },
       "streamSettings": {
         "network": "ws",
         "security": "none",
         "wsSettings": {
         "acceptProxyProtocol": true,
           "path": "/vless"
         }
       },
       "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls","quic"]
      }
    }
  ]
}
XRTLS

# // INSTALLING XHTTP NONE-TLS
cat > /usr/local/etc/xray/none.json <<XRNONE
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
     {
       "port": 8880,
       "listen": "0.0.0.0",
       "tag": "tcpnonexht",
       "protocol": "vless",
       "settings": {
         "clients": [
           {
             "email": "general@vless-tcpxht",
             "id": "${uuid}",
             "level": 0
           }
         ],
         "decryption": "none",
         "fallbacks": [
           {
             "dest": 10002,
             "xver": 0
           },
           {
             "dest": 10002,
             "path": "/xhttp",
             "xver": 0
           }
         ]
       },
       "streamSettings": {
         "network": "tcp",
         "security": "none"
       },
       "sniffing": {
         "enabled": true,
         "destOverride": ["http", "tls","quic"]
       }
     },
     {
       "port": 10002,
       "listen": "127.0.0.1",
       "tag": "xhttpnone-in",
       "protocol": "vless",
       "settings": {
          "clients": [
            {
              "email": "general@vless-xhttp",
              "id": "${uuid}",
              "level": 0
#none
            }
          ],
          "decryption": "none"
        },
        "streamSettings": {
          "network": "xhttp",
          "security": "none",
          "xhttpSettings": {
          "acceptProxyProtocol": true,
           "mode": "auto",
           "path": "/xhttp"
        }
      },
      "sniffing": {
       "enabled": true,
       "destOverride": ["http", "tls","quic"]
      }
    }
  ]
}
XRNONE

#XRAY OUTBOUND
cat > /usr/local/etc/xray/outbounds.json <<OUTB
{
  "outbounds": [
     {
       "tag": "direct",
       "protocol": "freedom",
       "settings": {
         "domainStrategy": "UseIPv4"
       }
     },
     {
       "tag": "blocked",
       "protocol": "blackhole"
     }
  ]
}
OUTB

#XRAY ROUTING
cat > /usr/local/etc/xray/routing.json <<ROUTE
{
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "outboundTag": "blocked",
        "domain": [
          "keyword:seks",
          "keyword:porn",
          "keyword:torrent",
          "keyword:tracker",
          "domain:debrid.it",
          "domain:fast.com",
          "domain:strem.fun",
          "domain:stremio.com",
          "domain:alldebrid.com",
          "domain:playstation.net",
          "domain:playstation.com",
          "domain:real-debrid.com"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "keyword:speedtest",
          "keyword:ooklaserver",
          "domain:ooklaserver.net",
          "domain:shopee.com.my"
        ]
      },
      {
        "type": "field",
        "outboundTag": "socks-dyno",
        "domain": [
          "keyword:viu",
          "keyword:hbo",
          "keyword:iqiyi",
          "keyword:lk21",
          "keyword:netflix",
          "keyword:disney",
          "keyword:hotstar",
          "keyword:primevideo"
        ]
      },
      {
        "type": "field",
        "outboundTag": "socks-dyno",
        "domain": [
          "geosite:viu",
          "geosite:hbo",
          "geosite:iqiyi",
          "geosite:netflix",
          "geosite:disney",
          "geosite:hotstar",
          "geosite:primevideo"
        ]
      },
      {
        "type": "field",
        "outboundTag": "socks-dyno",
        "domain": [
          "domain:lk21official.cc"
        ]
      },
      {
        "type": "field",
        "outboundTag": "socks-dyno",
        "domain": [
          "keyword:tv",
          "keyword:jpj",
          "keyword:ott",
          "keyword:tnb",
          "keyword:rtm",
          "keyword:iptv",
          "keyword:unifi",
          "keyword:astro",
          "keyword:myjpj",
          "keyword:tiktok",
          "keyword:loklok",
          "keyword:unifitv",
          "keyword:mytnb",
          "keyword:youtube",
          "keyword:widevine",
          "regexp:.*\\\\.my$"
        ]
      },
      {
        "type": "field",
        "outboundTag": "socks-dyno",
        "domain": [
          "geosite:tiktok",
          "geosite:akamai",
          "geosite:youtube"
        ]
      },
      {
        "type": "field",
        "outboundTag": "socks-dyno",
        "domain": [
          "domain:loklok.tv",
          "domain:bimb.com",
          "domain:loklok.com",
          "domain:g-bank.app",
          "domain:loklok.video",
          "domain:lokloktv.com",
          "domain:mygovapp.io",
          "domain:cloudfront.net",
          "domain:roboforex.com",
          "domain:amazonaws.com",
          "domain:umamusume.com"
        ]
      },
      {
        "type": "field",
        "outboundTag": "socks-dyno",
        "domain": [
          "domain:ovh.co",
          "domain:gcdn.co",
          "domain:ott-1.xyz",
          "domain:glueapi.io",
          "domain:go-ott.xyz",
          "domain:yumiki.cyou",
          "domain:thelelong.com",
          "domain:vextrionix.com",
          "domain:aethercdn.com",
          "domain:videocardz.com",
          "domain:rocket-ott.shop",
          "domain:tm.quickplay.com",
          "domain:clevertap-prod.com",
          "domain:tmcms.quickplay.com",
          "domain:secureswiftcontent.com"
        ]
      }
    ]
  }
}
ROUTE

#Remove Old Service
rm -rf /etc/systemd/system/xray.service.d
rm -rf /etc/systemd/system/xray@.service.d

#XRAY Service
cat> /etc/systemd/system/xray.service <<XRONE
[Unit]
Description=XRAY SERVICE
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
User=root
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray1 run \
  -config /usr/local/etc/xray/config.json \
  -config /usr/local/etc/xray/outbounds.json \
  -config /usr/local/etc/xray/routing.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

XRONE

#XRAY Service
cat> /etc/systemd/system/xray@.service << XRTWO
[Unit]
Description=Xray Service
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
User=root
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray2 run \
  -config /usr/local/etc/xray/%i.json \
  -config /usr/local/etc/xray/outbounds.json \
  -config /usr/local/etc/xray/routing.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

XRTWO

#XRAY LOGROTATE
cat >/etc/logrotate.d/xray <<XRLG
/var/log/xray/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    copytruncate
}
XRLG

# Set Nginx Conf
cat > /etc/nginx/nginx.conf << EOF
user www-data;
worker_processes 1;
pid /var/run/nginx.pid;
events {
	multi_accept on;
	worker_connections 1024;
}
http {
	gzip on;
	gzip_vary on;
	gzip_comp_level 5;
	gzip_types text/plain application/x-javascript text/xml text/css;
	autoindex on;
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	server_tokens off;
	include /etc/nginx/mime.types;
	default_type application/octet-stream;
	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;
	client_max_body_size 32M;
	client_header_buffer_size 8m;
	large_client_header_buffers 8 8m;
	fastcgi_buffer_size 8m;
	fastcgi_buffers 8 8m;
	fastcgi_read_timeout 600;
	#CloudFlare IPv4
	set_real_ip_from 199.27.128.0/21;
	set_real_ip_from 173.245.48.0/20;
	set_real_ip_from 103.21.244.0/22;
	set_real_ip_from 103.22.200.0/22;
	set_real_ip_from 103.31.4.0/22;
	set_real_ip_from 141.101.64.0/18;
	set_real_ip_from 108.162.192.0/18;
	set_real_ip_from 190.93.240.0/20;
	set_real_ip_from 188.114.96.0/20;
	set_real_ip_from 197.234.240.0/22;
	set_real_ip_from 198.41.128.0/17;
	set_real_ip_from 162.158.0.0/15;
	set_real_ip_from 104.16.0.0/12;
	#Incapsula
	set_real_ip_from 199.83.128.0/21;
	set_real_ip_from 198.143.32.0/19;
	set_real_ip_from 149.126.72.0/21;
	set_real_ip_from 103.28.248.0/22;
	set_real_ip_from 45.64.64.0/22;
	set_real_ip_from 185.11.124.0/22;
	set_real_ip_from 192.230.64.0/18;
	real_ip_header CF-Connecting-IP;
	include /etc/nginx/conf.d/*.conf;
}
EOF

#Nginx Webserver
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/vinstechmy/VlessWebsocket/main/OTHERS/vps.conf"

echo -e "[ ${YB}INFO${NC} ] Restart Daemon Service"
echo ""
systemctl daemon-reload
sleep 1

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

# enable nginx
echo -e "[ ${GB}OK${NC} ] Restarting Nginx Service"
systemctl restart nginx

sleep 1

# IPV4 IPTABLES
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p udp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p udp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 8880 -j ACCEPT
iptables -A INPUT -p udp --dport 8880 -j ACCEPT
iptables -P INPUT DROP
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

# IPV6 IPTABLES
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT
ip6tables -A INPUT -p udp --dport 443 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT
ip6tables -A INPUT -p udp --dport 80 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 8880 -j ACCEPT
ip6tables -A INPUT -p udp --dport 8880 -j ACCEPT
ip6tables -P INPUT DROP
ip6tables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
ip6tables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
ip6tables -A FORWARD -m string --string "find_node" --algo bm -j DROP
ip6tables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
ip6tables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
ip6tables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
ip6tables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
ip6tables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
ip6tables -A FORWARD -m string --algo bm --string "torrent" -j DROP
ip6tables -A FORWARD -m string --algo bm --string "announce" -j DROP
ip6tables -A FORWARD -m string --algo bm --string "info_hash" -j DROP

#SAVE AND APPLY DUAL IPTABLES
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

# Enable BBR
clear
echo -e "[ ${GB}INFO${NC} ] Installing TCP BBR Please Wait . . ."
echo ""
sleep 2
cat > /usr/lib/sysctl.d/10-coredump-debian.conf <<CR1
kernel.core_pattern=core
CR1

cat > /usr/lib/sysctl.d/50-default.conf <<CR2
kernel.sysrq = 0x01b6
kernel.core_uses_pid = 1

net.ipv4.conf.default.rp_filter = 2
net.ipv4.conf.*.rp_filter = 2
-net.ipv4.conf.all.rp_filter

net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.*.accept_source_route = 0
-net.ipv4.conf.all.accept_source_route

net.ipv4.conf.default.promote_secondaries = 1
net.ipv4.conf.*.promote_secondaries = 1
-net.ipv4.conf.all.promote_secondaries
-net.ipv4.ping_group_range = 0 2147483647
-net.core.default_qdisc = fq_codel

fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_regular = 2
fs.protected_fifos = 1

vm.max_map_count = 1048576
CR2

cat > /usr/lib/sysctl.d/50-pid-max.conf <<CR3
kernel.pid_max = 4194304
CR3

cat > /etc/sysctl.d/99-optimizer.conf <<-OPTI99
fs.file-max = 67108864
net.ipv4.ip_forward = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.core.netdev_max_backlog = 32768
net.core.optmem_max = 262144
net.core.somaxconn = 65536
net.core.rmem_max = 33554432
net.core.rmem_default = 1048576
net.core.wmem_max = 33554432
net.core.wmem_default = 1048576
net.ipv4.tcp_rmem = 16384 1048576 33554432
net.ipv4.tcp_wmem = 16384 1048576 33554432
net.ipv4.tcp_fin_timeout = 25
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_probes = 7
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_max_orphans = 819200
net.ipv4.tcp_max_syn_backlog = 20480
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_mem = 65536 1048576 33554432
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_notsent_lowat = 32768
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = -2
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_ecn_fallback = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.udp_mem = 65536 1048576 33554432
net.unix.max_dgram_qlen = 256
vm.min_free_kbytes = 65536
vm.swappiness = 10
vm.vfs_cache_pressure = 8192
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.neigh.default.gc_thresh1 = 512
net.ipv4.neigh.default.gc_thresh2 = 2048
net.ipv4.neigh.default.gc_interval = 30
net.ipv4.neigh.default.gc_stale_time = 60
net.ipv4.neigh.default.proxy_delay = 30
net.ipv4.conf.default.arp_filter = 2
kernel.panic = 3
vm.dirty_ratio = 20
vm.overcommit_memory = 2
vm.overcommit_ratio = 100
OPTI99

cat > /etc/sysctl.conf <<-CT5
CT5

ln -s /etc/sysctl.conf /etc/sysctl.d/99-sysctl.conf
echo -e "[ ${GB}INFO${NC} ] TCP BBR Successfully Installed !"
echo ""
sleep 2
clear

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
wget -O /usr/bin/cleanall "https://raw.githubusercontent.com/dvhcore/xrmod/main/cleaner-script/clear-cache.sh" && chmod +x /usr/bin/cleanall
wget -O /usr/bin/xp "${Git_Profile}/OTHERS/xp.sh" && chmod +x /usr/bin/xp
wget -O /usr/bin/ram "${Git_Profile}/OTHERS/ram.sh" && chmod +x /usr/bin/ram
wget -O /usr/bin/nf "https://raw.githubusercontent.com/vinstechmy/MediaUnlockerTest/main/media.sh" && chmod +x /usr/bin/nf

echo -e "[ ${GB}INFO${NC} ] Autoscript Files Successfully Download !"
echo ""
sleep 2
clear

# Crontab settings
echo "0 6 * * * root reboot" >> /etc/crontab
echo "0 5 * * * root /usr/bin/xp" >> /etc/crontab
echo "0 * * * * root /usr/bin/cleanall" >> /etc/crontab
echo "*/2 * * * * root /usr/bin/cleaner" >> /etc/crontab

#Set Log Cleaner
if [ ! -f "/etc/cron.d/cleaner" ]; then
cat> /etc/cron.d/cleaner << END
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/2 * * * * root /usr/bin/cleaner
END
fi

#Set Log Cleanall
if [ ! -f "/etc/cron.d/cleanall" ]; then
cat> /etc/cron.d/cleanall << CLALL
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 * * * * /usr/bin/cleanall
CLALL
fi

systemctl restart cron
systemctl restart sshd

#Install Chrony
apt install chrony -y

#Disable Systemd-Timesyncd
systemctl disable --now systemd-timesyncd 2>/dev/null || true
systemctl disable --now ntp 2>/dev/null || true

#Download Chrony Conf
wget -O /etc/chrony/chrony.conf "https://raw.githubusercontent.com/dvhcore/xrmod/main/time-fixer.sh" >/dev/null 2>&1

#Enable Chrony
systemctl enable chrony 2>/dev/null || true
systemctl restart chrony 2>/dev/null || true

#Verify Chrony
chronyc sources -v
chronyc tracking

#Install Rclone
apt install rclone
printf "q\n" | rclone config
wget -O /root/.config/rclone/rclone.conf "${Git_Profile}/OTHERS/rclone.conf" >/dev/null 2>&1

#Install Wondershape for limit bandwith
git clone  https://github.com/MrMan21/wondershaper.git
cd wondershaper
make install
cd
rm -rf wondershaper

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
apt autoremove --purge -y

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
    rm -r /root/xrlitedual.sh
	clear
    menu
else
    rm -r xrlitedual.sh
    reboot
fi
