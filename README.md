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
<!-- /TOC -->

## ✨ Update Methods
The following update methods are currently implemented:

### APIs

* INWX.com Domrobot JSON-RPC-API  
  Limitations:
  - minimum TTL is 300 (5 minutes)

### DynDNS2

* INWX.com  
* dynv6.com
* deSEC.io (dedyn.io)

## 📦 Requirements

* `curl` - The minimum requirement for running DynDNS2 operations

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
This convenience function only works if `util-linux` is installed on your system.

## ⚙ Configuration

You can use a config in form of an `.env` file.
Or you can just use CLI parameters.

Create `.env` in the app root directory or at `~/.local/share/dynb/.env`.
```
_dyn_domain=dyndns.example.com

## service provider could be inwx
_serviceProvider=inwx

## update method options: domrobot, dyndns
_update_method=domrobot

## ip mode could be either: 4, 6 or dual for dualstack
_ip_mode=dual

## If you are using the DomRobot RPC-API enter your credentials for the web interface login here
## If you are using the DynDNS2 protocol enter your credentials here
_username=
_password=
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
To automatically call the script you can use cron.

execute :point_down:
```
crontab -e
```
then enter :point_down: to run dynb every five minutes.
```
*/5 * * * * $HOME/.local/bin/dynb >> $HOME/.local/share/dynb/dynb-cron.log
```
Note, cron typically does not use the users PATH variable.
