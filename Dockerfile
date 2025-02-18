#FROM alpine:latest as rsbuild
#
#RUN apk update && \
#    apk add ca-certificates cargo gcc make rust && \
#    mkdir /doh-proxy && \
#    cargo install --root /doh-proxy doh-proxy

FROM golang:alpine AS build-env

RUN apk add --no-cache git make

RUN git clone https://github.com/m13253/dns-over-https.git /src

WORKDIR /src
#ADD . /src

RUN make doh-server/doh-server


FROM alpine:3.17
#COPY --from=rsbuild /doh-proxy/bin/doh-proxy /usr/local/bin/doh-proxy
COPY --from=build-env /src/doh-server/doh-server /doh-server

RUN apk add --no-cache bind-tools dnsdist tini bash htop mtr curl unbound caddy openssl libsodium  jq
RUN apk add --no-cache py3-pip gcc make libc-dev openssl-dev python3-dev && pip install dnsdist_console && apk del gcc make openssl-dev




#RUN echo "/doh-server -conf /app/doh-server1.conf & /doh-server -conf /app/doh-server2.conf & /doh-server -conf /app/doh-server3.conf & wait;" > /launchjson.sh
#RUN chmod +x /launchjson.sh

ARG PUID=2000
ARG PGID=2000

ENV LISTEN_ADDR 0.0.0.0:4053
ENV SERVER_ADDR 127.0.0.2:53
ENV TIMEOUT 10
ENV MAX_CLIENTS 512
ENV SUBPATH /resolve

#EXPOSE 3000/tcp
EXPOSE 5353/tcp
HEALTHCHECK CMD /bin/bash -c 'curl -s 127.0.0.1:5353 |grep -e "Hello, world" -e "uptime" -q '

RUN apk add --no-cache git jq && mkdir /etc/custom && git clone https://gitlab.com/the-foundation/picoinflux-dnsdist-stats.git /etc/custom/stats && apk del git

WORKDIR /app
COPY . .
RUN chmod -R a+x /app
#RUN apk update && apk add --no-cache  libgcc libunwind 
#&& \
#    addgroup -g ${PGID} doh-proxy && \
#    adduser -H -D -u ${PUID} -G doh-proxy doh-proxy
#USER doh-proxy
#RUN echo "/usr/local/bin/doh-proxy -l $LISTEN_ADDR -c $MAX_CLIENTS -u $SERVER_ADDR -t $TIMEOUT -p $SUBPATH" > /launchjson.sh

#CMD ["/bin/sh", "-c", "/usr/local/bin/doh-proxy -l $LISTEN_ADDR -c $MAX_CLIENTS -u $SERVER_ADDR -t $TIMEOUT -p $SUBPATH"]

CMD ["/sbin/tini","/app/app.sh"]