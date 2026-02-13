#!/bin/bash

# ===============================
# BASIC INSTALL
# ===============================
apt update -y
apt install -y dnsmasq haproxy curl ipset iptables-persistent

# ===============================
# INSTALL XRAY
# ===============================
bash <(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)

mkdir -p /etc/xray
cat > /etc/xray/config.json <<EOF
{
  "inbounds": [
    {
      "port": 1080,
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
# IPSET
# ===============================
ipset create bypass hash:ip
ipset create bypassdomain hash:ip

# ===============================
# DNSMASQ CONFIG
# ===============================
cat > /etc/dnsmasq.conf <<EOF
port=53
no-resolv
server=8.8.8.8
server=1.1.1.1

conf-dir=/etc/dnsmasq.d
EOF

mkdir -p /etc/dnsmasq.d

cat > /etc/dnsmasq.d/bypass.conf <<EOF
ipset=/netflix.com/bypassdomain
ipset=/nflxvideo.net/bypassdomain
EOF

systemctl restart dnsmasq
systemctl enable dnsmasq

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

# ===============================
# HAPROXY CONFIG
# ===============================
cat > /etc/haproxy/haproxy.cfg <<EOF
global
    daemon
    maxconn 2048

defaults
    mode tcp
    timeout connect 5s
    timeout client  1m
    timeout server  1m

frontend https
    bind *:443
    default_backend xray

backend xray
    server socks 127.0.0.1:1080
EOF

systemctl restart haproxy
systemctl enable haproxy

# ===============================
# FIREWALL BASIC
# ===============================
iptables -t mangle -N XRAY
iptables -t mangle -A PREROUTING -m set --match-set bypassdomain dst -j XRAY
iptables -t mangle -A XRAY -p tcp -j MARK --set-mark 1

ip rule add fwmark 1 table 100
ip route add default via 127.0.0.1 dev lo table 100

netfilter-persistent save

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
iptables -A INPUT -s $ip -p tcp --dport 1080 -j ACCEPT

echo $ip >> $ALLOW_FILE
netfilter-persistent save
;;

2)
read -p "Enter IP: " ip

iptables -D INPUT -s $ip -p udp --dport 53 -j ACCEPT
iptables -D INPUT -s $ip -p tcp --dport 53 -j ACCEPT
iptables -D INPUT -s $ip -p tcp --dport 1080 -j ACCEPT

sed -i "/$ip/d" $ALLOW_FILE
netfilter-persistent save
;;

3)
read -p "Enter domain (example.com): " domain
echo "ipset=/$domain/bypassdomain" >> $BYPASS_FILE
systemctl restart dnsmasq
;;

4)
read -p "Enter domain: " domain
sed -i "/$domain/d" $BYPASS_FILE
systemctl restart dnsmasq
;;

5)
systemctl restart dnsmasq
systemctl restart haproxy
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
