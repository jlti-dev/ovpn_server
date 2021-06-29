FROM alpine:latest

RUN apk add --no-cache openvpn iptables

WORKDIR /docker
VOLUME /docker/server

COPY *.sh /docker/
RUN chown -R nobody:nogroup /docker
CMD /bin/sh /docker/start.sh
