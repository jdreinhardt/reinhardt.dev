FROM alpine:latest as builder

WORKDIR /app

COPY . /app

RUN apk add -U hugo && \
    hugo

FROM alpine:latest

RUN apk add -U lighttpd

COPY --from=builder /app/public* /var/www/localhost/htdocs/

CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]
