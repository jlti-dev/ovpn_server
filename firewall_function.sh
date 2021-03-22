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
