#!/bin/bash

wg_awg_setup() {
    PROTOCOL_NAME=$1
    printf "\033[32;1mConfigure ${PROTOCOL_NAME}\033[0m\n"
    if [ "$PROTOCOL_NAME" = 'Wireguard' ]; then
        INTERFACE_NAME="wg0"
        CONFIG_NAME="wireguard_wg0"
        PROTO="wireguard"
        ZONE_NAME="wg"
    fi

    if [ "$PROTOCOL_NAME" = 'AmneziaWG' ]; then
        INTERFACE_NAME="awg0"
        CONFIG_NAME="amneziawg_awg0"
        PROTO="amneziawg"
        ZONE_NAME="awg"
        
        echo "Do you want to use AmneziaWG config or basic Wireguard config + automatic obfuscation?"
        echo "1) AmneziaWG"
        echo "2) Wireguard + automatic obfuscation"
        read CONFIG_TYPE
    fi

    read -r -p "Enter the private key (from [Interface]):"$'\n' WG_PRIVATE_KEY_INT

    while true; do
        read -r -p "Enter internal IP address with subnet, example 192.168.100.5/24 (from [Interface]):"$'\n' WG_IP
        if echo "$WG_IP" | egrep -oq '^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+$'; then
            break
        else
            echo "This IP is not valid. Please repeat"
        fi
    done

    read -r -p "Enter the public key (from [Peer]):"$'\n' WG_PUBLIC_KEY_INT
    read -r -p "If use PresharedKey, Enter this (from [Peer]). If your don't use leave blank:"$'\n' WG_PRESHARED_KEY_INT
    read -r -p "Enter Endpoint host without port (Domain or IP) (from [Peer]):"$'\n' WG_ENDPOINT_INT

    read -r -p "Enter Endpoint host port (from [Peer]) [51820]:"$'\n' WG_ENDPOINT_PORT_INT
    WG_ENDPOINT_PORT_INT=${WG_ENDPOINT_PORT_INT:-51820}
    if [ "$WG_ENDPOINT_PORT_INT" = '51820' ]; then
        echo $WG_ENDPOINT_PORT_INT
    fi

    if [ "$PROTOCOL_NAME" = 'AmneziaWG' ]; then
        if [ "$CONFIG_TYPE" = '1' ]; then
            read -r -p "Enter Jc value (from [Interface]):"$'\n' AWG_JC
            read -r -p "Enter Jmin value (from [Interface]):"$'\n' AWG_JMIN
            read -r -p "Enter Jmax value (from [Interface]):"$'\n' AWG_JMAX
            read -r -p "Enter S1 value (from [Interface]):"$'\n' AWG_S1
            read -r -p "Enter S2 value (from [Interface]):"$'\n' AWG_S2
            read -r -p "Enter H1 value (from [Interface]):"$'\n' AWG_H1
            read -r -p "Enter H2 value (from [Interface]):"$'\n' AWG_H2
            read -r -p "Enter H3 value (from [Interface]):"$'\n' AWG_H3
            read -r -p "Enter H4 value (from [Interface]):"$'\n' AWG_H4
        elif [ "$CONFIG_TYPE" = '2' ]; then
            #Default values to wg automatic obfuscation
            AWG_JC=4
            AWG_JMIN=40
            AWG_JMAX=70
            AWG_S1=0
            AWG_S2=0
            AWG_H1=1
            AWG_H2=2
            AWG_H3=3
            AWG_H4=4
        fi
    fi
    
    uci set network.${INTERFACE_NAME}=interface
    uci set network.${INTERFACE_NAME}.proto=$PROTO
    uci set network.${INTERFACE_NAME}.private_key=$WG_PRIVATE_KEY_INT
    uci set network.${INTERFACE_NAME}.listen_port='51821'
    uci set network.${INTERFACE_NAME}.addresses=$WG_IP

    if [ "$PROTOCOL_NAME" = 'AmneziaWG' ]; then
        uci set network.${INTERFACE_NAME}.awg_jc=$AWG_JC
        uci set network.${INTERFACE_NAME}.awg_jmin=$AWG_JMIN
        uci set network.${INTERFACE_NAME}.awg_jmax=$AWG_JMAX
        uci set network.${INTERFACE_NAME}.awg_s1=$AWG_S1
        uci set network.${INTERFACE_NAME}.awg_s2=$AWG_S2
        uci set network.${INTERFACE_NAME}.awg_h1=$AWG_H1
        uci set network.${INTERFACE_NAME}.awg_h2=$AWG_H2
        uci set network.${INTERFACE_NAME}.awg_h3=$AWG_H3
        uci set network.${INTERFACE_NAME}.awg_h4=$AWG_H4
    fi

    uci commit network
    handler_network_restart
}

check_system() {
    MODEL=$(cat /tmp/sysinfo/model)
    echo "Router model: $MODEL"

    AVAILABLE_SPACE=$(df /tmp | awk 'NR==2 {print $4}')
    REQUIRED_SPACE=1024

    echo "Available space: $((AVAILABLE_SPACE/1024))MB"
    echo "Required space: $((REQUIRED_SPACE/1024))MB"

    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        echo "Error: Insufficient space in /tmp"
        echo "Available: $((AVAILABLE_SPACE/1024))MB"
        echo "Required: $((REQUIRED_SPACE/1024))MB"
        exit 1
    fi
}

main() {
    check_system
    echo "Starting setup..."
    wg_awg_setup "AmneziaWG"
}

main
