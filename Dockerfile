FROM alpine:3.17

RUN apk add bind-tools dnsdist tini bash htop mtr curl unbound
WORKDIR /app
COPY . .
RUN chmod -R a+x /app
EXPOSE 8053/tcp

CMD ["/sbin/tini","/app/app.sh"]
