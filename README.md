# 🔃 DynB

DynB - dynamic DNS update script, written in bash

IPv4 (A) and IPv6 (AAAA) record updates are supported.

<!-- TOC -->

- [✨ Update Methods](#-update-methods)
- [📦 Requirements](#-requirements)
- [🚀 Installation](#-installation)
- [⚙ Configuration](#-configuration)
- [🏃 Run](#-run)
- [⏰ Cron](#-cron)
  - [loop mode](#loop-mode)
  - [crontab](#crontab)
- [🐟 docker](#-docker)
- [environment variables](#environment-variables)

<!-- /TOC -->

## ✨ Update Methods

The following update methods are currently implemented:

| Provider            | API                   | TTL in seconds | Credentials                                                                                  | own domain via NS record | free (sub-) domain                             |
|---------------------|-----------------------|----------------|----------------------------------------------------------------------------------------------|--------------------------|------------------------------------------------|
| INWX.com            | Domrobot JSON-RPC-API | 300            | customer login `username` & `password`. Mobile TAN (OTP) is currently not supported by DynB. | ✔️                       | ⛔ choose one of your owned domains             |
| INWX.com            | DynDNS2               | 60             | specific dyndns `username` & `password`                                                      | ✔️                       | ⛔ choose one of your owned domains per account |
| deSEC.io (dedyn.io) | DynDNS2               | 60             | `token`                                                                                      | ✔️                       | ✔️                                             |
| DuckDNS.org         | DynDNS2               | 60             | `token`                                                                                      | ⛔                        | ✔️                                             |
| dynv6.com           | DynDNS2               | 60             | `token`                                                                                      | ✔️                       | ✔️                                             |
| ddnss.de            | DynDNS2               | 10             | update key as `token`                                                                        | ⛔                        | ✔️                                             |
| IPv64.net           | DynDNS2               | 300            | `DynDNS Updatehash` as `token`                                                               | ⛔                        | ✔️                                             |

## 📦 Requirements

- `curl` - The minimum requirement for all API requests.
- `dig` - You can get it by installing `dnsutils` (debian/ubuntu/ArchLinux), `bind-utils` (CentOS/RHEL), `bind-tools` (Alpine)

also essential if you are using other APIs:

- `jq` - Command-line JSON processor

## 🚀 Installation

Download the latest release

or simply clone this repo

```shell
git clone https://github.com/EV21/dynb.git
```

If you want to add the script to you PATH, run 👇

```shell
bash dynb.sh --link
```

## ⚙ Configuration

You can use a config in form of an `.env` file.
Or you can just use CLI parameters.

Create `.env` in the app root directory or at `~/.local/share/dynb/.env`.

```bash
DYNB_DYN_DOMAIN=dyndns.example.com

## service provider could be deSEC, duckdns, dynv6, inwx
DYNB_SERVICE_PROVIDER=inwx

## update method options: domrobot, dyndns
DYNB_UPDATE_METHOD=domrobot

## ip mode could be either: 4, 6 or 64 for dualstack
DYNB_IP_MODE=64

## If you are using the DomRobot RPC-API enter your credentials for the web interface login here
## If you are using the DynDNS2 protocol enter your credentials here
DYNB_USERNAME=User42
DYNB_PASSWORD=SuperSecretPassword
## or use a token
DYNB_TOKEN=
```

## 🏃 Run

If you have a config file just run 👇

```bash
dynb
```

Alternatively you can use parameters if your system meets the relevant requirements. This example shows the long form parameter, there are also short ones.\
Call the help function 👇

```bash
dynb --help
```

```bash
dynb --ip-mode dualstack --update-method domrobot --domain dyndns.example.com --username user42 --password SuperSecretPassword
```

```bash
dynb --ip-mode dualstack --update-method dyndns --provider inwx --domain dyndns.example.com --username user42 --password SuperSecretPassword
```

## ⏰ Cron

To automatically call the script you can use either crontab or the script can also run in a loop mode.

### loop mode

Just use the parameter `--interval 60` or the environment variable `DYNB_INTERVAL=60` so the script will check every 60 seconds if it needs to do an update.

### crontab

execute 👇

```bash
crontab -e
```

then add the following line 👇 to run dynb every five minutes.

```bash
*/5 * * * * $HOME/.local/bin/dynb >> $HOME/.local/share/dynb/dynb-cron.log
```

alternative with docker and parameters::

```bash
*/5 * * * * docker run --interactive --tty --rm --network host ev21/dynb:latest --ip-mode 64 --update-method domrobot --domain dyndns.example.com --username user42 --password SuperSecretPassword
```

Note, cron typically does not use the users PATH variable.

## 🐟 docker

This is an example of a `docker-compose.yml` file. If you are using IPv6 make sure the routing works properly with your docker container. Note: [IPv6 networking](https://docs.docker.com/config/daemon/ipv6/) is only supported on Docker daemons running on Linux hosts.

```yaml
version: '3.4'

services:
  dynb:
    image: ev21/dynb
    container_name: dynb
    network_mode: host
    stdin_open: true
    tty: true
    environment:
      - DYNB_DYN_DOMAIN=dyndns.example.com
      # Providers: deSec, DuckDNS, dynv6, inwx, ddnss, ipv64
      - DYNB_SERVICE_PROVIDER=desec
      # Possible update methods are: dyndns, domrobot
      - DYNB_UPDATE_METHOD=dyndns
      # IP modes: 4 (IPv4 only), 6 (IPv6 only), 64 both
      - DYNB_IP_MODE=64
      # If your provider uses tokens use DYNB_TOKEN instead of DYNB_USERNAME and DYNB_PASSWORD
      - DYNB_USERNAME=User42
      - DYNB_PASSWORD=SuperSecretPassword
      # The interval in seconds is the time the script waits before executing it again
      - DYNB_INTERVAL=300
      # TZ: Timezone setting for correct log time
      - TZ=Europe/Berlin
      # TERM: For colorful console output (attached mode)
      - TERM=xterm-256color
```

## environment variables

| variable              | default value   | description                                                                                                    |
|-----------------------|-----------------|----------------------------------------------------------------------------------------------------------------|
| DYNB_DYN_DOMAIN       | undefined       | required; `dyndns.example.com`                                                                                 |
| DYNB_SERVICE_PROVIDER | undefined       | required; `deSEC`, `duckdns`, `dynv6`, `inwx`, `ddnss`, `ipv64`                                                |
| DYNB_UPDATE_METHOD    | undefined       | required; `dyndns` or `domrobot` (with inwx)                                                                   |
| DYNB_IP_MODE          | undefined       | required; `4`, `6` or `64` for both                                                                            |
| DYNB_USERNAME         | undefined       | the requirement depends on your provider and the update method                                                 |
| DYNB_PASSWORD         | undefined       | the requirement depends on your provider and the update method                                                 |
| DYNB_TOKEN            | undefined       | the requirement depends on your provider and the update method                                                 |
| DYNB_INTERVAL         | undefined       | without this setting the script/docker container will run one time and exits                                   |
| DYNB_DEBUG            | undefined       | more console outputs                                                                                           |
| DYNB_IPv4_CHECK_SITE  | api64.ipify.org | You need a website or Web-API that outputs your remote IP                                                      |
| DYNB_IPv6_CHECK_SITE  | api64.ipify.org | You need a website or Web-API that outputs your remote IP                                                      |
| DYNB_DNS_CHECK_SERVER | undefined       | If you are using a local DNS Resolver/Server make sure it answers with the public answer or set another server |
