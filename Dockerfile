FROM alpine:latest

RUN apk add --no-cache openvpn iptables

WORKDIR /docker

COPY *.sh /docker/

CMD /bin/sh /docker/start.sh
