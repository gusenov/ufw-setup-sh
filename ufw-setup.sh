#!/bin/bash

#set -x  # echo on


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

function allow_http_and_https {
	sudo ufw allow out on "$1" from any to 0.0.0.0/0 port 80 proto tcp
	sudo ufw allow out on "$1" from any to 0.0.0.0/0 port 443 proto tcp
}

function allow_www {
	allow_google_public_dns "$1"
	allow_http_and_https "$1"
}




function for_admin {
	:
}

function for_devel_web_server {
	:
}

function for_devel {
	allow_www "$1"  # разработчику нужен доступ в интернет (DNS, HTTP, HTTPS), например, для доступа к публичным API онлайн-сервисов.
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
	allow_www "$1"
}




function deny_all {
	sudo ufw reset
	sudo ufw default deny incoming
	sudo ufw default deny outgoing
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

