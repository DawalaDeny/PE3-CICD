FROM alpine:3.19.1
WORKDIR /mail
COPY *.sh /mail
RUN chmod a+x script.sh
RUN apk update && \
    apk upgrade && \
    apk add --no-cache bash curl jq
ENTRYPOINT ["/mail/script.sh"]