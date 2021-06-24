#/bin/sh

set -e 
echo "We will exit ungraceful in case of errors!"
echo "creating device tun0"
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
echo "device created"

echo "doing iptables policy"
iptables --policy FORWARD DROP



echo "--------------------------------------------------"
echo "building command and checking file existence"
if [ -f "/docker/ovpn.conf" ]; then
	cmd="openvpn --config /docker/ovpn.conf"
else
	echo "did not find config file at /docker/ovpn.conf"
	exit 1
fi
if [ -f "/docker/server/ca.crt" ]; then
	cmd="$cmd --ca /docker/server/ca.crt"
else
	echo "did not find CA certificate at /docker/server/ca.crt"
	exit 1
fi
if [ -f "/docker/server/server.crt" ]; then
	cmd="$cmd --cert /docker/server/server.crt"
else
	echo "did not find server certificate at /docker/server/server.crt"
	exit 1
fi
if [ -f "/docker/server/server.key" ]; then
	cmd="$cmd --key /docker/server/server.key"
else
	echo "did not find key file at /docker/server/server.key"
	exit 1
fi
if [ -f "/docker/server/crl.pem" ]; then
	cmd="$cmd --crl-verify /docker/server/crl.pem"
else
	echo "not adding --crl-verify (file: /docker/server/crl.pem)"
fi
if [ -d "/docker/ccd" ]; then
	echo "adding client-config-dir"
	cmd="$cmd --client-config-dir /docker/ccd"
else
	echo "not adding client-config-dir (folder: /docker/ccd)"
fi
if [ "$FIREWALL" == "false" ]; then
	echo "You turned of the firewall. Please make sure your server is safe!"
else
	echo "Firewall is turned on."
	echo "This will cause openvpn to execute a script /docker/firewall.sh which reads the allowed routes"
	echo "from the ccd folder."
	cmd="$cmd --learn-address /docker/firewall.sh"
fi
echo "Starting command build"
echo "--------------------------------------------------"
echo "$cmd"
echo "--------------------------------------------------"

echo "parsing ovpn.conf for public routes (pushed to all clients)"
source firewall_function.sh
server=""
echo "creating tempfile for server-directive"
tmp=$(mktemp)
grep "server " /docker/ovpn.conf >> $tmp
while read -r line 
do
	echo "found server-line: $line"
	server=$(serverRange "$line")
	if [ "$server" == "" ]; then
		echo "ignoring, cidr not readable"
	else
		echo "Found Server $server"
		break
	fi
done < $tmp
echo "removing tempfile"
$(rm $tmp)
echo "$server"
if [ "$server"  == "" ]; then
	echo "Could not verify server ip range"
	exit 1
fi
echo "--------------------------------------------------"
if [ "${MASQUERADE}" == "true" ]; then
	echo "Masquerading traffic"
	iptab="iptables --table nat --append POSTROUTING --source $server --out-interface eth0 --jump MASQUERADE"
	echo "$iptab"
	$($iptab)
else
	echo "You can masquerade all traffic when setting environment Variable MASQUERADE"
fi
echo "--------------------------------------------------"
iptab="iptables --insert FORWARD --in-interface eth0 --out-interface tun0 --match conntrack --ctstate RELATED,ESTABLISHED --jump ACCEPT"
echo "Accepting traffic back into vpn --> As long as the vpn initiated it"
echo "$iptab"
$($iptab)
echo "--------------------------------------------------"
if [ "$FIREWALL" == "false" ]; then
	echo "Not doing any iptables"
else	
	echo "creating tempfile for iptables (public routes"
	tmp=$(mktemp)
	grep "push \"route" /docker/ovpn.conf >> $tmp
	while read -r line ; do
		echo "found line: $line"
		ip=$(IPprefix_by_netmask "$line")
		echo "The parsed Ip is: $ip"
		if [ "$ip" == "" ]; then
			continue;
		fi
		iptab="iptables --insert FORWARD --source $server --destination $ip --jump ACCEPT"
		echo "$iptab"
		$($iptab)
		echo "command succeeded"
	done < $tmp
	echo "removing tmp file"
	echo "--------------------------------------------------"

	echo "making iptables usable"
	iptables=$(which iptables)
	chmod u+s $iptables
	chmod +x /docker/firewall.sh
fi
if [ -f "/docker/ip-routes.txt" ]; then
	echo "--------------------------------------------------"
	echo "found /docker/ip-routes.txt"
	while read -r line ; do
		iproute="ip route add $line"
		echo "$iproute"
		$($iproute)
	done < "/docker/ip-routes.txt"
fi
echo "replacing current process"
echo "--------------------------------------------------"
echo "--------------------------------------------------"
exec $cmd
