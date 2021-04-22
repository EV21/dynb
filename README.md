# 🔃 DynB
DynB - dynamic DNS update script, written in bash

IPv4 (A) and IPv6 (AAAA) record updates are supported.
<!-- TOC -->
- [✨ Update Methods](#-update-methods)
    - [APIs](#apis)
    - [DynDNS2](#dyndns2)
- [📦 Requirements](#-requirements)
- [🚀 Installation](#-installation)
- [⚙ Configuration](#-configuration)
- [🏃 Run](#-run)
- [⏰ Cron](#-cron)
- [⏰ docker](#-docker)
<!-- /TOC -->

## ✨ Update Methods
The following update methods are currently implemented:

### APIs

* INWX.com Domrobot JSON-RPC-API  
  Limitations:
  - minimum TTL is 300 (5 minutes)

### DynDNS2

* INWX.com  
* deSEC.io (dedyn.io)  
* DuckDNS.org  
* dynv6.com  

## 📦 Requirements

* `curl` - The minimum requirement for all API requests.
* `dig` - You can get it by installing `dnsutils` (debian/ubuntu/ArchLinux), `bind-utils` (CentOS/RHEL), `bind-tools` (Alpine)

also essential if you are using other APIs:

* `jq` - Command-line JSON processor

## 🚀 Installation

Download the latest release

or simply clone this repo
```
git clone https://github.com/EV21/dynb.git
```

If you want to add the script to you PATH, run :point_down:
```
bash dynb.sh --link
```

## ⚙ Configuration

You can use a config in form of an `.env` file.
Or you can just use CLI parameters.

Create `.env` in the app root directory or at `~/.local/share/dynb/.env`.
```
DYNB_DYN_DOMAIN=dyndns.example.com

## service provider could be deSEC, duckdns, dynv6, inwx
DYNB_SERVICE_PROVIDER=inwx

## update method options: domrobot, dyndns
DYNB_UPDATE_METHOD=domrobot

## ip mode could be either: 4, 6 or dual for dualstack
DYNB_IP_MODE=64

## If you are using the DomRobot RPC-API enter your credentials for the web interface login here
## If you are using the DynDNS2 protocol enter your credentials here
DYNB_USERNAME=User42
DYNB_PASSWORD=SuperSecretPassword
## or use a token
DYNB_TOKEN=
```

## 🏃 Run

If you have a config file just run :point_down:
```
dynb
```
Alternatively you can use parameters if your system meets the relevant requirements. This example shows the long form parameter, there are also short ones.  
Call the help function :point_down:
```
dynb --help
```
```
dynb --ip-mode dualstack --update-method domrobot --domain dyndns.example.com --username user42 --password SuperSecretPassword
```
```
dynb --ip-mode dualstack --update-method dyndns --provider inwx --domain dyndns.example.com --username user42 --password SuperSecretPassword
```

## ⏰ Cron

To automatically call the script you can use either crontab or the script can also run in a loop mode.

### loop mode

Just use the parameter `--interval 60` or the environment variable `DYNB_INTERVAL=60` so the script will check every 60 seconds if it needs to do an update.

### crontab

execute :point_down:
```
crontab -e
```
then enter :point_down: to run dynb every five minutes.
```
*/5 * * * * $HOME/.local/bin/dynb >> $HOME/.local/share/dynb/dynb-cron.log
```
Note, cron typically does not use the users PATH variable.

## 🐟 docker

This is an example of a `docker-compose.yml` file. If you are using IPv6 make sure the routing works properly with your docker container.
```yaml
version: '3.4'

services:
  dynb:
    image: ev21/dynb
    container_name: dynb
    network_mode: host
    build:
      context: .
      dockerfile: ./Dockerfile
    environment:
      - DYNB_DYN_DOMAIN=dyndns.example.com
      - DYNB_SERVICE_PROVIDER=inwx
      - DYNB_UPDATE_METHOD=dyndns
      - DYNB_IP_MODE=64
      - DYNB_USERNAME=User42
      - DYNB_PASSWORD=SuperSecretPassword
      - DYNB_INTERVAL=60
```
