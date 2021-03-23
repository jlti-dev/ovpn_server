IPprefix_by_netmask() {
	#function returns prefix for given netmask in arg1
	#$1 = push "route 192.168.1.1 255.255.255.255"

	echo "$1" | awk '{	
	#removing last "
	oct = substr($4, 1, length($4) - 1 )
	#Splitting string at .
	split(oct, octets,".")
	mask = 0
	for (i in octets) {
		#256 = 2^8 = max octet
		    mask += 8 - log( 256 - octets[i])/log(2);
		    #octets:
		    #255 = 0
		    #0 = 8
	    }
    # returning ip in cidr
    if (mask > 0 ){
 	   print $3 "/" mask
	}
}'
}
serverRange(){
	in="dummy $1\""
	out=$(IPprefix_by_netmask "$in")
	echo "$out"
}
rule_exists(){
	[ $# -lt 1 -o $# -gt 2 ] && {
		echo "Usage: rule_exists <rule> [table]" >&2
		return 1
	}
	local rule="$1" ; shift
	[ $# -eq 1 ] && local table="--table $2"
	iptables $table --check $rule >/dev/null 2>&1
}

chain_exists(){
	[ $# -lt 1 -o $# -gt 2 ] && { 
		echo "Usage: chain_exists <chain_name> [table]" >&2
			return 1
		}
	local chain_name="$1" ; shift
	[ $# -eq 1 ] && local table="--table $2"
	iptables $table -n --list "$chain_name" >/dev/null 2>&1
}
