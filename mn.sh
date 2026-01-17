#!/bin/bash

ALLOW_FILE="/etc/sniproxy/allow-ip.list"

flush_rules() {
    iptables -F
    iptables -X
}

apply_rules() {
    flush_rules

    # Allow localhost
    iptables -A INPUT -i lo -j ACCEPT

    # Allow established
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Allow allowed IPs
    while read ip; do
        iptables -A INPUT -p udp --dport 53 -s $ip -j ACCEPT
        iptables -A INPUT -p tcp --dport 443 -s $ip -j ACCEPT
    done < "$ALLOW_FILE"

    # Drop others
    iptables -A INPUT -p udp --dport 53 -j DROP
    iptables -A INPUT -p tcp --dport 443 -j DROP
}

add_ip() {
    read -p "Enter IP or CIDR: " IP
    if grep -q "^$IP$" "$ALLOW_FILE"; then
        echo "IP already exists"
    else
        echo "$IP" >> "$ALLOW_FILE"
        apply_rules
        echo "IP added"
    fi
}

delete_ip() {
    read -p "Enter IP or CIDR to delete: " IP
    sed -i "/^$IP$/d" "$ALLOW_FILE"
    apply_rules
    echo "IP deleted"
}

list_ip() {
    echo "==== Allowed IPs ===="
    cat "$ALLOW_FILE"
}

menu() {
    clear
    echo "==== dnsmasq + sniproxy Manager ===="
    echo "1) Add allowed IP"
    echo "2) Delete allowed IP"
    echo "3) List allowed IPs"
    echo "4) Apply firewall rules"
    echo "5) Exit"
    read -p "Choose: " opt

    case $opt in
        1) add_ip ;;
        2) delete_ip ;;
        3) list_ip ;;
        4) apply_rules ;;
        5) exit ;;
    esac
}

while true; do
    menu
    read -p "Press Enter to continue..."
done
