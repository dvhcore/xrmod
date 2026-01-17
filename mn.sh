#!/bin/bash

ALLOW_FILE="/etc/sniproxy/allow-ip.list"

flush_fw() {
    iptables -F
    iptables -X
}

apply_fw() {
    flush_fw

    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT

    # Allow established
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Allow SSH (change port if needed)
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT

    # Allow listed IPs
    while read -r ip; do
        [[ -z "$ip" ]] && continue
        iptables -A INPUT -p udp --dport 53 -s "$ip" -j ACCEPT
        iptables -A INPUT -p tcp --dport 53 -s "$ip" -j ACCEPT
        iptables -A INPUT -p tcp --dport 443 -s "$ip" -j ACCEPT
    done < "$ALLOW_FILE"

    # Drop others
    iptables -A INPUT -p udp --dport 53 -j DROP
    iptables -A INPUT -p tcp --dport 53 -j DROP
    iptables -A INPUT -p tcp --dport 443 -j DROP

    iptables-save > /etc/iptables/rules.v4
}

add_ip() {
    read -p "Enter IP or CIDR: " IP
    if grep -qx "$IP" "$ALLOW_FILE"; then
        echo "IP already allowed"
    else
        echo "$IP" >> "$ALLOW_FILE"
        apply_fw
        echo "IP added & firewall updated"
    fi
}

delete_ip() {
    read -p "Enter IP or CIDR to delete: " IP
    sed -i "\|^$IP$|d" "$ALLOW_FILE"
    apply_fw
    echo "IP deleted & firewall updated"
}

list_ip() {
    echo "====== ALLOWED IPs ======"
    cat "$ALLOW_FILE"
}

check_dns_users() {
    echo "====== DNS USERS ======"
    grep "query" /var/log/dnsmasq.log | awk '{print $NF}' | sort | uniq -c | sort -nr
}

check_sni_users() {
    echo "====== SNI USERS ======"
    ss -tn sport = :443 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c
}

menu() {
    clear
    echo "==== dnsmasq + sniproxy Manager ===="
    echo "1) Add allowed IP"
    echo "2) Delete allowed IP"
    echo "3) List allowed IPs"
    echo "4) Apply firewall rules"
    echo "5) Check DNS users"
    echo "6) Check SNI users"
    echo "7) Restart services"
    echo "8) Exit"
    echo "==================================="
    read -p "Choose: " opt

    case $opt in
        1) add_ip ;;
        2) delete_ip ;;
        3) list_ip ;;
        4) apply_fw ;;
        5) check_dns_users ;;
        6) check_sni_users ;;
        7) systemctl restart dnsmasq sniproxy ;;
        8) exit ;;
        *) echo "Invalid option" ;;
    esac
}

while true; do
    menu
    read -p "Press ENTER to continue..."
done
