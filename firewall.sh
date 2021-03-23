#!/bin/sh
source /docker/firewall_function.sh
add() {
	[ $# -lt 1 -o $# -gt 2 ] && {
		echo "Usage: add <ip> <common_name>"
		return 1
	}
	#IP RULES
	local chainName="chain-$1"
	local tmp=$(mktemp)
	
	echo "$(date +%T) creating and populating: $chainName"
	iptables --new $chainName
	iptables --append $chainName --jump RETURN
	iptables --insert FORWARD --source $1 --jump $chainName
	if [ -f "/docker/ccd/$2" ]; then
		echo "$(date +%T) reading /docker/ccd/$2"
		grep "push \"route" /docker/ccd/$2 > $tmp
		while read -r line ; do
			dest="$(IPprefix_by_netmask "$line")"
			if [ "$dest" == "" ]; then
				continue
			fi
			cmd="iptables --insert $chainName --source $1 --destination $dest --jump ACCEPT"
			echo "$(date +%T) $cmd"
			$($cmd)
		done < $tmp
	fi
	echo "$(date +%T) finished iptables"
}
delete() {
	chainName="chain-$1"
	rule="FORWARD --source $1 --jump $chainName"
	if chain_exists $chainName ; then
		if rule_exists "$rule" ; then
			echo "$(date +%T) Deleting chain form forward"
			echo "$(date +%T) iptables --delete $rule"
			$(iptables --delete $rule)
		fi
		echo "$(date +%T) Flushing & deleting: $chainName" 
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
		echo "Nicht erlaubte Aktion!" >> $log
		exit 1
		;;
esac
