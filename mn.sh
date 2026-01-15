#!/bin/bash

IPSET_NAME="sniproxy_allow"

add_ip() {
    read -p "Enter IP to allow: " IP
    ipset add $IPSET_NAME $IP -exist
    echo "✅ IP added: $IP"
}

del_ip() {
    read -p "Enter IP to delete: " IP
    ipset del $IPSET_NAME $IP 2>/dev/null
    echo "❌ IP removed: $IP"
}

check_ip() {
    read -p "Enter IP to check: " IP
    if ipset test $IPSET_NAME $IP >/dev/null 2>&1; then
        echo "✅ IP IS ALLOWED (LOGIN OK)"
    else
        echo "⛔ IP NOT ALLOWED (LOGIN FAILED)"
    fi
}

list_ip() {
    echo "📋 Allowed IPs:"
    ipset list $IPSET_NAME
}

while true; do
    clear
    echo "===== DNSMASQ + SNIPROXY MANAGER ====="
    echo "1) Add Allowed IP"
    echo "2) Delete Allowed IP"
    echo "3) Check IP Login"
    echo "4) List Allowed IPs"
    echo "5) Restart Services"
    echo "0) Exit"
    echo "====================================="
    read -p "Choose option: " opt

    case $opt in
        1) add_ip ;;
        2) del_ip ;;
        3) check_ip ;;
        4) list_ip ;;
        5)
           systemctl restart dnsmasq sniproxy
           echo "🔄 Services restarted"
           ;;
        0) exit ;;
        *) echo "❌ Invalid option" ;;
    esac
    read -p "Press Enter..."
done
