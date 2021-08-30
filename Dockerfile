FROM alpine:latest

RUN apk add --no-cache openvpn iptables openssl

WORKDIR /docker
VOLUME /docker/server

COPY *.sh /docker/
RUN chown -R nobody:nogroup /docker && chmod +x /docker/firewall.sh /docker/password.sh
CMD /bin/sh /docker/start.sh
