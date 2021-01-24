#!/usr/bin/env bash

## Copyright (c) 2021 Eduard Veit
## All rights reserved. This program and the accompanying materials
## are made available under the terms of the MIT license
## which accompanies this distribution, and is available at
## https://opensource.org/licenses/MIT

_version=0.1.0

###################
## Configuration ##
###################

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

 ## TTL (time to live) minimum allowed value by inwx is 300 (5 minutes)
TTL=300

## The IP-Check sites (some sites have different urls for v4 and v6)
## pro tip: use your own ip check server for privacy
## it could be as simple as that... 
## create an index.php with <?php echo $_SERVER['REMOTE_ADDR']; ?>
_ipv4_checker=api64.ipify.org
_ipv6_checker=api64.ipify.org
_DNS_checkServer=1.1.1.1

######################################################
## You don't need to change the following variables ##
_INWX_JSON_API_URL=https://api.domrobot.com/jsonrpc/
_new_IPv4=
_new_IPv6=
_dns_records=
_main_domain=
_has_getopt=
_is_IPv4_enabled=false
_is_IPv6_enabled=false

[[ -x $(command -v jq 2> /dev/null) ]] || {
  echo "This script depends on jq and it is not available." >&2
  exit 1
}
[[ -x $(command -v curl 2> /dev/null) ]] || {
  echo "This script depends on curl and it is not available." >&2
  exit 1
}
[[ -x $(command -v getopt 2> /dev/null) ]] || {
  _has_getopt=false
}

_help_message="$(cat << 'EOF'
dynb - dynamic DNS update script for bash

Usage
-------
dynb [options]

-h, --help                                displays this help message
-i | --ip-mode [ 4 | 6 | dual ]           updates type A (IPv4) and AAAA (IPv6) records
-m | --update-method [dyndns | domrobot]  choose if you want to use DynDNS2 or the DomRobot RPC-API
-s | --service-provider inwx              set your provider in case you are using DynDNS2
-d | --domain "dyndns.example.com"        set the domain you want to update
-u | --username "user42"                  depends on your selected update method and your provider
-p | --password "SuperSecretPassword"     depends on your selected update method and your provider

##### examples #####
dynb --ip-mode dualstack --update-method domrobot --domain dyndns.example.com --username user42 --password SuperSecretPassword
dynb --ip-mode dualstack --update-method dyndns --service-provider inwx --domain dyndns.example.com --username user42 --password SuperSecretPassword
EOF
)"

# The main domain or another identifier for the zone is required for the updateRecord call
function getMainDomain() {
  request=$( echo "{}" | \
      jq '(.method="'nameserver.list'")' | \
      jq '(.params.user="'$_username'")' | \
      jq '(.params.pass="'$_password'")'
    )

  response=$(curl --silent  \
      --request POST $_INWX_JSON_API_URL \
     --header "Content-Type: application/json" \
     --data "$request" | jq '.resData.domains[] | select(inside(.domain="'"$_dyn_domain"'"))'
    )
  _main_domain=$( echo "$response" | jq --raw-output '.domain'  )
}

function fetchDNSRecords() {
  request=$( echo "{}" | \
      jq '(.method="'nameserver.info'")' | \
      jq '(.params.user="'$_username'")' | \
      jq '(.params.pass="'$_password'")' | \
      jq '(.params.domain="'"$_main_domain"'")' | \
      jq '(.params.name="'"$_dyn_domain"'")'
    )

  response=$( curl --silent  \
      --request POST $_INWX_JSON_API_URL \
     --header "Content-Type: application/json" \
     --data "$request"
    )

  _dns_records=$( echo $response | jq '.resData.record[]' )
}

# requires parameter A or AAAA
# result to stdout 
function getRecordID() {
  echo $_dns_records | jq 'select(.type == "'${1}'") | .id'
}

# requires parameter A or AAAA
# result to stdout
function getDNSIP() {
  echo $_dns_records | jq --raw-output 'select(.type == "'${1}'") | .content'
}

# requires parameter
# 1. param: 4 or 6 for ip version
# 2. param: IP check server address
# result to stdout
function getRemoteIP() {
  curl --silent --ipv${1} --dns-servers 1.1.1.1 --location ${2}
}

# requires parameter
# 1. param: 4 or 6 as ip version
function updateRecord() {
  if [[ ${1} == 4 ]]; then
    ID=$(getRecordID A)
    IP=$_new_IPv4
  fi
  if [[ ${1} == 6 ]]; then
    ID=$(getRecordID AAAA)
    IP=$_new_IPv6
  fi
  if [[ $IP != "" ]]; then
  request=$( echo "{}" | \
      jq '(.method="'nameserver.updateRecord'")' | \
      jq '(.params.user="'$_username'")' | \
      jq '(.params.pass="'$_password'")' | \
      jq '(.params.id="'$ID'")' | \
      jq '(.params.content="'$IP'")' | \
      jq '(.params.ttl="'$TTL'")'
    )
  response=$(curl --silent  \
      --request POST $_INWX_JSON_API_URL \
      --header "Content-Type: application/json" \
      --data "$request"
     )
     echo -e "$(echo "$response" | jq --raw-output '.msg')\n Domain: $_dyn_domain\n new IPv${1}: $IP"
  fi
}

# using DynDNS2 protocol
function dynupdate() {
  INWX_DYNDNS_UPDATE_URL="https://dyndns.inwx.com/nic/update?"
  if [[ $_serviceProvider == "inwx" ]]; then
    dyndns_update_url=$INWX_DYNDNS_UPDATE_URL
  fi
  if [[ $_is_IPv4_enabled == true ]] && [[ $_is_IPv6_enabled == true ]]; then
    dyndns_update_url="${dyndns_update_url}myip=${_new_IPv4}&myipv6=${_new_IPv6}"
  fi
  if [[ $_is_IPv4_enabled == true ]] && [[ $_is_IPv6_enabled == false ]]; then
    dyndns_update_url="${dyndns_update_url}myip=${_new_IPv4}"
  fi
  if [[ $_is_IPv4_enabled == false ]] && [[ $_is_IPv6_enabled == true ]]; then
    dyndns_update_url="${dyndns_update_url}myipv6=${_new_IPv6}"
  fi

  result=$(curl --silent --user $_username:$_password "${dyndns_update_url}" )
  case $result in
    good )
    echo "The DynDNS update has been executed."
    return
    ;;
    nochg )
    echo "Nothing has changed, IP addresses are still up to date."
    return
    ;;
    abuse )
    echo "You are not allowed to run this command more than once in 60 seconds."
    return
    ;;
    badauth ) 
    echo "Your username and/or password is wrong."
    return
    ;;
    !yours )
    echo "The domain does not belong to your user account"
    return
    ;;
    notfqdn )
    echo "Hostname $_dyn_domain is invalid"
    return
    ;;
    nohost )
    echo "No hostname has been specified"
    return
    ;;
    numhost )
    echo "Too many hostnames have been specified for this update"
    return
    ;;
    dnserr )
    echo "There is an internal error in the dyndns update system"
    return
    ;;
  esac
}

# requires parameter
# 1. param: 4 or 6 for IP version
function ipHasChanged() {
  if [[ ${1} == 4 ]]; then
    remote_ip=$(getRemoteIP 4 $_ipv4_checker)
    if [[ $_update_method == domrobot ]]; then
      dns_ip=$(getDNSIP A)
    else
      dns_ip=$(dig @${_DNS_checkServer} in a +short "$_dyn_domain")
    fi
  fi
  if [[ ${1} == 6 ]]; then
    remote_ip=$(getRemoteIP 6 $_ipv6_checker)
    if [[ $_update_method == domrobot ]]; then
      dns_ip=$(getDNSIP AAAA)
    else
      dns_ip=$(dig @${_DNS_checkServer} in aaaa +short "$_dyn_domain")
    fi
  fi

  if [[ "$remote_ip" == "$dns_ip" ]]; then
    return 0
  else
    if [[ ${1} == 4 ]]; then
      _new_IPv4=$remote_ip
      #echo "New IPv4: $_new_IPv4 old was: $dns_ip"
    else
      _new_IPv6=$remote_ip
      #echo "New IPv6: $_new_IPv6 old was: $dns_ip"
    fi
    return 1
  fi
}

###############
## arguments ##
###############

ARGS=
if [[ $_has_getopt == "" ]] && [[ $(uname) == Linux ]]; then
  ARGS=$(getopt --options "hvi:,d:,m:,s:,u:,p:" --longoptions "help,version,link,ip-mode:,domain:,update-method:,service-provider:,username:,password:" -- "$@");
fi
eval set -- "$ARGS";
unset ARGS

function processParameters() {
  while true; do
    case $1 in
      -h | --help )
        echo "$_help_message"
        exit 0
        ;;  
      -v | --version )
        echo $_version
        exit 0
        ;;  
      --link )
        ln --verbose --symbolic "$(realpath "$0")" "$HOME/.local/bin/dynb"
        exit 0
        ;;
      -i | --ip-mode )
        _ip_mode=$2
        shift 2
        ;;
      -d | --domain )
        _dyn_domain=$2
        shift 2
        ;;
      -m | --update-method )
        _update_method=$2
        shift 2
        ;;
      -s | --service-provider )
        _serviceProvider=$2
        shift 2
        ;;
      -u | --username )
        _username=$2
        shift 2
        ;;
      -p | --password )
        _password=$2
        shift 2
        ;;
      --)
        shift
        break
    esac
  done
}

##################
## dependencies ##
##################

function checkDependencies() {
  [[ -x $(command -v curl 2> /dev/null) ]] || {
    echo "This script depends on curl and it is not available." >&2
    exit 1
  }
  [[ -x $(command -v jq 2> /dev/null) ]] || {
    if [[ $_update_method != dyndns* ]]; then
      echo "This script depends on jq and it is not available." >&2
      exit 1
    fi
  }
  [[ -x $(command -v getopt 2> /dev/null) ]] || {
    _has_getopt=false
  }
}

##################
## MAIN section ##
##################

FILE=$(dirname "$0")/.env
if test -f "$FILE"; then
  # shellcheck source=.env
  # shellcheck disable=SC1091
  source "$FILE"
fi

if [[ $_has_getopt == "" ]] && [[ $(uname) == Linux ]]; then
  processParameters "$@"
fi

checkDependencies

if [[ $_ip_mode == d* ]]; then
  _is_IPv4_enabled=true
  _is_IPv6_enabled=true
fi
if [[ $_ip_mode == *4* ]]; then
  _is_IPv4_enabled=true
fi
if [[ $_ip_mode == *6* ]]; then
  _is_IPv6_enabled=true
fi

if [[ $_update_method == "domrobot" ]]; then
  getMainDomain
  fetchDNSRecords
  if [[ $_is_IPv4_enabled == true ]]; then
    ipHasChanged 4
    if [[ $? == 1 ]]; then
      updateRecord 4
    fi
  fi
  if [[ $_is_IPv6_enabled == true ]]; then
    ipHasChanged 6
    if [[ $? == 1 ]]; then
      updateRecord 6
    fi
  fi
fi

if [[ $_update_method == "dyndns" ]]; then
  changed=0
  if [[ $_is_IPv4_enabled == true ]]; then
    ipHasChanged 4
    (( changed += $? ))
  fi
  if [[ $_is_IPv6_enabled == true ]]; then
    ipHasChanged 6
    (( changed += $? ))
  fi
  if [[ $changed -gt 0 ]]; then
    dynupdate
  fi
fi

unset _DNS_checkServer
unset _dns_records
unset _dyn_domain
unset _has_getopt
unset _help_message
unset _INWX_JSON_API_URL
unset _ip_mode
unset _ipv4_checker
unset _ipv6_checker
unset _is_IPv4_enabled
unset _is_IPv6_enabled
unset _main_domain
unset _new_IPv4
unset _new_IPv6
unset _password
unset _username
unset _serviceProvider
unset _version

exit 0
