#!/bin/sh
source /docker/firewall_function.sh
if [ -d "/docker/logs" ]; then
	log="/docker/logs/$3"
	echo "$(date +[%Y-%m-%d]%T) starting protocol" >> $log
else
	log="/dev/null"
fi
add() {
	[ $# -lt 1 -o $# -gt 2 ] && {
		echo "Usage: add <ip> <common_name>"
		return 1
	}
	#IP RULES
	local chainName="chain-$1"
	local tmp=$(mktemp)
	
	echo "$(date +[%Y-%m-%d]%T) creating and populating: $chainName" >> $log
	iptables --new $chainName
	iptables --append $chainName --jump RETURN
	iptables --insert FORWARD --source $1 --jump $chainName
	if [ -f "/docker/ccd/$2" ]; then
		echo "$(date +[%Y-%m-%d]%T) reading /docker/ccd/$2" >> $log
		grep "push \"route" /docker/ccd/$2 > $tmp
		while read -r line ; do
			dest="$(IPprefix_by_netmask "$line")"
			if [ "$dest" == "" ]; then
				continue
			fi
			cmd="iptables --insert $chainName --source $1 --destination $dest --jump ACCEPT"
			echo "$(date +[%Y-%m-%d]%T) $cmd" >> $log
			$($cmd)
		done < $tmp
	fi
	echo "$(date +[%Y-%m-%d]%T) finished iptables" >> $log
}
delete() {
	chainName="chain-$1"
	rule="FORWARD --source $1 --jump $chainName"
	if chain_exists $chainName ; then
		if rule_exists "$rule" ; then
			echo "$(date +[%Y-%m-%d]%T) Deleting chain form forward" >> $log
			echo "$(date +[%Y-%m-%d]%T) iptables --delete $rule" >> $log
			$(iptables --delete $rule)
		fi
		echo "$(date +[%Y-%m-%d]%T) Flushing & deleting: $chainName" >> $log
		$(iptables --flush $chainName)
		$(iptables --delete-chain $chainName)
	fi
}
case "$1" in
	add )
		delete $2
		add $2 $3
		;;
	update )
		#IP Regeln neu aufbauen
		delete $2
		add $2 $3
		;;

	delete )
		delete $2	
		;;
	* )
		echo "$(date +[%Y-%m-%d]%T) Nicht erlaubte Aktion! - $1" >> $log
		exit 1
		;;
esac
