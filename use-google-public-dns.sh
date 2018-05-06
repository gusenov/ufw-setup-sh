#!/bin/bash

set -x  # echo on


# Usage:
#  $ ./use-google-public-dns.sh
#  $ ./use-google-public-dns.sh --interface="wls1" --connection="SSID"


interface_name="wls1"
connection_name="SSID"

for i in "$@"; do
	case $i in
		-i=*|--interface=*)
			interface_name="${i#*=}"
			shift # past argument=value
			;;
		-c=*|--connection=*)
			connection_name="${i#*=}"
			shift # past argument=value
			;;
	esac
done


function show_info {
	#nmcli device status
	nmcli device show "$1"

	#nmcli connection show
	#nmcli connection show --active

	#ip link show
}


show_info "$interface_name"

nmcli con down "$connection_name"

nmcli dev disconnect "$interface_name"

nmcli con mod "$connection_name" ipv4.ignore-auto-dns "yes"
nmcli con mod "$connection_name" ipv4.dns "8.8.8.8 8.8.4.4"

nmcli con mod "$connection_name" ipv6.ignore-auto-dns "yes"
nmcli con mod "$connection_name" ipv6.dns "2001:4860:4860::8888 2001:4860:4860::8844"

nmcli con up "$connection_name" ifname "$interface_name"

sleep 16

show_info "$interface_name"

