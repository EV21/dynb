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

_dyn_domain=

## service provider could be inwx
_serviceProvider=

## update method options: domrobot, dyndns
_update_method=

## ip mode could be either: 4, 6 or dual for dualstack
_ip_mode=

## If you are using the DomRobot RPC-API enter your credentials for the web interface login here
## If you are using the DynDNS2 protocol enter your credentials here
_username=
_password=
## or use a token
_token=

 ## TTL (time to live) for the DNS record
 ## This setting is only relevant for API based record updates (not DnyDNS2!)
 ## minimum allowed TTL value by inwx is 300 (5 minutes)
TTL=300

## The IP-Check sites (some sites have different urls for v4 and v6)
## Pro tip: use your own ip check server for privacy
## it could be as simple as that... 
## create an index.php with <?php echo $_SERVER['REMOTE_ADDR']; ?>
_ipv4_checker=api64.ipify.org
_ipv6_checker=api64.ipify.org

_DNS_checkServer=1.1.1.1

## if you are actively using multiple network interfaces you might want to specify this
## normally the default value is okay
#_network_interface=eth0
_network_interface=

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
_interface_str=
_status=
_eventTime=0
_counter=0
_statusHostname=
_statusUsername=
_statusPassword=
_userAgent="DynB/$_version github.com/EV21/dynb"

function echoerr() { printf "%s\n" "$*" >&2; }

for i in curl jq date; do
  if ! command -v $i >/dev/null 2>&1; then
    echoerr "Error: could not find \"$i\", DynB depends on it. "
    exit 1
  fi
done
[[ -x $(command -v getopt 2> /dev/null) ]] || {
  _has_getopt=false
}

_help_message="$(cat << 'EOF'
dynb - dynamic DNS update script for bash

Usage
=====
dynb [options]

-h, --help                                displays this help message
--version                                 outputs the client version
--link                                    links to your script at ~/.local/bin/dynb
--reset                                   deletes the client blocking status file

Configuration options
---------------------
-i | --ip-mode [ 4 | 6 | dual ]           updates type A (IPv4) and AAAA (IPv6) records
-m | --update-method [dyndns | domrobot]  choose if you want to use DynDNS2 or the DomRobot RPC-API
-s | --service-provider inwx              set your provider in case you are using DynDNS2
-d | --domain "dyndns.example.com"        set the domain you want to update
-u | --username "user42"                  depends on your selected update method and your provider
-p | --password "SuperSecretPassword"     depends on your selected update method and your provider
-t | --token "YourProviderGivenToken"     depends on your selected update method and your provider


##### examples #####
dynb --ip-mode dual --update-method domrobot --domain dyndns.example.com --username user42 --password SuperSecretPassword
dynb --ip-mode dual --update-method dyndns --service-provider inwx --domain dyndns.example.com --username user42 --password SuperSecretPassword
EOF
)"

# The main domain as an identifier for the dns zone is required for the updateRecord call
function getMainDomain() {
  request=$( echo "{}" | \
      jq '(.method="nameserver.list")' | \
      jq "(.params.user=\"$_username\")" | \
      jq "(.params.pass=\"$_password\")"
    )

  response=$(curl --silent  \
      "$_interface_str" \
      --user-agent "$_userAgent" \
      --header "Content-Type: application/json" \
      --request POST $_INWX_JSON_API_URL \
      --data "$request" | jq ".resData.domains[] | select(inside(.domain=\"$_dyn_domain\"))"
    )
  _main_domain=$( echo "$response" | jq --raw-output '.domain'  )
}

function fetchDNSRecords() {
  request=$( echo "{}" | \
      jq '(.method="'nameserver.info'")' | \
      jq "(.params.user=\"$_username\")" | \
      jq "(.params.pass=\"$_password\")" | \
      jq "(.params.domain=\"$_main_domain\")" | \
      jq "(.params.name=\"$_dyn_domain\")"
    )

  response=$( curl --silent  \
      "$_interface_str" \
      --user-agent "$_userAgent" \
      --header "Content-Type: application/json" \
      --request POST $_INWX_JSON_API_URL \
      --data "$request"
    )

  _dns_records=$( echo "$response" | jq '.resData.record[]' )
}

# requires parameter A or AAAA
# result to stdout 
function getRecordID() {
  echo "$_dns_records" | jq "select(.type == \"${1}\") | .id"
}

# requires parameter A or AAAA
# result to stdout
function getDNSIP() {
  echo "$_dns_records" | jq --raw-output "select(.type == \"${1}\") | .content"
}

# requires parameter
# 1. param: 4 or 6 for ip version
# 2. param: IP check server address
# result to stdout
function getRemoteIP() {
  curl --silent "$_interface_str" --user-agent "$_userAgent" \
    --ipv"${1}" --dns-servers 1.1.1.1 --location "${2}"
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
      jq '(.method="nameserver.updateRecord")' | \
      jq "(.params.user=\"$_username\")" | \
      jq "(.params.pass=\"$_password\")" | \
      jq "(.params.id=\"$ID\")" | \
      jq "(.params.content=\"$IP\")" | \
      jq "(.params.ttl=\"$TTL\")"
    )

  response=$(curl --silent  \
      "$_interface_str" \
      --user-agent "$_userAgent" \
      --header "Content-Type: application/json" \
      --request POST $_INWX_JSON_API_URL \
      --data "$request"
     )
     echo -e "$(echo "$response" | jq --raw-output '.msg')\n Domain: $_dyn_domain\n new IPv${1}: $IP"
  fi
}

# using DynDNS2 protocol
function dynupdate() {
  myip_str=
  myipv6_str=

  INWX_DYNDNS_UPDATE_URL="https://dyndns.inwx.com/nic/update?"
  DYNV6_DYNDNS_UPDATE_URL="https://dynv6.com/api/update?zone=$_dyn_domain&token=$_token&"

  if [[ $_serviceProvider == "inwx" ]]; then
    dyndns_update_url=$INWX_DYNDNS_UPDATE_URL
    myip_str=myip
    myipv6_str=myipv6
  fi
  if [[ $_serviceProvider == "dynv6" ]]; then
    dyndns_update_url="${DYNV6_DYNDNS_UPDATE_URL}"
    myip_str=ipv4
    myipv6_str=ipv6
  fi

  if [[ $_is_IPv4_enabled == true ]] && [[ $_is_IPv6_enabled == true ]]; then
    dyndns_update_url="${dyndns_update_url}${myip_str}=${_new_IPv4}&${myipv6_str}=${_new_IPv6}"
  fi
  if [[ $_is_IPv4_enabled == true ]] && [[ $_is_IPv6_enabled == false ]]; then
    dyndns_update_url="${dyndns_update_url}${myip_str}=${_new_IPv4}"
  fi
  if [[ $_is_IPv4_enabled == false ]] && [[ $_is_IPv6_enabled == true ]]; then
    dyndns_update_url="${dyndns_update_url}${myipv6_str}=${_new_IPv6}"
  fi

  ## request ##
  if [[ $_serviceProvider == "dynv6" ]]; then
    response=$(curl --silent "$_interface_str" \
        --user-agent "$_userAgent" \
        "${dyndns_update_url}"
      )
  fi
  if [[ $_serviceProvider == "inwx" ]]; then
    response=$(curl --silent "$_interface_str" \
      --user-agent "$_userAgent" \
      --user "$_username":"$_password" \
      "${dyndns_update_url}" )
  fi

  case $response in
    good* )
      if [[ $response == "good 127.0.0.1" ]]; then
        echoerr "Error: $response: Request ignored."
      else
        echo "$response: The DynDNS update has been executed."
      fi
      return
    ;;
    nochg* )
      echo "$response: Nothing has changed, IP addresses are still up to date."
      return
    ;;
    abuse )
      echoerr "Error: $response: Username is blocked due to abuse."
      return
    ;;
    badauth ) 
      echoerr "Error: $response: Invalid username password combination."
      return
    ;;
    badagent )
      echoerr "Error: $response: Client disabled. Something is very wrong!"
      return
    ;;
    !donator )
      echoerr "Error: $response: An update request was sent, including a feature that is not available to that particular user such as offline options."
      return
    ;;
    !yours )
      echoerr "Error: $response: The domain does not belong to your user account"
      return
    ;;
    notfqdn )
      echoerr "Error: $response: Hostname $_dyn_domain is invalid"
      return
    ;;
    nohost )
      echoerr "Error: $response: Hostname supplied does not exist under specified account, enter new login credentials before performing an additional request."
      return
    ;;
    numhost )
      echoerr "Error: $response: Too many hostnames have been specified for this update"
      return
    ;;
    dnserr )
      echoerr "Error: $response: There is an internal error in the dyndns update system"
      return
    ;;
    911 )
      echoerr "Error: $response: A fatal error on provider side such as a database outage. Retry the update no sooner than 30 minutes."
      return
    ;;
    * )
      echo "$response"
      return
    ;;
  esac
  if [[ $response != good ]]; then
    setStatus "$response" "$(date +%s)" $(( _counter += 1 )) "$_dyn_domain" "${_username}${_token}"
  fi
}

function setStatus() {
  echo "_status=$1; _eventTime=$2; _counter=$3; _statusHostname=$4; _statusUsername=$5; _statusPassword=$6" > /tmp/dynb.status
}

# handle errors from past update requests
function checkStatus() {
  case $_status in
    nohost )
      if [[ "$_statusHostname" == "$_dyn_domain" && ( "$_statusUsername" == "$_username" || $_statusUsername == "$_token" ) ]]; then
        echoerr "Error: Hostname supplied does not exist under specified account, enter new login credentials before performing an additional request."
        exit 1
      else
        rm "$FILE_STATUS"
      fi
      return
    ;;
    badauth )
      if [[ "$_statusUsername" == "$_username" && "$_statusPassword" == "$_password" ]]; then
        echoerr "Error: Invalid username password combination."
        exit 1
      else
        rm "$FILE_STATUS"
      fi
      return
    ;;
    badagent )
      echoerr "Error: Client is deactivated by provider."
      echo "Fix your config and then manually remove $FILE_STATUS to reset the client blockade"
      exit 1
      return
    ;;
    !donator )
      echoerr "Error: An update request was sent, including a feature that is not available to that particular user such as offline options."
      echo "Fix your config and then manually remove $FILE_STATUS to reset the client blockade"
      exit 1
      return
    ;;
    abuse )
      echoerr "Error: Username is blocked due to abuse."
      echo "Fix your config and then manually remove $FILE_STATUS to reset the client blockade"
      exit 1
      return
    ;;
    911 )
      delta=$(( $(date +%s) - _eventTime ))
      if [[ $delta -lt 1800 ]]; then
        echoerr "$_status: The provider currently has an fatal error. DynB will wait $(date --date=@$delta -u +%M) minutes for next update until 30 minutes have passed since last request"
        exit 1
      else
        rm "$FILE_STATUS"
      fi
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
  ARGS=$(getopt --options "hvi:,d:,m:,s:,u:,p:,t:" --longoptions "help,version,link,ip-mode:,domain:,update-method:,service-provider:,username:,password:,token:,reset" -- "$@");
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
      -t | --token )
        _token=$2
        shift 2
        ;;
      --reset )
        rm --verbose "$FILE_STATUS"
        exit 0
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

## parameters and checks

FILE_CONFIG=$(dirname "$(realpath "$0")")/.env
if test -f "$FILE_CONFIG"; then
  # shellcheck source=.env
  # shellcheck disable=SC1091
  source "$FILE_CONFIG"
fi
FILE_STATUS=/tmp/dynb.status
if test -f "$FILE_STATUS"; then
  # shellcheck disable=SC1090
  source "$FILE_STATUS"
fi

if [[ $_has_getopt == "" ]] && [[ $(uname) == Linux ]]; then
  processParameters "$@"
fi

checkDependencies

if [[ $_network_interface != "" ]]; then
  _interface_str="--interface $_network_interface"
fi

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

## execute operations

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

unset _network_interface
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
