#!/bin/bash
COLOR1='\033[0;35m'
WH='\033[0;39m'
ungu="\033[0;35m"
Xark="\033[0m"
# . Liner 
function baris_panjang() {
  echo -e "${BlueCyan} ——————————————————————————————————— ${Xark} "
}

function Sc_Credit(){
sleep 1
baris_panjang
echo -e "${ungu}  Terimakasih Telah Menggunakan ${Xark}"
echo -e "${ungu}          Script Credit DynoXray ${Xark}"
baris_panjang
exit 1
}

duration=3
frames=("██10%" "█████35%" "█████████65%" "█████████████80%" "█████████████████████90%" "█████████████████████████100%")

# Menghitung jumlah frame
num_frames=${#frames[@]}

# Menghitung jumlah iterasi
num_iterations=$((duration))

# Fungsi untuk menampilkan animasi loading berwarna

Loading_Animasi() {
    for ((i = 0; i < num_iterations; i++)); do
        clear
        index=$((i % num_frames))
        color_code=$((31 + i % 7))
echo ""
echo ""
echo ""
echo -e "\e[1;${color_code}m ${frames[$index]}\e[0m"
sleep 0.5
    done
}

# Menjalankan animasi loading

# Menampilkan pesan setelah animasi selesai
function Loading_Succes() {
clear
echo -e  "\033[5;32mSucces\033[0m"
sleep 1
clear
}
function display_header() {
    clear
    echo -e "${COLOR1}————————————————————————"
    echo -e "${WH}   All Xray User Login Account           "
    echo -e "${COLOR1}————————————————————————"
}

# Fungsi untuk menampilkan menu
function display_menu() {
    echo -e "${COLOR1}1.${WH} Refresh data akun"
    echo -e "${COLOR1}2.${WH} Keluar"
    echo -e "${COLOR1}————————————————————————"
}

# Fungsi untuk menampilkan pengguna dan IP yang login
function display_users() {
    local config_file="/usr/local/etc/xray/config.json"
    local log_file="/var/log/xray/access.log"

    if [[ ! -f "$config_file" ]]; then
        echo -e "File konfigurasi tidak ditemukan: $config_file"
        return
    fi

    if [[ ! -f "$log_file" ]]; then
        echo -e "File log tidak ditemukan: $log_file"
        return
    fi

    local data=($(grep '^#&@' "$config_file" | cut -d ' ' -f 2 | sort | uniq))
    if [ ${#data[@]} -eq 0 ]; then
        echo -e "Tidak ada akun pengguna ditemukan."
        return
    fi

    for akun in "${data[@]}"; do
        [ -z "$akun" ] && akun="Tidak Ada"

        local data2=($(tail -n 500 "$log_file" | awk '{print $3}' | sed 's/tcp://g' | cut -d ":" -f 1 | sort | uniq))

        if [ ${#data2[@]} -eq 0 ]; then
            echo -e "Tidak ada alamat IP yang ditemukan untuk pengguna $YB$akun$NC."
            continue
        fi

        echo -n > /tmp/ipxray
        echo -n > /tmp/other

        for ip in "${data2[@]}"; do
            local jum=$(grep -w "$akun" "$log_file" | tail -n 500 | awk '{print $3}' | sed 's/tcp://g' | cut -d ":" -f 1 | grep -w "$ip" | sort | uniq)
            if [[ "$jum" == "$ip" ]]; then
                echo "$jum" >> /tmp/ipxray
            else
                echo "$ip" >> /tmp/other
            fi
        done

        local jum=$(cat /tmp/ipxray)
        if [ -n "$jum" ]; then
            local jum2=$(nl < /tmp/ipxray)
            echo -e "User: $akun"
            echo -e "$jum2"
            echo -e "${COLOR1}————————————————————————"
        fi

        rm -f /tmp/ipxray /tmp/other
    done
}

# Fungsi utama
function main() {
    while true; do
        display_header
        display_users
        display_menu
        read -p "Pilih opsi [1-2]: " choice
        case $choice in
            1) ;;
            2) echo -e "Keluar..."; sleep 2 ; clear ; allxray ;;
            *) echo -e "Opsi tidak valid!"; sleep 1 ;;
        esac
    done
}
main
