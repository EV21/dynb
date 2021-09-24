FROM alpine:latest
RUN \
apk update \
&& \
apk add \
bash \
curl \
jq \
bind-tools
WORKDIR /usr/src/app
COPY . .
ENTRYPOINT ["/bin/bash", "/usr/src/app/dynb.sh"]