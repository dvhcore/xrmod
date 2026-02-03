#!/bin/bash

### CONFIG ###
SOCKS_PORT=10808
REDSOCKS_PORT=12345
DNS_PORT=53
IPSET_NAME=bypass
DNSMASQ_BYPASS=/etc/dnsmasq.d/bypass.conf
ALLOW_IP_LIST=/etc/dns-allow-ip.list

echo "[+] Installing packages..."
apt update
apt install -y dnsmasq redsocks ipset iptables curl unzip netfilter-persistent

### XRAY ###
echo "[+] Installing xray-core..."
bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

cat > /usr/local/etc/xray/config.json <<EOF
{
  "inbounds": [{
    "listen": "127.0.0.1",
    "port": ${SOCKS_PORT},
    "protocol": "socks",
    "settings": { "udp": false }
  }],
  "outbounds": [{
    "protocol": "freedom"
  }]
}
EOF

systemctl enable xray
systemctl restart xray

### REDSOCKS ###
cat > /etc/redsocks.conf <<EOF
base {
 log_debug = off;
 log_info = on;
 daemon = on;
 redirector = iptables;
}

redsocks {
 local_ip = 127.0.0.1;
 local_port = ${REDSOCKS_PORT};
 ip = 127.0.0.1;
 port = ${SOCKS_PORT};
 type = socks5;
}
EOF

systemctl enable redsocks
systemctl restart redsocks

### IPSET ###
ipset create ${IPSET_NAME} hash:ip timeout 0 2>/dev/null

### DNSMASQ ###
cat > /etc/dnsmasq.conf <<EOF
port=${DNS_PORT}
listen-address=0.0.0.0
bind-interfaces
domain-needed
bogus-priv
no-resolv
server=1.1.1.1
server=8.8.8.8
conf-dir=/etc/dnsmasq.d
EOF

touch ${DNSMASQ_BYPASS}
touch ${ALLOW_IP_LIST}

systemctl restart dnsmasq

### IPTABLES ###
iptables -t nat -N REDSOCKS 2>/dev/null
iptables -t nat -F REDSOCKS
iptables -t nat -A REDSOCKS -m set --match-set ${IPSET_NAME} dst -p tcp -j REDIRECT --to-ports ${REDSOCKS_PORT}
iptables -t nat -A PREROUTING -j REDSOCKS

iptables -A INPUT -p udp --dport 53 -j DROP
iptables -A INPUT -p tcp --dport 53 -j DROP

while read ip; do
  iptables -A INPUT -s $ip -p udp --dport 53 -j ACCEPT
  iptables -A INPUT -s $ip -p tcp --dport 53 -j ACCEPT
done < ${ALLOW_IP_LIST}

iptables -A INPUT -s 127.0.0.1 -p udp --dport 53 -j ACCEPT
iptables -A INPUT -s 127.0.0.1 -p tcp --dport 53 -j ACCEPT

netfilter-persistent save

### IPSET PERSIST ###
ipset save > /etc/ipset-bypass.conf

cat > /etc/systemd/system/ipset-bypass.service <<EOF
[Unit]
Before=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ipset restore < /etc/ipset-bypass.conf
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ipset-bypass

### MENU ###
cat > /usr/local/bin/dns-bypass-menu <<'EOF'
#!/bin/bash

BYPASS=/etc/dnsmasq.d/bypass.conf
ALLOW=/etc/dns-allow-ip.list
IPSET=bypass

apply_fw() {
 iptables -D INPUT -p udp --dport 53 -j DROP 2>/dev/null
 iptables -D INPUT -p tcp --dport 53 -j DROP 2>/dev/null

 iptables -A INPUT -p udp --dport 53 -j DROP
 iptables -A INPUT -p tcp --dport 53 -j DROP

 while read ip; do
  iptables -A INPUT -s $ip -p udp --dport 53 -j ACCEPT
  iptables -A INPUT -s $ip -p tcp --dport 53 -j ACCEPT
 done < $ALLOW

 iptables -A INPUT -s 127.0.0.1 -p udp --dport 53 -j ACCEPT
 iptables -A INPUT -s 127.0.0.1 -p tcp --dport 53 -j ACCEPT

 netfilter-persistent save
}

menu() {
 clear
 echo "===== DNSMASQ + REDSOCKS MENU ====="
 echo "1) Add bypass domain"
 echo "2) Delete bypass domain"
 echo "3) List bypass domains"
 echo "4) Allow VPS IP"
 echo "5) Remove VPS IP"
 echo "6) List allowed IPs"
 echo "7) Restart services"
 echo "0) Exit"
 read -p "Select: " opt

 case $opt in
 1)
  read -p "Domain: " d
  echo "ipset=/$d/$IPSET" >> $BYPASS
  systemctl restart dnsmasq
 ;;
 2)
  read -p "Domain: " d
  sed -i "/$d/d" $BYPASS
  systemctl restart dnsmasq
 ;;
 3)
  grep ipset= $BYPASS || echo "No domains"
 ;;
 4)
  read -p "VPS IP: " ip
  echo "$ip" >> $ALLOW
  apply_fw
 ;;
 5)
  read -p "VPS IP: " ip
  sed -i "/$ip/d" $ALLOW
  apply_fw
 ;;
 6)
  cat $ALLOW || echo "None"
 ;;
 7)
  systemctl restart dnsmasq
  systemctl restart redsocks
  systemctl restart xray
 ;;
 0)
  exit
 ;;
 esac

 read -p "Press Enter..."
 menu
}

menu
EOF

chmod +x /usr/local/bin/dns-bypass-menu

echo
echo "======================================"
echo " INSTALL COMPLETE"
echo "--------------------------------------"
echo " Menu : dns-bypass-menu"
echo " DNS  : This VPS IP"
echo " TCP  : redsocks only"
echo "======================================"
