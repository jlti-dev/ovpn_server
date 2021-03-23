# OpenVPN Server

This image is a small OpenVPN server instance, launching your VPN fast.
Its packed with a firewall based on iptables and can masquerade all your traffic (checkout environment Variables).
You just need to mount your files.

## Environment

### FIREWALL

If this variable is set explicitly to false (FIREWALL=false), no firewall (iptables) rules will be automatically applied.
This is not recommended.

By default, the start script will scrape the openvpn.conf for any push commands regarding routes. 
This routes will be added to the FORWARD chain of iptables by default and are for everyone.
User specific routes are configured in the ccd (client-config-dir) of OpenVPN (see Mounts).
If a file for the common_name of the certificate is found, the /docker/firewall.sh script will add a chain for the client and automatically apply rules.
Though changing of ccd files is possible at any time, we do not monitor them explicitly, so we are just doing firewall rules as they are expected at the time of connection.

Technically this is solved by adding the directive --learn-address to the openvpn run command.

### MASQUERADE

To make routing easier, you can masquerade all traffic.
So all your clients appear to surf with your ip in the vpn.
This is useful, if you have other subnets around and routing gets tricky.

This option is enabled by setting the variable explicitly to true (MASQUERADE=true).

## Mounts

### File: /docker/ca.crt

Can be mounted as read-only.

This file is the certificate of your Certificate Authority and is crucial for the image to work.

### File: /docker/crl.pem

Can be mounted as read-only.

This file is the certificate revocation list and is crucial for the image to work.

### File: /docker/server.crt

Can be mounted as read-only.

This file is your server certificate and therefor is crucial for the image to work.
It must be signed by the ca from /docker/ca.crt, however this is not checked.

### File: /docker/server.key

Can be mounted as read-only.

This file is your server private key and therefor is crucial for the image to work.

_It should be kept safe and a secret._

### File: /docker/ovpn.conf

Can be mounted as read-only.

This file is your primary config file and therefor is crucial for the image to work.

### File: /docker/ip-routes.txt

Can be mounted as read-only.

This file is a way to enable individual routing, to reach other subnets than those represented by OpenVPN.
The file is line based, each line is prefixed by "ip route". A valid line would be:

8.8.8.8 dev eth0

8.8.8.8 via 8.8.4.4

### Folder: /docker/ccd

Can be mounted as read-only.
This folder is the space of your ccd-files.
It can be omitted, if you don't use ccd at all (see FIREWALL, why you should use it).
If the folder does not exists, openvpn command will not be extended to use ccd.

### Folder: /docker/logs

Can NOT be mounted as read-only, as you want logs to be written.
This folder should have write access for nobody:nogroup.
If this folder is not provided, the firewall script will not log (so this makes only sense, when you set the FIREWALL).
The firewall will log a file for every common_name. 
