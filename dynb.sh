#!/usr/bin/env bash

## Copyright (c) 2021 Eduard Veit
## All rights reserved. This program and the accompanying materials
## are made available under the terms of the MIT license
## which accompanies this distribution, and is available at
## https://opensource.org/licenses/MIT

###################
## Configuration ##
###################

#DYNB_DYN_DOMAIN=

## service provider could be deSEC, duckdns, dynv6, inwx
#DYNB_SERVICE_PROVIDER=

## update method options: domrobot, dyndns
#DYNB_UPDATE_METHOD=

## ip mode could be either: 4, 6 or dual for dualstack
#DYNB_IP_MODE=

## If you are using the DomRobot RPC-API enter your credentials for the web interface login here
## If you are using the DynDNS2 protocol enter your credentials here
#DYNB_USERNAME=
#DYNB_PASSWORD=
## or use a token
#DYNB_TOKEN=

## TTL (time to live) for the DNS record
## This setting is only relevant for API based record updates (not DnyDNS2!)
## minimum allowed TTL value by inwx is 300 (5 minutes)
TTL=300

## The IP-Check sites (some sites have different urls for v4 and v6)
## Pro tip: use your own ip check server for privacy
## it could be as simple as that...
## create an index.php with <?php echo $_SERVER'REMOTE_ADDR'; ?>
_ipv4_checker=api64.ipify.org
_ipv6_checker=api64.ipify.org

## An exernal DNS check server prevents wrong info from local DNS servers/resolvers
_DNS_checkServer=

## if you are actively using multiple network interfaces you might want to specify this
## normally the default value is okay
#_network_interface=eth0
_network_interface=

######################################################
## You don't need to change the following variables ##
_INWX_JSON_API_URL=https://api.domrobot.com/jsonrpc/
_internet_connectivity_test_server=https://www.google.de
_new_IPv4=
_new_IPv6=
_dns_records=
_main_domain=
_is_IPv4_enabled=false
_is_IPv6_enabled=false
_interface_str=
_status=
_eventTime=0
_errorCounter=0
_response=
_statusHostname=
_statusUsername=
_statusPassword=
_version=0.3.0
_userAgent="DynB/$_version github.com/EV21/dynb"
_configFile=$HOME/.local/share/dynb/.env
_statusFile=/tmp/dynb.status
_debug=0
_minimum_looptime=60
_loopMode=0

# Ansi color code variables
yellow_color="\e[0;33m"
green_color="\e[0;92m"
expand_bg="\e[K"
red_color_bg="\e[0;101m${expand_bg}"
bold="\e[1m"
reset_color_modification="\e[0m"

REGEX_IPv4="^(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$"
REGEX_IPv6="^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$"

function is_IPv4_address
{
  local ip=$1
  if [[ $ip =~ $REGEX_IPv4 ]]
  then return 0
  else return 1
  fi
}

function is_IPv6_address
{
  local ip=$1
  if [[ $ip =~ $REGEX_IPv6 ]]
  then return 0
  else return 1
  fi
}

function loopMode
{
  if [[ $_loopMode -eq 1 ]]
  then return 0
  else return 1
  fi
}

function debugMode
{
  if [[ $_debug -eq 1 ]]
  then return 0
  else return 1
  fi
}

function infoMessage
{
  echo -e "${green_color}$(logtime) INFO: $*${reset_color_modification}"
}

function debugMessage
{
  if debugMode
  then echo -e "${yellow_color}$(logtime) DEBUG: ${*}${reset_color_modification}"
  fi
}

function errorMessage
{
  echo -e "${red_color_bg}${bold}$(logtime) ERROR: $*${reset_color_modification}" >&2
}

function logtime
{
  LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$LOGTIME]"
}

# The main domain as an identifier for the dns zone is required for the updateRecord call
function getMainDomain
{
  request=$(
    echo "{}" |
      jq '(.method="nameserver.list")' |
      jq "(.params.user=\"$DYNB_USERNAME\")" |
      jq "(.params.pass=\"$DYNB_PASSWORD\")"
  )

  _response=$(
    curl --silent \
      "$_interface_str" \
      --user-agent "$_userAgent" \
      --header "Content-Type: application/json" \
      --request POST $_INWX_JSON_API_URL \
      --data "$request" | jq ".resData.domains[] | select(inside(.domain=\"$DYNB_DYN_DOMAIN\"))"
  )
  _main_domain=$(echo "$_response" | jq --raw-output '.domain')
}

function fetchDNSRecords
{
  request=$(
    echo "{}" |
      jq '(.method="'nameserver.info'")' |
      jq "(.params.user=\"$DYNB_USERNAME\")" |
      jq "(.params.pass=\"$DYNB_PASSWORD\")" |
      jq "(.params.domain=\"$_main_domain\")" |
      jq "(.params.name=\"$DYNB_DYN_DOMAIN\")"
  )

  _response=$(
    curl --silent \
      "$_interface_str" \
      --user-agent "$_userAgent" \
      --header "Content-Type: application/json" \
      --request POST $_INWX_JSON_API_URL \
      --data "$request"
  )

  _dns_records=$(echo "$_response" | jq '.resData.record[]')
}

# requires parameter A or AAAA
# result to stdout
function getRecordID
{
  echo "$_dns_records" |
    jq "select(.type == \"${1}\") | .id"
}

# requires parameter A or AAAA
# result to stdout
function getDNSIP() {
  echo "$_dns_records" |
    jq --raw-output "select(.type == \"${1}\") | .content"
}

# requires parameter
# 1. param: 4 or 6 for ip version
# 2. param: IP check server address
# result to stdout
function getRemoteIP
{
  local ip_version=$1
  local ip_check_server=$2
  if [[ -n $_DNS_checkServer ]]
  then
    curl --silent "$_interface_str" --user-agent "$_userAgent" \
      --ipv"${ip_version}" --dns-servers "$_DNS_checkServer" --location "${ip_check_server}"
  else
    curl --silent "$_interface_str" --user-agent "$_userAgent" \
      --ipv"${ip_version}" --location "${ip_check_server}"
  fi
  # shellcheck disable=2181
  if [[ $? -gt 0 ]]; then
    errorMessage "IPCheck (getRemoteIP ${1}) request failed"
    exit 1
  fi
}

# requires parameter
# 1. param: 4 or 6 as ip version
function updateRecord
{
  local ip_version=$1
  if [[ ${ip_version} == 4 ]]
  then
    ID=$(getRecordID A)
    IP=$_new_IPv4
  fi
  if [[ ${ip_version} == 6 ]]
  then
    ID=$(getRecordID AAAA)
    IP=$_new_IPv6
  fi
  if [[ $IP != "" ]]
  then
    request=$(
      echo "{}" |
        jq '(.method="nameserver.updateRecord")' |
        jq "(.params.user=\"$DYNB_USERNAME\")" |
        jq "(.params.pass=\"$DYNB_PASSWORD\")" |
        jq "(.params.id=\"$ID\")" |
        jq "(.params.content=\"$IP\")" |
        jq "(.params.ttl=\"$TTL\")"
    )

    _response=$(
      curl --silent \
        "$_interface_str" \
        --user-agent "$_userAgent" \
        --header "Content-Type: application/json" \
        --request POST $_INWX_JSON_API_URL \
        --data "$request"
    )
    infoMessage "$(echo "$_response" | jq --raw-output '.msg')\n Domain: $DYNB_DYN_DOMAIN\n New IPv${1}: $IP"
  fi
}

# using DynDNS2 protocol
function dynupdate
{
  # default parameter values
  myip_str=myip
  myipv6_str=myipv6

  INWX_DYNDNS_UPDATE_URL="https://dyndns.inwx.com/nic/update?"
  DESEC_DYNDNS_UPDATE_URL="https://update.dedyn.io/?"
  DUCKDNS_DYNDNS_UPDATE_URL="https://www.duckdns.org/update?domains=$DYNB_DYN_DOMAIN&token=$DYNB_TOKEN&"
  DYNV6_DYNDNS_UPDATE_URL="https://dynv6.com/api/update?zone=$DYNB_DYN_DOMAIN&token=$DYNB_TOKEN&"

  case $DYNB_SERVICE_PROVIDER in
    inwx* | INWX*)
      dyndns_update_url=$INWX_DYNDNS_UPDATE_URL
      ;;
    deSEC* | desec* | dedyn*)
      dyndns_update_url="${DESEC_DYNDNS_UPDATE_URL}"
      ;;
    dynv6*)
      dyndns_update_url="${DYNV6_DYNDNS_UPDATE_URL}"
      myip_str=ipv4
      myipv6_str=ipv6
      ;;
    DuckDNS* | duckdns*)
      dyndns_update_url="${DUCKDNS_DYNDNS_UPDATE_URL}"
      myip_str=ipv4
      myipv6_str=ipv6
      ;;
    *)
      errorMessage "$DYNB_SERVICE_PROVIDER is not supported"
      exit 1
      ;;
  esac

  # pre encode ip parameters
  if [[ $_is_IPv4_enabled == true ]] && [[ $_is_IPv6_enabled == true ]]; then
    dyndns_update_url="${dyndns_update_url}${myip_str}=${_new_IPv4}&${myipv6_str}=${_new_IPv6}"
  fi
  if [[ $_is_IPv4_enabled == true ]] && [[ $_is_IPv6_enabled == false ]]; then
    dyndns_update_url="${dyndns_update_url}${myip_str}=${_new_IPv4}"
  fi
  if [[ $_is_IPv4_enabled == false ]] && [[ $_is_IPv6_enabled == true ]]; then
    dyndns_update_url="${dyndns_update_url}${myipv6_str}=${_new_IPv6}"
  fi
  debugMessage "Update URL was: $dyndns_update_url"

  ## request ##
  case $DYNB_SERVICE_PROVIDER in
    inwx* | INWX*)
      _response=$(curl --silent "$_interface_str" \
        --user-agent "$_userAgent" \
        --user "$DYNB_USERNAME":"$DYNB_PASSWORD" \
        "${dyndns_update_url}")
      ;;
    deSEC* | desec* | dedyn*)
      _response=$(curl --silent "$_interface_str" \
        --user-agent "$_userAgent" \
        --header "Authorization: Token $DYNB_TOKEN" \
        --get --data-urlencode "hostname=$DYNB_DYN_DOMAIN" \
        "${dyndns_update_url}")
      ;;
    dynv6* | duckDNS* | duckdns*)
      _response=$(
        curl --silent "$_interface_str" \
          --user-agent "$_userAgent" \
          "${dyndns_update_url}"
      )
      ;;
  esac

  case $_response in
    good* | OK* | "addresses updated")
      if [[ $_response == "good 127.0.0.1" ]]; then
        errorMessage "$_response: Request ignored."
        return 1
      else
        infoMessage "$_response: The DynDNS update has been executed."
        _errorCounter=0
        return 0
      fi
      ;;
    nochg*)
      infoMessage "$_response: Nothing has changed, IP addresses are still up to date."
      return 1
      ;;
    abuse)
      errorMessage "$_response: Username is blocked due to abuse."
      return 1
      ;;
    badauth | 401)
      errorMessage "$_response: Invalid username password combination."
      return 1
      ;;
    badagent)
      errorMessage "$_response: Client disabled. Something is very wrong!"
      return 1
      ;;
    !donator)
      errorMessage "$_response: An update request was sent, including a feature that is not available to that particular user such as offline options."
      return 1
      ;;
    !yours)
      errorMessage "$_response: The domain does not belong to your user account"
      return 1
      ;;
    notfqdn)
      errorMessage "$_response: Hostname $DYNB_DYN_DOMAIN is invalid"
      return 1
      ;;
    nohost)
      errorMessage "$_response: Hostname supplied does not exist under specified account, enter new login credentials before performing an additional request."
      return 1
      ;;
    numhost)
      errorMessage "$_response: Too many hostnames have been specified for this update"
      return 1
      ;;
    dnserr)
      errorMessage "$_response: There is an internal error in the dyndns update system. Retry update no sooner than 30 minutes."
      return 1
      ;;
    911 | 5*)
      errorMessage "$_response: A fatal error on provider side such as a database outage. Retry update no sooner than 30 minutes."
      return 1
      ;;
    *)
      if [[ "$_response" == "$_status" ]]; then
        errorMessage "An unknown response code has been received. $_response"
        return 1
      else
        errorMessage "unknown respnse code: $_response"
        return 0
      fi
      ;;
  esac
}

function setStatus
{
  echo "_status=$1; _eventTime=$2; _errorCounter=$3; _statusHostname=$4; _statusUsername=$5; _statusPassword=$6" >/tmp/dynb.status
}

# handle errors from past update requests
function checkStatus
{
  case $_status in
    nochg*)
      if [[ _errorCounter -gt 1 ]]; then
        errorMessage "The update client was spamming unnecessary update requests, something might be wrong with your IP-Check site."
        errorMessage "Fix your config an then delete $_statusFile or restart your docker container"
        return 1
      fi
      ;;
    nohost | !yours)
      if [[ "$_statusHostname" == "$DYNB_DYN_DOMAIN" && ("$_statusUsername" == "$DYNB_USERNAME" || $_statusUsername == "$DYNB_TOKEN") ]]; then
        errorMessage "Hostname supplied does not exist under specified account, enter new login credentials before performing an additional request."
        return 1
      else rm "$_statusFile"
      fi
      return 0
      ;;
    badauth | 401)
      if [[ "$_statusUsername" == "$DYNB_USERNAME" && "$_statusPassword" == "$DYNB_PASSWORD" ]]; then
        errorMessage "Invalid username password combination."
        return 1
      else rm "$_statusFile"
      fi
      return 0
      ;;
    badagent)
      errorMessage "Client is deactivated by provider."
      echo "Fix your config and then manually remove $_statusFile to reset the client blockade."
      echo "If it still fails file an issue at github or try another client :)"
      return 1
      ;;
    !donator)
      errorMessage "An update request was sent, including a feature that is not available to that particular user such as offline options."
      echo "Fix your config and then manually remove $_statusFile to reset the client blockade"
      echo "If it still fails file an issue at github or try another client :)"
      return 1
      ;;
    abuse)
      errorMessage "Username is blocked due to abuse."
      echo "Fix your config and then manually remove $_statusFile to reset the client blockade"
      echo "If it still fails file an issue at github or try another client :)"
      return 1
      ;;
    911 | 5*)
      delta=$(($(date +%s) - _eventTime))
      if [[ $delta -lt 1800 ]]
      then
        errorMessage "$_status: The provider currently has an fatal error. DynB will wait for next update until 30 minutes have passed since last request, $(date --date=@$delta -u +%M) minutes already passed."
        return 1
      else rm "$_statusFile"
      fi
      return 0
      ;;
    *)
      if [[ _errorCounter -gt 1 ]]
      then
        errorMessage "An unknown response code has repeatedly been received. $_response"
        return 1
      else return 0
      fi
      ;;
  esac
}

# requires parameter
# 1. param: 4 or 6 for IP version
function ipHasChanged
{
  local ip_version=$1
  case ${ip_version} in
    4)
      remote_ip=$(getRemoteIP 4 $_ipv4_checker)
      if ! is_IPv4_address "$remote_ip"
      then
        errorMessage "The response from the IP check server is not an IPv4 address: $remote_ip"
        return 1
      fi
      if [[ $DYNB_UPDATE_METHOD == domrobot ]]
      then dns_ip=$(getDNSIP A)
      else
        if [[ -n $_DNS_checkServer ]]
        then dig_response=$(dig @"${_DNS_checkServer}" in a +short "$DYNB_DYN_DOMAIN")
        else dig_response=$(dig in a +short "$DYNB_DYN_DOMAIN")
        fi
        if [[ $dig_response == ";; connection timed out; no servers could be reached" ]]
        then
          errorMessage "DNS request failed $dig_response"
          return 1
        fi
        # If the dns resolver lists multiple records in the answer section we filter the first line
        # using short option "-n" and not "--lines" because of alpines limited BusyBox head command
        dns_ip=$(echo "$dig_response" | head -n 1)
      fi
      _new_IPv4=$remote_ip
      debugMessage "IPv4 from remote IP check server: $_new_IPv4, IPv4 from DNS: $dns_ip"
      ;;
    6)
      remote_ip=$(getRemoteIP 6 $_ipv6_checker)
      if ! is_IPv6_address "$remote_ip"
      then
        errorMessage "The response from the IP check server is not an IPv6 address: $remote_ip"
        return 1
      fi
      if [[ $DYNB_UPDATE_METHOD == domrobot ]]
      then dns_ip=$(getDNSIP AAAA)
      else
        if [[ -n $_DNS_checkServer ]]
        then dig_response=$(dig @"${_DNS_checkServer}" in aaaa +short "$DYNB_DYN_DOMAIN")
        else dig_response=$(dig in aaaa +short "$DYNB_DYN_DOMAIN")
        fi
        exitcode=$?
        if [[ $exitcode -gt 0 ]]
        then
          errorMessage "DNS request failed with exit code: $exitcode $dig_response"
          return 1
        fi
        # If the dns server lists multiple records in the answer section we filter the first line
        dns_ip=$(echo "$dig_response" | head -n 1)
      fi
      _new_IPv6=$remote_ip
      debugMessage "IPv6 from remote IP check server: $_new_IPv6, IPv4 from DNS: $dns_ip"
      ;;
    *) ;;
  esac

  if [[ "$remote_ip" == "$dns_ip" ]]
  then return 1
  else
    case ${ip_version} in
    4) infoMessage "New IPv4: $_new_IPv4 old was: $dns_ip";;
    6) infoMessage "New IPv6: $_new_IPv6 old was: $dns_ip";;
    esac
    return 0
  fi
}

function handleParameters
{
  # shellcheck disable=SC2154
  if [[ $_arg_version == "on" ]]
  then echo $_version; exit 0
  fi
  # shellcheck disable=SC2154
  if [[ $_arg_link == "on" ]]
  then ln --verbose --symbolic "$(realpath "$0")" "$HOME/.local/bin/dynb"; exit 0
  fi
  # shellcheck disable=SC2154
  if [[ $_arg_reset == "on" ]] && test -f "$_statusFile"
  then rm --verbose "$_statusFile"; exit 0
  fi
  # shellcheck disable=SC2154
  if [[ $_arg_debug == "on" ]]
  then _debug=1
  fi
  # shellcheck disable=SC2154
  if [[ $_arg_update_method != "" ]]
  then DYNB_UPDATE_METHOD=$_arg_update_method
  fi
  # shellcheck disable=SC2154
  if [[ $_arg_ip_mode != "" ]]
  then DYNB_IP_MODE=$_arg_ip_mode
  fi
  # shellcheck disable=SC2154
  if [[ $_arg_domain != "" ]]
  then DYNB_DYN_DOMAIN=$_arg_domain
  fi
  # shellcheck disable=SC2154
  if [[ $_arg_service_provider != "" ]]
  then DYNB_SERVICE_PROVIDER=$_arg_service_provider
  fi
  # shellcheck disable=SC2154
  if [[ $_arg_username != "" ]]
  then DYNB_USERNAME=$_arg_username
  fi
  # shellcheck disable=SC2154
  if [[ $_arg_password != "" ]]
  then DYNB_PASSWORD=$_arg_password
  fi
  # shellcheck disable=SC2154
  if [[ $_arg_token != "" ]]
  then DYNB_TOKEN=$_arg_token
  fi
  # shellcheck disable=SC2154
  if [[ $_arg_interval != "" ]]
  then DYNB_INTERVAL=$_arg_interval
  fi

  if [[ -z $DYNB_INTERVAL ]]
  then _loopMode=0
  elif [[ $DYNB_INTERVAL -lt _minimum_looptime ]]
  then
    DYNB_INTERVAL=$_minimum_looptime
    _loopMode=1
  else _loopMode=1
  fi
  if [[ $_network_interface != "" ]]
  then _interface_str="--interface $_network_interface"
  fi

  if [[ $DYNB_IP_MODE == d* ]]
  then
    _is_IPv4_enabled=true
    _is_IPv6_enabled=true
  fi
  if [[ $DYNB_IP_MODE == *4* ]]
  then _is_IPv4_enabled=true
  fi
  if [[ $DYNB_IP_MODE == *6* ]]
  then _is_IPv6_enabled=true
  fi

  if [[ $DYNB_DEBUG == true ]]
  then _debug=1
  fi
  # shellcheck disable=SC2154
  if [[ -n $DYNB_IPv4_CHECK_SITE ]]
  then _ipv4_checker=$DYNB_IPv4_CHECK_SITE
  fi
  # shellcheck disable=SC2154
  if [[ -n $DYNB_IPv6_CHECK_SITE ]]
  then _ipv6_checker=$DYNB_IPv6_CHECK_SITE
  fi
  if [[ -n $DYNB_DNS_CHECK_SERVER ]]
  then _DNS_checkServer=$DYNB_DNS_CHECK_SERVER
  fi
  return 0
}

function checkDependencies
{
  failCounter=0
  for i in curl dig; do
    if ! command -v $i >/dev/null 2>&1
    then
      errorMessage "could not find \"$i\", DynB depends on it. "
      ((failCounter++))
    fi
  done
  [[ -x $(command -v jq 2>/dev/null) ]] || {
    if [[ $DYNB_UPDATE_METHOD != dyndns* ]]
    then
      echo "This script depends on jq and it is not available." >&2
      ((failCounter++))
    fi
  }
  if [[ failCounter -gt 0 ]]
  then exit 1
  fi
}

function doUnsets
{
  unset _network_interface
  unset _DNS_checkServer
  unset _dns_records
  unset _has_getopt
  unset _help_message
  unset _INWX_JSON_API_URL
  unset _ipv4_checker
  unset _ipv6_checker
  unset _is_IPv4_enabled
  unset _is_IPv6_enabled
  unset _main_domain
  unset _new_IPv4
  unset _new_IPv6
  unset _version
  unset DYNB_DYN_DOMAIN
  unset DYNB_USERNAME
  unset DYNB_PASSWORD
  unset DYNB_TOKEN
  unset DYNB_SERVICE_PROVIDER
  unset DYNB_IP_MODE
  unset DYNB_INTERVAL
  unset DYNB_IPv4_CHECK_SITE
  unset DYNB_IPv6_CHECK_SITE
  unset DYNB_DNS_CHECK_SERVER
  unset DYNB_DEBUG
}

function doDomrobotUpdates
{
  getMainDomain
  fetchDNSRecords
  if [[ $_is_IPv4_enabled == true ]]
  then
    if ipHasChanged 4
    then updateRecord 4
    else debugMessage "Skip IPv4 record update, it is already up to date"
    fi
  fi
  if [[ $_is_IPv6_enabled == true ]]
  then
    if ipHasChanged 6
    then updateRecord 6
    else debugMessage "Skip IPv6 record update, it is already up to date"
    fi
  fi
}

function doDynDNS2Updates
{
  changed=0
  if [[ $_is_IPv4_enabled == true ]] && ipHasChanged 4
  then ((changed += 1))
  fi
  if [[ $_is_IPv6_enabled == true ]] && ipHasChanged 6
  then ((changed += 1))
  fi
  if [[ $changed -gt 0 ]]
  then
    if checkStatus
    then
      debugMessage "checkStatus has no errors, try update"
      if dynupdate
      then debugMessage "DynDNS2 update success"
      else
        debugMessage "Save new status after dynupdate has failed"
        setStatus "$_response" "$(date +%s)" $((_errorCounter += 1)) "$DYNB_DYN_DOMAIN" "${DYNB_USERNAME}" "${DYNB_PASSWORD}${DYNB_TOKEN}"
      fi
    else debugMessage "Skip DynDNS2 update, checkStatus fetched previous error."
    fi
  else debugMessage "Skip DynDNS2 update, IPs are up to date or there is a connection problem"
  fi
}

function doUpdates
{
  if [[ $DYNB_UPDATE_METHOD == "domrobot" ]]
  then doDomrobotUpdates
  elif [[ $DYNB_UPDATE_METHOD == "dyndns" ]]
  then doDynDNS2Updates
  fi
}

function ipv6_is_not_working
{
  curl --ipv6 --head --silent --max-time 5 $_internet_connectivity_test_server > /dev/null
  status_code=$?
  if test $status_code -gt 0
  then return 0
  else return 1
  fi
}

function ipv4_is_not_working
{
  curl --ipv4 --head --silent --max-time 5 $_internet_connectivity_test_server > /dev/null
  status_code=$?
  if test $status_code -gt 0
  then return 0
  else return 1
  fi
}

function check_internet_connection
{
  if [[ $_is_IPv4_enabled == true ]]
  then
    if ipv4_is_not_working
    then
      _is_IPv4_enabled="false"
      errorMessage "Your IPv4 internet connection does not work."
    fi
  fi
  if [[ $_is_IPv6_enabled == true ]]
  then
    if ipv6_is_not_working
    then
      _is_IPv6_enabled="false"
      errorMessage "Your IPv6 internet connection does not work."
    fi
  fi
}

function main
{
  # shellcheck disable=SC1091,SC1090
  source "$(dirname "$(realpath "$0")")/dynb-parsing.sh"

  # shellcheck source=.env
  if test -f "$_configFile"
  then
    # shellcheck disable=SC1091
    source "$_configFile"
  else
    alternativeConfig="$(dirname "$(realpath "$0")")/.env"
    if test -f "$alternativeConfig"
    then
      # shellcheck disable=SC1091
      source "$alternativeConfig"
    fi
  fi
  if test -f "$_statusFile"
  then
    debugMessage "read previous status file"
    # shellcheck disable=SC1090
    source "$_statusFile"
  fi

  ## parameters and checks
  handleParameters
  checkDependencies
  check_internet_connection

  if loopMode
  then
    while : 
    do
      doUpdates
      sleep $DYNB_INTERVAL
    done
  else doUpdates
  fi

  doUnsets
  return 0
}

main "${@}"
exit $?
