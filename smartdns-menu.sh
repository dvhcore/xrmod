#!/bin/bash

CONF_DIR="/etc/smartdns"
CONF_FILE="$CONF_DIR/smartdns.conf"
ALLOW_FILE="$CONF_DIR/allowed_ips.txt"
BYPASS_FILE="$CONF_DIR/bypass_domains.conf"

install_smartdns() {
    apt update
    apt install -y smartdns iptables-persistent

    mkdir -p $CONF_DIR
    touch $ALLOW_FILE
    touch $BYPASS_FILE

    cat > $CONF_FILE <<EOF
bind :53
cache-size 4096
prefetch-domain yes
serve-expired yes
log-level info

# Default SmartDNS upstreams
server 1.1.1.1
server 9.9.9.9

# Bypass domains include
conf-file $BYPASS_FILE
EOF

    systemctl enable smartdns
    systemctl restart smartdns
    echo "✅ SmartDNS installed"
}

apply_firewall() {
    iptables -F INPUT

    iptables -A INPUT -p udp --dport 53 -j DROP
    iptables -A INPUT -p tcp --dport 53 -j DROP

    while read ip; do
        iptables -I INPUT -s $ip -p udp --dport 53 -j ACCEPT
        iptables -I INPUT -s $ip -p tcp --dport 53 -j ACCEPT
    done < $ALLOW_FILE

    netfilter-persistent save
    echo "🔥 Firewall applied"
}

add_ip() {
    read -p "Enter IP to allow: " ip
    echo "$ip" >> $ALLOW_FILE
    apply_firewall
    echo "✅ IP added"
}

remove_ip() {
    read -p "Enter IP to remove: " ip
    sed -i "/^$ip$/d" $ALLOW_FILE
    apply_firewall
    echo "❌ IP removed"
}

list_ips() {
    echo "📃 Allowed IPs:"
    cat $ALLOW_FILE
}

add_bypass_domain() {
    read -p "Enter domain to bypass (example.com): " domain
    read -p "Bypass DNS server (default 8.8.8.8): " dns
    dns=${dns:-8.8.8.8}

    echo "server $dns -domain $domain" >> $BYPASS_FILE
    systemctl restart smartdns
    echo "✅ Domain bypass added"
}

remove_bypass_domain() {
    read -p "Enter domain to remove: " domain
    sed -i "/$domain/d" $BYPASS_FILE
    systemctl restart smartdns
    echo "❌ Domain removed"
}

list_bypass_domains() {
    echo "📃 Bypass domains:"
    cat $BYPASS_FILE
}

uninstall_smartdns() {
    systemctl stop smartdns
    apt remove -y smartdns
    iptables -F
    netfilter-persistent save
    rm -rf $CONF_DIR
    echo "🗑 SmartDNS removed"
}

while true; do
    echo ""
    echo "========= SmartDNS Menu ========="
    echo "1) Install SmartDNS"
    echo "2) Add Allowed IP"
    echo "3) Remove Allowed IP"
    echo "4) List Allowed IPs"
    echo "5) Add Bypass Domain"
    echo "6) Remove Bypass Domain"
    echo "7) List Bypass Domains"
    echo "8) Apply Firewall Rules"
    echo "9) Restart SmartDNS"
    echo "0) Exit"
    echo "================================"
    read -p "Select option: " opt

    case $opt in
        1) install_smartdns ;;
        2) add_ip ;;
        3) remove_ip ;;
        4) list_ips ;;
        5) add_bypass_domain ;;
        6) remove_bypass_domain ;;
        7) list_bypass_domains ;;
        8) apply_firewall ;;
        9) systemctl restart smartdns ;;
        0) exit ;;
        *) echo "❌ Invalid option" ;;
    esac
done
