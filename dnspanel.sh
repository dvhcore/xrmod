#!/bin/bash

# ===============================
# BASIC INSTALL
# ===============================
apt update -y
apt install -y curl iptables-persistent

# ===============================
# INSTALL XRAY
# ===============================
bash <(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)

mkdir -p /etc/xray
cat > /etc/xray/config.json <<EOF
{
  "inbounds": [
    {
      "port": 40000,
      "listen": "0.0.0.0",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF

systemctl enable xray
systemctl restart xray

# ===============================
# IPTABLES ROUTING
# ===============================
iptables -F
iptables -X

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow localhost
iptables -A INPUT -i lo -j ACCEPT

# Allow established
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

netfilter-persistent save
netfilter-persistent reload

# ===============================
# MENU SYSTEM
# ===============================

cat > /usr/local/bin/menu <<'EOF'
#!/bin/bash

ALLOW_FILE="/etc/allow_ip.list"
BYPASS_FILE="/etc/dnsmasq.d/bypass.conf"

menu() {
echo "===== DNS BYPASS MENU ====="
echo "1. Add Allowed IP"
echo "2. Delete Allowed IP"
echo "3. Add Bypass Domain"
echo "4. Delete Bypass Domain"
echo "5. Restart Services"
echo "0. Exit"
read -p "Choose: " opt

case $opt in

1)
read -p "Enter IP: " ip

iptables -A INPUT -s $ip -p udp --dport 53 -j ACCEPT
iptables -A INPUT -s $ip -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -s $ip -p tcp --dport 40000 -j ACCEPT

echo $ip >> $ALLOW_FILE
netfilter-persistent save
netfilter-persistent reload
;;

2)
read -p "Enter IP: " ip

iptables -D INPUT -s $ip -p udp --dport 53 -j ACCEPT
iptables -D INPUT -s $ip -p tcp --dport 53 -j ACCEPT
iptables -D INPUT -s $ip -p tcp --dport 40000 -j ACCEPT

sed -i "/$ip/d" $ALLOW_FILE
netfilter-persistent save
netfilter-persistent reload
;;

3)
read -p "Enter domain (example.com): " domain
echo "address=/$domain/bypassdomain" >> $BYPASS_FILE
systemctl restart dnsmasq
;;

4)
read -p "Enter domain: " domain
sed -i "/$domain/d" $BYPASS_FILE
systemctl restart dnsmasq
;;

5)
systemctl restart smartdns
systemctl restart sniproxy
systemctl restart xray
;;

0) exit;;

esac
}

menu
EOF

chmod +x /usr/local/bin/menu

echo "INSTALL COMPLETE"
echo "Run: menu"
