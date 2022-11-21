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

# service provider could be deSEC, duckdns, dynv6, inwx
#DYNB_SERVICE_PROVIDER=

## update method options: domrobot, dyndns
#DYNB_UPDATE_METHOD=

# ip mode could be either: 4, 6 or dual for dualstack
#DYNB_IP_MODE=

# If you are using the DomRobot RPC-API enter your credentials for the web interface login here
# If you are using the DynDNS2 protocol enter your credentials here
#DYNB_USERNAME=
#DYNB_PASSWORD=
# or use a token
#DYNB_TOKEN=

# TTL (time to live) for the DNS record
# This setting is only relevant for API based record updates (not DnyDNS2!)
# minimum allowed TTL value by inwx is 300 (5 minutes)
TTL=300

# The IP-Check sites (some sites have different urls for v4 and v6)
# Pro tip: use your own ip check server for privacy
# it could be as simple as that...
# create an index.php with <?php echo $_SERVER'REMOTE_ADDR'; ?>
#DYNB_IPv4_CHECK_SITE=
#DYNB_IPv6_CHECK_SITE=

# An exernal DNS check server prevents wrong info from local DNS servers/resolvers
#DYNB_DNS_CHECK_SERVER=9.9.9.9

# if you are actively using multiple network interfaces you might want to specify this
# normally the default value is okay
#_network_interface=eth0
_network_interface=

######################################################
## You don't need to change the following variables ##

_INWX_JSON_API_URL=https://api.domrobot.com/jsonrpc/
_internet_connectivity_test_server=https://www.google.de
_default_check_ip_servers=("ip64.ev21.de" "api64.ipify.org" "api.my-ip.io/ip" "ip.anysrc.net/plain")
_ipv4_checker=
_ipv6_checker=
_DNS_checkServer=
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
_version=0.5.0
_userAgent="DynB/$_version github.com/EV21/dynb"
_configFile=$HOME/.local/share/dynb/.env
_statusFile=/tmp/dynb.status
_debug=false
_minimum_looptime=60
_loopMode=false
_remote_ip=
_dns_ip=
_has_remote_ip_error=
_has_remote_ip4=false
_has_remote_ip6=false

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

## is_ip_address A B
# parameters required
# 1. param: ip_version
# 2. param: ip_address
function is_ip_address
{
  local ip_version=$1
  local ip_address=$2
  case $ip_version in
    4)
      is_IPv4_address "$ip_address"
      result=$?
    ;;
    6)
      is_IPv6_address "$ip_address"
      result=$?
    ;;
  esac
  return $result
}

function loopMode
{
  if [[ $_loopMode == "true" ]]
  then return 0
  else return 1
  fi
}

function debugMode
{
  if [[ $_debug == "true" ]]
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

## getRecordID
# requires parameter A or AAAA
# result to stdout
function getRecordID
{
  echo "$_dns_records" |
    jq "select(.type == \"${1}\") | .id"
}

## do_dig_request A B
# sets variable: _dns_ip
#
# requires parameter
# 1. param: dns server address
# 2. param: A or AAAA
function do_dig_request
{
  local dns_server=$1
  local record_type=$2
  dig_response=$(dig @"$dns_server" in "$record_type" +short "$DYNB_DYN_DOMAIN")
  dig_exitcode=$?
  if [[ $dig_exitcode -gt 0 ]]
  then
    errorMessage "DNS request failed with exit code: $dig_exitcode $dig_response"
    unset _dns_ip
    return 1
  else
    case $record_type in
    A) is_ip_address 4 "$dig_response"
    ;;
    AAAA) is_ip_address 6 "$dig_response"
    ;;
    esac
    if test $? -gt 0
    then
      test -n "$dig_response" || debugMessage "dig response: $dig_response"
      unset _dns_ip
      return 1
    fi
  fi
  # If the dns resolver lists multiple records in the answer section we filter the first line
  # using short option "-n" and not "--lines" because of alpines limited BusyBox head command
  _dns_ip=$(echo "$dig_response" | head -n 1)
  return 0
}

## getDNSIP A
# sets variable: _dns_ip
#
# requires parameter
# 1. param: A or AAAA
function getDNSIP() {
  local record_type=$1
  if [[ $DYNB_UPDATE_METHOD == domrobot ]]
  then
    echo "$_dns_records" |
      jq --raw-output "select(.type == \"${record_type}\") | .content"
  else
    for current_dns_server in "${provider_dns_servers[@]}"
    do
      debugMessage "try dig DNS request with record type $record_type @$current_dns_server"
      if do_dig_request "$current_dns_server" "$record_type"
      then break
      fi
    done
  fi
}

## getRemoteIP A
# sets variable: _remote_ip,
#
# requires parameter
# 1. param: 4 or 6 for ip version
#
# result to stdout
function getRemoteIP
{
  local ip_version=$1

  if test -n "$_provider_check_ip"
  then ip_check_servers=("$_provider_check_ip" "${_default_check_ip_servers[@]}")
  fi
  case $ip_version in
    4)
      if test -n "$_ipv4_checker"
      then ip_check_servers=("$_ipv4_checker" "${_default_check_ip_servers[@]}")
      else ip_check_servers=("${_default_check_ip_servers[@]}")
      fi
    ;;
    6)
      if test -n "$_ipv6_checker"
      then ip_check_servers=("$_ipv6_checker" "${_default_check_ip_servers[@]}")
      else ip_check_servers=("${_default_check_ip_servers[@]}")
      fi
    ;;
  esac

  for current_check_server in "${ip_check_servers[@]}"
  do
    debugMessage "try getting remote IPv$ip_version via $current_check_server"
    response=$(curl --silent "$_interface_str" --user-agent "$_userAgent" \
    --ipv"${ip_version}" --location "${current_check_server}")
    curls_status_code=$?
    # shellcheck disable=2181
    if [[ $curls_status_code -gt 0 ]]
    then
      errorMessage "Remote IPv$ip_version request failed with ${current_check_server} curl status code: $curls_status_code"
      _has_remote_ip_error=true
      return_value=1
    else
      if is_ip_address "$ip_version" "$response"
      then
        _has_remote_ip_error=false
        _remote_ip="$response"
        return_value=0
        break
      else
        errorMessage "The response from the IP check server $current_check_server is not an IPv$ip_version address: $response"
        _has_remote_ip_error=true
        return_value=1
      fi
    fi
  done

  case $ip_version in
  4)
    if [[ $_has_remote_ip_error == true ]]
    then _has_remote_ip4=false
    else _has_remote_ip4=true
    fi
  ;;
  6)
    if [[ $_has_remote_ip_error == true ]]
    then export _has_remote_ip6=false
    else export _has_remote_ip6=true
    fi
  ;;
  esac
  return $return_value
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

function prepare_request_parameters
{
  # default parameter values
  ipv4_parameter_name=myip
  ipv6_parameter_name=myipv6
  curl_parameters=("--user-agent" "$_userAgent")

  case $DYNB_SERVICE_PROVIDER in
    [Ii][Nn][Ww][Xx]*)
    # inwx.de
    # in case of dualstack use you need to request both parameters with the same request
    # otherwise inwx will delete the not requested record type
      curl_parameters+=("--user" "$DYNB_USERNAME:$DYNB_PASSWORD")
      curl_parameters+=("--get") # inwx will ignore the ipv6 parameter if you don't put it into the url
      dyndns_update_url="https://dyndns.inwx.com/nic/update"
      provider_dns_servers=("ns.inwx.de" "ns2.inwx.de" "ns3.inwx.eu")
    ;;
    [Dd][Yy][Nn][Uu]*)
      curl_parameters+=("--user" "$DYNB_USERNAME:$DYNB_PASSWORD")
      curl_parameters+=("--get")
      dyndns_update_url="https://api.dynu.com/nic/update"
      provider_dns_servers=("NS11.dynu.com" "NS10.dynu.com" "NS12.dynu.com")
    ;;
    [Dd][Ee][Ss][Ee][Cc]* | [Dd][Ee][Dd][Yy][Nn]* )
    # deSEC.de / dedyn.io
      curl_parameters+=("--header" "Authorization: Token $DYNB_TOKEN")
      curl_parameters+=("--get")
      curl_parameters+=("--data-urlencode" "hostname=$DYNB_DYN_DOMAIN")
      dyndns_update_url="https://update.dedyn.io"
      provider_dns_servers=("ns1.desec.io" "ns2.desec.org")
      _provider_check_ip="https://checkip.dedyn.io" # checkipv4 and checkipv6 is also available
    ;;
    [Dd][Yy][Nn][Vv]6*)
    # dynv6.com
      ipv4_parameter_name=ipv4
      ipv6_parameter_name=ipv6
      curl_parameters+=("--get")
      curl_parameters+=("--data-urlencode" "zone=$DYNB_DYN_DOMAIN")
      curl_parameters+=("--data-urlencode" "token=$DYNB_TOKEN")
      dyndns_update_url="https://dynv6.com/api/update"
      provider_dns_servers=("ns1.dynv6.com" "ns2.dynv6.com" "ns3.dynv6.com")
    ;;
    [Dd][Uu][Cc][Kk][Dd][Nn][Ss]*)
    # DuckDNS.org
      ipv4_parameter_name=ip
      ipv6_parameter_name=ipv6
      curl_parameters+=("--get")
      curl_parameters+=("--data-urlencode" "domains=$DYNB_DYN_DOMAIN")
      curl_parameters+=("--data-urlencode" "token=$DYNB_TOKEN")
      dyndns_update_url="https://www.duckdns.org/update"
      provider_dns_servers=("ns1.duckdns.org" "ns2.duckdns.org")
    ;;
    [Dd][Dd][Nn][Ss][Ss]*)
    # ddnss.de
      ipv4_parameter_name=ip
      ipv6_parameter_name=ip6
      curl_parameters+=("--get")
      curl_parameters+=("--data-urlencode" "host=$DYNB_DYN_DOMAIN")
      curl_parameters+=("--data-urlencode" "key=$DYNB_TOKEN")
      dyndns_update_url="https://ddnss.de/upd.php"
      provider_dns_servers=("ns1.ddnss.de" "ns2.ddnss.de" "ns3.ddnss.de")
    ;;
    [Ii][Pp][Vv]64*)
    # IPv64.net
      ipv4_parameter_name=ip
      ipv6_parameter_name=ip6
      curl_parameters+=("--request" "POST")
      curl_parameters+=("--header" "Authorization: Bearer $DYNB_TOKEN")
      curl_parameters+=("--data-urlencode" "domain=$DYNB_DYN_DOMAIN")
      dyndns_update_url="https://ipv64.net/nic/update"
      provider_dns_servers=("ns1.IPv64.net" "ns2.IPv64.net")
    ;;
    *)
      errorMessage "$DYNB_SERVICE_PROVIDER is not supported"
      exit 1
    ;;
  esac
  if test -n "$_DNS_checkServer"
  then provider_dns_servers=("$_DNS_checkServer" "${provider_dns_servers[@]}")
  fi
}

function prepare_ip_flag_parameters
{
  debugMessage "IPv4 enabled: $_is_IPv4_enabled; IPv6 enabled: $_is_IPv6_enabled; has remote IPv4: $_has_remote_ip4; has remote IPv6: $_has_remote_ip6"
  if [[ $_is_IPv4_enabled == true ]] && [[ $_is_IPv6_enabled == true ]] && [[ $_has_remote_ip4 == true ]] && [[ $_has_remote_ip6 == true ]]
  then
    ip_flag_parameters=("--data-urlencode" "${ipv4_parameter_name}=${_new_IPv4}" "--data-urlencode" "${ipv6_parameter_name}=${_new_IPv6}")
  fi
  if [[ $_is_IPv4_enabled == true ]] && [[ $_is_IPv6_enabled == false ]] || [[ $_is_IPv4_enabled == true ]] && [[ $_is_IPv6_enabled == true ]] && [[ $_has_remote_ip4 == true ]] && [[ $_has_remote_ip6 == false ]]
  then
    ip_flag_parameters=("--data-urlencode" "${ipv4_parameter_name}=${_new_IPv4}")
  fi
  if [[ $_is_IPv4_enabled == false ]] && [[ $_is_IPv6_enabled == true ]] || [[ $_is_IPv4_enabled == true ]] && [[ $_is_IPv6_enabled == true ]] && [[ $_has_remote_ip4 == false ]] && [[ $_has_remote_ip6 == true ]]
  then
    ip_flag_parameters=("--data-urlencode" "${ipv6_parameter_name}=${_new_IPv6}")
  fi
}

function send_request
{
  local _response
  debugMessage "curl parameters: ${curl_parameters[*]} ${dyndns_update_url}"
  _response=$(
    curl --silent "$_interface_str" \
    "${curl_parameters[@]}" \
    "${dyndns_update_url}")
  analyse_response
  status_code=$?
  return $status_code
}

function analyse_response
{
    case $_response in
    good* | OK* | "addresses updated" | *Updated*hostname* | *'"info":"good"'*)
      if [[ $_response == "good 127.0.0.1" ]]; then
        errorMessage "$_response: Request ignored."
        return 1
      else
        infoMessage "The DynDNS update has been executed."
        debugMessage "Response: $_response"
        return 0
      fi
      ;;
    *nochg*)
      infoMessage "Nothing has changed, IP addresses are still up to date."
      debugMessage "Response: $_response"
      return 1
      ;;
    400* | *'Bad Request'*)
      errorMessage "Bad Request."
      debugMessage "Response: $_response"
      return 1
      ;;
    *'Too Many Requests'*)
      errorMessage "Too Many Request."
      debugMessage "Response: $_response"
      return 1
      ;;
    abuse)
      errorMessage "Username is blocked due to abuse."
      debugMessage "Response: $_response"
      return 1
      ;;
    *badauth* | 401 | *Unauthorized*)
      errorMessage "Invalid token or username password combination."
      debugMessage "Response: $_response"
      return 1
      ;;
    badagent)
      errorMessage "Client disabled. Something is very wrong!"
      debugMessage "Response: $_response"
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
    *nohost*)
      errorMessage "Hostname supplied does not exist under specified account, enter new login credentials before performing an additional request."
      debugMessage "Response: $_response"
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
    servererror | 911 | 5*)
      errorMessage "$_response: A fatal error on provider side such as a database outage. Retry update no sooner than 30 minutes."
      return 1
      ;;
    *)
      if [[ "$_response" == "$_status" ]]; then
        errorMessage "An unknown response code has been received: $_response"
        return 1
      else
        errorMessage "unknown respnse code: $_response"
        return 0
      fi
      ;;
  esac
}

# using DynDNS2 protocol
function dynupdate
{
  prepare_ip_flag_parameters
  curl_parameters+=("${ip_flag_parameters[@]}")
  send_request
  request_status=$?
  return $request_status
}

function setStatus
{
  echo "_status=$1; _eventTime=$2; _errorCounter=$3; _statusHostname=$4; _statusUsername=$5; _statusPassword=$6" >/tmp/dynb.status
}

# handle errors from past update requests
function checkStatus
{
  case $_status in
    *nochg*)
      if [[ _errorCounter -gt 1 ]]; then
        errorMessage "The update client was spamming unnecessary update requests, something might be wrong with your IP-Check site."
        errorMessage "Fix your config and then delete $_statusFile or restart your docker container"
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
    *badauth* | 401 | *Unauthorized*)
      if [[ "$_statusUsername" == "$DYNB_USERNAME" &&  ("$_statusPassword" == "$DYNB_PASSWORD" || $_statusPassword == "$DYNB_TOKEN") ]]; then
        errorMessage "Invalid username password combination."
        return 1
      else rm "$_statusFile"
      fi
      return 0
      ;;
    badagent)
      errorMessage "Client is deactivated by provider."
      echo "Please file an issue at GitHub or try another client :)"
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
    servererror | 911 | 5* | *'Too Many Requests'*)
      delta=$(($(date +%s) - _eventTime))
      if [[ $delta -lt 1800 ]]
      then
        errorMessage "$_status: The provider currently has an fatal error. DynB will wait for next update until 30 minutes have passed since last request, $(date --date=@$delta -u +%M) minutes already passed."
        return 1
      else rm "$_statusFile"
      fi
      return 0
      ;;
    *'Bad Request'*)
      if [[ "$_statusUsername" == "$DYNB_USERNAME" &&  ("$_statusPassword" == "$DYNB_PASSWORD" || $_statusPassword == "$DYNB_TOKEN") ]]; then
        errorMessage "Bad Request: Please check your credentials, maybe your token is invalid."
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
  getRemoteIP "$ip_version"
  if test $? -gt 0
  then return 1
  fi
  case ${ip_version} in
    4)
      getDNSIP A
      _new_IPv4=$_remote_ip
      debugMessage "IPv4 from remote IP check server: $_new_IPv4, IPv4 from DNS: $_dns_ip"
    ;;
    6)
      getDNSIP AAAA
      _new_IPv6=$_remote_ip
      debugMessage "IPv6 from remote IP check server: $_new_IPv6, IPv6 from DNS: $_dns_ip"
    ;;
  esac

  if [[ "$_remote_ip" == "$_dns_ip" ]]
  then return 1
  else
    case ${ip_version} in
    4) infoMessage "New IPv4: $_new_IPv4 old was: $_dns_ip";;
    6) infoMessage "New IPv6: $_new_IPv6 old was: $_dns_ip";;
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
  if [[ $_arg_debug == "on" ]] || [[ $DYNB_DEBUG == true ]]
  then _debug=true
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
    _loopMode=true
  else _loopMode=true
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

function delete_status_file
{
  if test -f "$_statusFile"
  then
    debugMessage "Delete status file with previous errors"
    rm "$_statusFile"
  fi
}

function doDynDNS2Updates
{
  prepare_request_parameters
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
      then
        debugMessage "DynDNS2 update success"
        delete_status_file
      else
        debugMessage "Save new status after dynupdate has failed"
        setStatus "$_response" "$(date +%s)" $((_errorCounter += 1)) "$DYNB_DYN_DOMAIN" "${DYNB_USERNAME}" "${DYNB_PASSWORD}${DYNB_TOKEN}"
      fi
    else debugMessage "Skip DynDNS2 update, checkStatus fetched previous error."
    fi
  else debugMessage "Skip DynDNS2 update"
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
  execute_connectivity_check 6
  return $?
}

function ipv4_is_not_working
{
  execute_connectivity_check 4
  return $?
}

function execute_connectivity_check
{
  local ip_version=$1
  curl --ipv"$ip_version" --head --silent --max-time 5 $_internet_connectivity_test_server > /dev/null
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

function read_config_file
{
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
}

function main
{
  # shellcheck disable=SC1091,SC1090
  source "$(dirname "$(realpath "$0")")/dynb-parsing.sh"

  read_config_file

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
      debugMessage "wait $DYNB_INTERVAL seconds until next check"
      sleep $DYNB_INTERVAL
    done
  else doUpdates
  fi

  doUnsets
  return 0
}

main "${@}"
exit $?
