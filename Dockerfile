FROM alpine:3.20

RUN apk add --no-cache nfs-utils bash e2fsprogs

RUN mkdir -p /exports/app

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/nfs.img"]

EXPOSE 2049/tcp 111/tcp 111/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
