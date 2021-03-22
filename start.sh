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
if [ -f "/docker/ca.crt" ]; then
	cmd="$cmd --ca /docker/ca.crt"
else
	echo "did not find CA certificate at /docker/ca.crt"
	exit 1
fi
if [ -f "/docker/server.crt" ]; then
	cmd="$cmd --cert /docker/server.crt"
else
	echo "did not find server certificate at /docker/server.crt"
	exit 1
fi
if [ -f "/docker/server.pem" ]; then
	cmd="$cmd --key /docker/server.pem"
else
	echo "did not find key file at /docker/server.pem"
	exit 1
fi
if [ -f "/docker/crl.pem" ]; then
	cmd="$cmd --crl-verify /docker/crl.pem"
else
	echo "not adding --crl-verify (file: /docker/crl.pem)"
fi
if [ -d "/docker/ccd" ]; then
	echo "adding client-config-dir"
	cmd="$cmd --client-config-dir /docker/ccd"
else
	echo "not adding client-config-dir (folder: /docker/ccd)"
fi
echo "Starting command build:"
echo "--------------------------------------------------"
echo "$cmd"
echo "--------------------------------------------------"

echo "parsing ovpn.conf for public routes (pushed to all clients)"
source firewall_function.sh
serverIP=$(grep "server " /docker/ovpn.conf | while read -r line ; do
	#echo "found server-line: $line"
	server=$(serverRange "$line")
	if [ "$server" == "" ]; then
		continue
	else
		#echo "Found Server (being $server)!"
		echo $server
		break
	fi
done)
echo "$serverIP"
if [ "$serverIP"  == "" ]; then
	echo "Could not verify server ip range"
	exit 1
fi
if [ "${MASQUERADE}" == "true" ]; then
	echo "Masquerading traffic"
	iptab="iptables --table nat --append POSTROUTING --source $serverIP --out-interface eth0 --jump MASQUERADE"
	echo "$iptab"
	$($iptab)
else
	echo "You can masquerade all traffic when setting environment Variable MASQUERADE"
fi
iptab="iptables --insert FORWARD --in-interface eth0 --out-interface tun0 --match state --state ESTABLISHED,RELATED --jump ACCEPT"
echo "Accepting traffic back into vpn --> As long as the vpn initiated it"
echo "$iptab"
$($iptab)
grep "push \"route" /docker/ovpn.conf | while read -r line ; do
	echo "found line: $line"
	ip=$(IPprefix_by_netmask "$line")
	echo "The parsed Ip is: $ip"
	if [ "$ip" == "" ]; then
		continue;
	fi
	iptab="iptables --insert FORWARD --source $serverIP --destination $ip --jump ACCEPT"
	echo "$iptab"
	$($iptab)
	echo "command succeeded"
done

echo "replacing current process"
exec $cmd
