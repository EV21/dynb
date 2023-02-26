FROM alpine:3.16.4

RUN \
apk update \
&& \
apk add \
bash \
curl \
jq \
bind-tools \
tzdata

WORKDIR /usr/src/app

COPY . .

ENTRYPOINT ["/bin/bash", "/usr/src/app/dynb.sh"]

LABEL org.opencontainers.image.source="https://github.com/EV21/dynb"
LABEL org.opencontainers.image.description="DynB - dynamic DNS update client."
LABEL org.opencontainers.image.licenses="MIT"
