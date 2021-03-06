#!/bin/sh

local INITPR TRACKER HOTSCR LOG DTUN_CONF

INITPR="dtun"
TRACKER="dtuntrack"
HOTSCR="hotplug-dtun"
DTUN_CONF="dtun"
MINTIMEOUT="3"
LOG="/usr/bin/logger"


dtun_logger()
{

 $LOG -t $1 -p $2 $3

}

dtun_runtrack()
{

	local protocol timeout remote_host dns
	
	protocol=$(uci -p /var/state get network.$1.proto) &> /dev/null

	if [ "$protocol" != "gre" ] && [ "$protocol" != "gretap" ] && [ "$protocol" != "ipip" ]; then
		dtun_logger "lib-$INITPR" error "The protocol of $1 must be IPIP or GRE"
		return 0
	fi	

	config_get timeout $1 timeout $MINTIMEOUT
	config_get remote_host $1 remote_host localhost
	config_get dns $1 dns ""

	[ -x /usr/sbin/$TRACKER ] && /usr/sbin/$TRACKER $1 $remote_host $timeout $dns &
}

dtun_stoptrack()
{
	dtun_logger "lib-$INITPR" notice "Stopping $TRACKER on $1"

	if [ -e /var/run/$TRACKER-$1.pid ]; then
                kill $(cat /var/run/$TRACKER-$1.pid) &> /dev/null
                rm /var/run/$TRACKER-$1.pid &> /dev/null
        fi
}

dtun_config_option_set()
{
	local config="$1"
	local section="$2"
	local option="$3"

	shift 3

	uci -q set $config.$section.$option="$@" > /dev/null
	ret=$?

	uci commit
	ret=$(( $ret + $? ))

	[ $ret -ne 0 ] && dtun_logger "lib-$INITPR" error "UCI returned an error applying $config.$section.$option=$@"

	return $ret

}
