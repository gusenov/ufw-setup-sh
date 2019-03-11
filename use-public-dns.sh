#!/bin/bash

set -x  # echo on


# Usage:
#  $ ./use-public-dns.sh
#  $ ./use-public-dns.sh --interface="wls1" --connection="SSID"


# Google Public DNS:

google_public_dns_ipv4_address1="8.8.8.8"
google_public_dns_ipv4_address2="8.8.4.4"

google_public_dns_ipv6_address1="2001:4860:4860::8888"
google_public_dns_ipv6_address2="2001:4860:4860::8844"


# Yandex.DNS:

# Quick and reliable DNS:

yandex_dns_ipv4_basic_preferred="77.88.8.8"
yandex_dns_ipv4_basic_alternate="77.88.8.1"

yandex_dns_ipv6_basic_preferred="2a02:6b8::feed:0ff"
yandex_dns_ipv6_basic_alternate="2a02:6b8:0:1::feed:0ff"

# Protection from virus and fraudulent content:

yandex_dns_ipv4_safe_preferred="77.88.8.88"
yandex_dns_ipv4_safe_alternate="77.88.8.2"

yandex_dns_ipv6_safe_preferred="2a02:6b8::feed:bad"
yandex_dns_ipv6_safe_alternate="2a02:6b8:0:1::feed:bad"

# Without adult content:

yandex_dns_ipv4_family_preferred="77.88.8.7"
yandex_dns_ipv4_family_alternate="77.88.8.3"

yandex_dns_ipv6_family_preferred="2a02:6b8::feed:a11"
yandex_dns_ipv6_family_alternate="2a02:6b8:0:1::feed:a11"


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
nmcli con mod "$connection_name" ipv4.dns "$google_public_dns_ipv4_address1 $google_public_dns_ipv4_address2 $yandex_dns_ipv4_basic_preferred $yandex_dns_ipv4_basic_alternate $yandex_dns_ipv4_safe_preferred $yandex_dns_ipv4_safe_alternate $yandex_dns_ipv4_family_preferred $yandex_dns_ipv4_family_alternate"

nmcli con mod "$connection_name" ipv6.ignore-auto-dns "yes"
nmcli con mod "$connection_name" ipv6.dns "$google_public_dns_ipv6_address1 $google_public_dns_ipv6_address2 $yandex_dns_ipv6_basic_preferred $yandex_dns_ipv6_basic_alternate $yandex_dns_ipv6_safe_preferred $yandex_dns_ipv6_safe_alternate $yandex_dns_ipv6_family_preferred $yandex_dns_ipv6_family_alternate"

nmcli con up "$connection_name" ifname "$interface_name"

sleep 16

show_info "$interface_name"

