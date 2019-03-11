#!/bin/bash

set -x  # echo on


# Usage:

#  $ ./ufw-setup.sh
#  $ ./ufw-setup.sh --interface="wls1" --profile="host"

#  $ ./ufw-setup.sh --interface="enp0s3" --profile="devel"
#  $ ./ufw-setup.sh --interface="eth0" --profile="devel-web-server"

#  $ ./ufw-setup.sh --interface="enp0s3" --profile="surf"


interface_name="wls1"
profile_name="host"

for i in "$@"; do
	case $i in
		-i=*|--interface=*)
			interface_name="${i#*=}"
			shift # past argument=value
			;;
		-p=*|--profile=*)
			profile_name="${i#*=}"
			shift # past argument=value
			;;
	esac
done




function allow_google_public_dns {
	# https://developers.google.com/speed/public-dns/
	sudo ufw allow out on "$1" from any to 8.8.8.8 port 53 proto udp
	sudo ufw allow out on "$1" from any to 8.8.4.4 port 53 proto udp
}

function allow_yandex_dns {
	# https://dns.yandex.com/
	
	# Basic (quick and reliable DNS):
	sudo ufw allow out on "$1" from any to 77.88.8.8 port 53 proto udp
	sudo ufw allow out on "$1" from any to 77.88.8.1 port 53 proto udp
	
	# Safe (protection from virus and fraudulent content):
	sudo ufw allow out on "$1" from any to 77.88.8.88 port 53 proto udp
	sudo ufw allow out on "$1" from any to 77.88.8.2 port 53 proto udp
	
	# Family (without adult content):
	sudo ufw allow out on "$1" from any to 77.88.8.7 port 53 proto udp
	sudo ufw allow out on "$1" from any to 77.88.8.3 port 53 proto udp
}

function allow_http_and_https {
	sudo ufw allow out on "$1" from any to 0.0.0.0/0 port 80 proto tcp
	sudo ufw allow out on "$1" from any to 0.0.0.0/0 port 443 proto tcp
}

function allow_www {
	allow_google_public_dns "$1"
	allow_yandex_dns "$1"
	allow_http_and_https "$1"
}




function allow_github {
	# IP-адреса соответствующие github.com:
	#  192.30.253.112
	#  192.30.253.113
	getent hosts github.com | awk '{ print $1 }' | while read -r ip ; do
		sudo ufw allow out on "$1" from any to "$ip" port 22 proto tcp
	done
}

function allow_bitbucket {
	# IP-адреса соответствующие bitbucket.org: 
	#  18.205.93.0
	#  18.205.93.1
	#  18.205.93.2
	#  2406:da00:ff00::22c0:3470
	#  2406:da00:ff00::22c3:9b0a
	#  2406:da00:ff00::22cd:e0db
	getent ahosts bitbucket.org | awk '{ print $1 }' | sort --unique | while read -r ip ; do
		sudo ufw allow out on "$1" from any to "$ip" port 22 proto tcp
	done
}




function allow_ssh_to_virtualbox() {
	sudo ufw allow out on "$1" from 192.168.56.1 to 192.168.56.0/255.255.255.0 port 22 proto tcp
	# 1) Зайти в Менеджер сетей хоста (Host Network Manager) и создать новую сеть (network),
	#    её имя по умолчанию будет vboxnet0. Свойства:
	#     192.168.56.1 - это IPv4 адрес присваиваемый по умолчанию виртуальному адаптеру хоста.
	#     255.255.255.0 - это IPv4 маска сети (IPv4 Network Mask).
	# 2) Зайти в настройки ВМ и в разделе Сеть (Network) выбрать тип подключения 
	#    Виртуальный адаптер хоста (Host-only Adapter), а в качестве имени (name) выбрать vboxnet0.
}




function allow_my_servers() {
	my_servers_file="my-servers.csv"
	if [ -f "$my_servers_file" ]; then
		while IFS=, read -r ip_addr port_num proto_name
		do
			sudo ufw allow out on "$1" from any to $ip_addr port $port_num proto $proto_name
		done < "$my_servers_file"
	fi
}




function for_admin {
	allow_my_servers "$1"
}

function for_devel_web_server {
	:
}

function for_devel {
	allow_www "$1"  # разработчику нужен доступ в интернет (DNS, HTTP, HTTPS), например, для доступа к публичным API онлайн-сервисов.
	allow_github "$1"
}

function for_surf {
	allow_www "$1"
}

function for_vault {
	:
}

function for_work {
	:
}

function for_host {
	allow_my_servers "$1"

	allow_www "$1"
	allow_github "$1"
	allow_bitbucket "$1"
	
	allow_ssh_to_virtualbox "vboxnet0"
}




function deny_all {
	sudo ufw reset
	sudo ufw default deny incoming
	sudo ufw default deny outgoing
	
	# By default, UFW allows ping requests.
	# Deny ICMP ping requests:
	sudo sed -i '/ufw-before-input.*icmp/s/ACCEPT/DROP/g' /etc/ufw/before.rules
}
deny_all  # по умолчанию лучше запретить всё.




case "$profile_name" in
	("admin")            for_admin "$interface_name" ;;

	("devel-web-server") for_devel_web_server "$interface_name" ;;
	("devel")            for_devel "$interface_name" ;;

	("surf")             for_surf "$interface_name" ;;

	("vault")            for_vault "$interface_name" ;;

	("work")             for_work "$interface_name" ;;

	("host")             for_host "$interface_name" ;;
esac




function restart_ufw {
	sudo ufw disable
	sudo ufw enable
	sudo service ufw restart

	sudo service network-manager restart
}
restart_ufw




function show_settings {
	cat /etc/default/ufw
	sudo ufw status numbered
	sudo ufw status verbose
}
show_settings

