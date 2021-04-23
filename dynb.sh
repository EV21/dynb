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
_version=0.1.1
_userAgent="DynB/$_version github.com/EV21/dynb"
_configFile=$HOME/.local/share/dynb/.env
_statusFile=/tmp/dynb.status
_debug=0
_minimum_looptime=60
_loopMode=0

# Created by argbash-init v2.10.0
# Rearrange the order of options below according to what you would like to see in the help message.
# ARG_OPTIONAL_BOOLEAN([version],[v],[outputs the client version],[off])
# ARG_OPTIONAL_BOOLEAN([link],[l],[links to your script at ~/.local/bin/dynb],[off])
# ARG_OPTIONAL_BOOLEAN([reset],[r],[deletes the client blocking status file],[off])
# ARG_OPTIONAL_BOOLEAN([debug],[],[enables debug mode],[off])
# ARG_OPTIONAL_SINGLE([update-method],[m],[choose if you want to use DynDNS2 or the DomRobot RPC-API],[])
# ARG_OPTIONAL_SINGLE([ip-mode],[i],[updates type A (IPv4) and AAAA (IPv6) records],[])
# ARG_OPTIONAL_SINGLE([domain],[d],[set the domain you want to update],[])
# ARG_OPTIONAL_SINGLE([service-provider],[s],[set your provider in case you are using DynDNS2],[])
# ARG_OPTIONAL_SINGLE([username],[u],[depends on your selected update method and your provider],[])
# ARG_OPTIONAL_SINGLE([password],[p],[depends on your selected update method and your provider],[])
# ARG_OPTIONAL_SINGLE([token],[t],[depends on your selected update method and your provider],[])
# ARG_OPTIONAL_SINGLE([interval],[],[choose the seconds interval to run the script in a loop, minimum is 60],[])
# ARG_HELP([DynB - dynamic DNS update script for bash])
# ARGBASH_GO()
# needed because of Argbash --> m4_ignore([
### START OF CODE GENERATED BY Argbash v2.10.0 one line above ###
# Argbash is a bash code generator used to get arguments parsing right.
# Argbash is FREE SOFTWARE, see https://argbash.io for more info


die()
{
	local _ret="${2:-1}"
	test "${_PRINT_HELP:-no}" = yes && print_help >&2
	echo "$1" >&2
	exit "${_ret}"
}


begins_with_short_option()
{
	local first_option all_short_options='vlrmidsupth'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_version="off"
_arg_link="off"
_arg_reset="off"
_arg_debug="off"
_arg_update_method=
_arg_ip_mode=
_arg_domain=
_arg_service_provider=
_arg_username=
_arg_password=
_arg_token=
_arg_interval=


print_help()
{
	printf '%s\n' "DynB - dynamic DNS update script for bash"
	printf 'Usage: %s [-v|--(no-)version] [-l|--(no-)link] [-r|--(no-)reset] [--(no-)debug] [-m|--update-method <arg>] [-i|--ip-mode <arg>] [-d|--domain <arg>] [-s|--service-provider <arg>] [-u|--username <arg>] [-p|--password <arg>] [-t|--token <arg>] [--interval <arg>] [-h|--help]\n' "$0"
	printf '\t%s\n' "-v, --version, --no-version: outputs the client version (off by default)"
	printf '\t%s\n' "-l, --link, --no-link: links to your script at ~/.local/bin/dynb (off by default)"
	printf '\t%s\n' "-r, --reset, --no-reset: deletes the client blocking status file (off by default)"
	printf '\t%s\n' "--debug, --no-debug: enables debug mode (off by default)"
	printf '\t%s\n' "-m, --update-method: choose if you want to use DynDNS2 or the DomRobot RPC-API (no default)"
	printf '\t%s\n' "-i, --ip-mode: updates type A (IPv4) and AAAA (IPv6) records (no default)"
	printf '\t%s\n' "-d, --domain: set the domain you want to update (no default)"
	printf '\t%s\n' "-s, --service-provider: set your provider in case you are using DynDNS2 (no default)"
	printf '\t%s\n' "-u, --username: depends on your selected update method and your provider (no default)"
	printf '\t%s\n' "-p, --password: depends on your selected update method and your provider (no default)"
	printf '\t%s\n' "-t, --token: depends on your selected update method and your provider (no default)"
	printf '\t%s\n' "--interval: choose the seconds interval to run the script in a loop, minimum is 60 (no default)"
	printf '\t%s\n' "-h, --help: Prints help"
}


parse_commandline()
{
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			-v|--no-version|--version)
				_arg_version="on"
				test "${1:0:5}" = "--no-" && _arg_version="off"
				;;
			-v*)
				_arg_version="on"
				_next="${_key##-v}"
				if test -n "$_next" -a "$_next" != "$_key"
				then
					{ begins_with_short_option "$_next" && shift && set -- "-v" "-${_next}" "$@"; } || die "The short option '$_key' can't be decomposed to ${_key:0:2} and -${_key:2}, because ${_key:0:2} doesn't accept value and '-${_key:2:1}' doesn't correspond to a short option."
				fi
				;;
			-l|--no-link|--link)
				_arg_link="on"
				test "${1:0:5}" = "--no-" && _arg_link="off"
				;;
			-l*)
				_arg_link="on"
				_next="${_key##-l}"
				if test -n "$_next" -a "$_next" != "$_key"
				then
					{ begins_with_short_option "$_next" && shift && set -- "-l" "-${_next}" "$@"; } || die "The short option '$_key' can't be decomposed to ${_key:0:2} and -${_key:2}, because ${_key:0:2} doesn't accept value and '-${_key:2:1}' doesn't correspond to a short option."
				fi
				;;
			-r|--no-reset|--reset)
				_arg_reset="on"
				test "${1:0:5}" = "--no-" && _arg_reset="off"
				;;
			-r*)
				_arg_reset="on"
				_next="${_key##-r}"
				if test -n "$_next" -a "$_next" != "$_key"
				then
					{ begins_with_short_option "$_next" && shift && set -- "-r" "-${_next}" "$@"; } || die "The short option '$_key' can't be decomposed to ${_key:0:2} and -${_key:2}, because ${_key:0:2} doesn't accept value and '-${_key:2:1}' doesn't correspond to a short option."
				fi
				;;
			--no-debug|--debug)
				_arg_debug="on"
				test "${1:0:5}" = "--no-" && _arg_debug="off"
				;;
			-m|--update-method)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_update_method="$2"
				shift
				;;
			--update-method=*)
				_arg_update_method="${_key##--update-method=}"
				;;
			-m*)
				_arg_update_method="${_key##-m}"
				;;
			-i|--ip-mode)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_ip_mode="$2"
				shift
				;;
			--ip-mode=*)
				_arg_ip_mode="${_key##--ip-mode=}"
				;;
			-i*)
				_arg_ip_mode="${_key##-i}"
				;;
			-d|--domain)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_domain="$2"
				shift
				;;
			--domain=*)
				_arg_domain="${_key##--domain=}"
				;;
			-d*)
				_arg_domain="${_key##-d}"
				;;
			-s|--service-provider)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_service_provider="$2"
				shift
				;;
			--service-provider=*)
				_arg_service_provider="${_key##--service-provider=}"
				;;
			-s*)
				_arg_service_provider="${_key##-s}"
				;;
			-u|--username)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_username="$2"
				shift
				;;
			--username=*)
				_arg_username="${_key##--username=}"
				;;
			-u*)
				_arg_username="${_key##-u}"
				;;
			-p|--password)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_password="$2"
				shift
				;;
			--password=*)
				_arg_password="${_key##--password=}"
				;;
			-p*)
				_arg_password="${_key##-p}"
				;;
			-t|--token)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_token="$2"
				shift
				;;
			--token=*)
				_arg_token="${_key##--token=}"
				;;
			-t*)
				_arg_token="${_key##-t}"
				;;
			--interval)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_interval="$2"
				shift
				;;
			--interval=*)
				_arg_interval="${_key##--interval=}"
				;;
			-h|--help)
				print_help
				exit 0
				;;
			-h*)
				print_help
				exit 0
				;;
			*)
				_PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
				;;
		esac
		shift
	done
}

parse_commandline "$@"

# OTHER STUFF GENERATED BY Argbash

### END OF CODE GENERATED BY Argbash (sortof) ### ])
# [ <-- needed because of Argbash

# The generated argbash help message does not look as nice as this:
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

function loopMode() {
  if [[ $_loopMode -eq 1 ]]; then
    return 0
  else
    return 1
  fi
}

function debugMode() {
  if [[ $_debug -eq 1 ]]; then
    return 0
  else
    return 1
  fi
}

function debugMessage() {
  if debugMode; then
    echo "Debug: $*"
  fi
}

function echoerr() { printf "%s\n" "$*" >&2; }

# The main domain as an identifier for the dns zone is required for the updateRecord call
function getMainDomain() {
  request=$( echo "{}" | \
      jq '(.method="nameserver.list")' | \
      jq "(.params.user=\"$DYNB_USERNAME\")" | \
      jq "(.params.pass=\"$DYNB_PASSWORD\")"
    )

  _response=$(curl --silent  \
      "$_interface_str" \
      --user-agent "$_userAgent" \
      --header "Content-Type: application/json" \
      --request POST $_INWX_JSON_API_URL \
      --data "$request" | jq ".resData.domains[] | select(inside(.domain=\"$DYNB_DYN_DOMAIN\"))"
    )
  _main_domain=$( echo "$_response" | jq --raw-output '.domain'  )
}

function fetchDNSRecords() {
  request=$( echo "{}" | \
      jq '(.method="'nameserver.info'")' | \
      jq "(.params.user=\"$DYNB_USERNAME\")" | \
      jq "(.params.pass=\"$DYNB_PASSWORD\")" | \
      jq "(.params.domain=\"$_main_domain\")" | \
      jq "(.params.name=\"$DYNB_DYN_DOMAIN\")"
    )

  _response=$( curl --silent  \
      "$_interface_str" \
      --user-agent "$_userAgent" \
      --header "Content-Type: application/json" \
      --request POST $_INWX_JSON_API_URL \
      --data "$request"
    )

  _dns_records=$( echo "$_response" | jq '.resData.record[]' )
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
      jq "(.params.user=\"$DYNB_USERNAME\")" | \
      jq "(.params.pass=\"$DYNB_PASSWORD\")" | \
      jq "(.params.id=\"$ID\")" | \
      jq "(.params.content=\"$IP\")" | \
      jq "(.params.ttl=\"$TTL\")"
    )

  _response=$(curl --silent  \
      "$_interface_str" \
      --user-agent "$_userAgent" \
      --header "Content-Type: application/json" \
      --request POST $_INWX_JSON_API_URL \
      --data "$request"
     )
     echo -e "$(echo "$_response" | jq --raw-output '.msg')\n Domain: $DYNB_DYN_DOMAIN\n new IPv${1}: $IP"
  fi
}

# using DynDNS2 protocol
function dynupdate() {
  # default parameter values
  myip_str=myip
  myipv6_str=myipv6

  INWX_DYNDNS_UPDATE_URL="https://dyndns.inwx.com/nic/update?"
  DESEC_DYNDNS_UPDATE_URL="https://update.dedyn.io/?"
  DUCKDNS_DYNDNS_UPDATE_URL="https://www.duckdns.org/update?domains=$DYNB_DYN_DOMAIN&token=$DYNB_TOKEN&"
  DYNV6_DYNDNS_UPDATE_URL="https://dynv6.com/api/update?zone=$DYNB_DYN_DOMAIN&token=$DYNB_TOKEN&"

  case $DYNB_SERVICE_PROVIDER in
    inwx* | INWX* )
      dyndns_update_url=$INWX_DYNDNS_UPDATE_URL
    ;;
    deSEC* | desec* | dedyn* )
      dyndns_update_url="${DESEC_DYNDNS_UPDATE_URL}"
    ;;
    dynv6* )
      dyndns_update_url="${DYNV6_DYNDNS_UPDATE_URL}"
      myip_str=ipv4
      myipv6_str=ipv6
    ;;
    DuckDNS* | duckdns* )
      dyndns_update_url="${DUCKDNS_DYNDNS_UPDATE_URL}"
      myip_str=ipv4
      myipv6_str=ipv6
    ;;
    * )
    echoerr "$DYNB_SERVICE_PROVIDER is not supported"
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
    inwx* | INWX* )
      _response=$(curl --silent "$_interface_str" \
      --user-agent "$_userAgent" \
      --user "$DYNB_USERNAME":"$DYNB_PASSWORD" \
      "${dyndns_update_url}" )
    ;;
    deSEC* | desec* | dedyn* )
      _response=$(curl --silent "$_interface_str" \
      --user-agent "$_userAgent" \
      --header "Authorization: Token $DYNB_TOKEN" \
      --get --data-urlencode "hostname=$DYNB_DYN_DOMAIN" \
      "${dyndns_update_url}" )
    ;;
    dynv6* | duckDNS* | duckdns* )
      _response=$(curl --silent "$_interface_str" \
        --user-agent "$_userAgent" \
        "${dyndns_update_url}"
      )
    ;;
  esac

  case $_response in
    good* | OK* | "addresses updated" )
      if [[ $_response == "good 127.0.0.1" ]]; then
        echoerr "Error: $_response: Request ignored."
        return 1
      else
        echo "$_response: The DynDNS update has been executed."
        _errorCounter=0
        return 0
      fi
    ;;
    nochg* )
      echo "$_response: Nothing has changed, IP addresses are still up to date."
      return 1
    ;;
    abuse )
      echoerr "Error: $_response: Username is blocked due to abuse."
      return 1
    ;;
    badauth | 401 )
      echoerr "Error: $_response: Invalid username password combination."
      return 1
    ;;
    badagent )
      echoerr "Error: $_response: Client disabled. Something is very wrong!"
      return 1
    ;;
    !donator )
      echoerr "Error: $_response: An update request was sent, including a feature that is not available to that particular user such as offline options."
      return 1
    ;;
    !yours )
      echoerr "Error: $_response: The domain does not belong to your user account"
      return 1
    ;;
    notfqdn )
      echoerr "Error: $_response: Hostname $DYNB_DYN_DOMAIN is invalid"
      return 1
    ;;
    nohost )
      echoerr "Error: $_response: Hostname supplied does not exist under specified account, enter new login credentials before performing an additional request."
      return 1
    ;;
    numhost )
      echoerr "Error: $_response: Too many hostnames have been specified for this update"
      return 1
    ;;
    dnserr )
      echoerr "Error: $_response: There is an internal error in the dyndns update system. Retry update no sooner than 30 minutes."
      return 1
    ;;
    911 | 5* )
      echoerr "Error: $_response: A fatal error on provider side such as a database outage. Retry update no sooner than 30 minutes."
      return 1
    ;;
    * )
      if [[ "$_response" == "$_status" ]]; then
        echoerr "Error: An unknown response code has been received. $_response"
        return 1
      else
        echoerr "Error: unknown respnse code: $_response"
        return 0
      fi
    ;;
  esac
}

function setStatus() {
  echo "_status=$1; _eventTime=$2; _errorCounter=$3; _statusHostname=$4; _statusUsername=$5; _statusPassword=$6" > /tmp/dynb.status
}

# handle errors from past update requests
function checkStatus() {
  case $_status in
    nochg* )
      if [[ _errorCounter -gt 1 ]]; then
        echoerr "Error: The update client was spamming unnecessary update requests, something might be wrong with your IP-Check site."
        echoerr "Fix your config an then delete $_statusFile"
        return 1
      fi
    ;;
    nohost | !yours )
      if [[ "$_statusHostname" == "$DYNB_DYN_DOMAIN" && ( "$_statusUsername" == "$DYNB_USERNAME" || $_statusUsername == "$DYNB_TOKEN" ) ]]; then
        echoerr "Error: Hostname supplied does not exist under specified account, enter new login credentials before performing an additional request."
        return 1
      else
        rm "$_statusFile"
      fi
      return 0
    ;;
    badauth | 401 )
      if [[ "$_statusUsername" == "$DYNB_USERNAME" && "$_statusPassword" == "$DYNB_PASSWORD" ]]; then
        echoerr "Error: Invalid username password combination."
        return 1
      else
        rm "$_statusFile"
      fi
      return 0
    ;;
    badagent )
      echoerr "Error: Client is deactivated by provider."
      echo "Fix your config and then manually remove $_statusFile to reset the client blockade."
      echo "If it still fails file an issue at github or try another client :)"
      return 1
    ;;
    !donator )
      echoerr "Error: An update request was sent, including a feature that is not available to that particular user such as offline options."
      echo "Fix your config and then manually remove $_statusFile to reset the client blockade"
      echo "If it still fails file an issue at github or try another client :)"
      return 1
    ;;
    abuse )
      echoerr "Error: Username is blocked due to abuse."
      echo "Fix your config and then manually remove $_statusFile to reset the client blockade"
      echo "If it still fails file an issue at github or try another client :)"
      return 1
    ;;
    911 | 5* )
      delta=$(( $(date +%s) - _eventTime ))
      if [[ $delta -lt 1800 ]]; then
        echoerr "$_status: The provider currently has an fatal error. DynB will wait for next update until 30 minutes have passed since last request, $(date --date=@$delta -u +%M) minutes already passed."
        return 1
      else
        rm "$_statusFile"
      fi
      return 0
    ;;
    * )
      if [[ _errorCounter -gt 1 ]]; then
        echoerr "Error: An unknown response code has repeatedly been received. $_response"
        return 1
      else
        return 0
      fi
    ;;
  esac
}

# requires parameter
# 1. param: 4 or 6 for IP version
function ipHasChanged() {
  if [[ ${1} == 4 ]]; then
    remote_ip=$(getRemoteIP 4 $_ipv4_checker)
    #TODO: this is doublicated code, refactor this some time
    if [[ $? -gt 0 ]]; then
      echoerr "IPCheck (getRemoteIP) request failed $remote_ip"
      return 0
    fi
    if [[ $DYNB_UPDATE_METHOD == domrobot ]]; then
      dns_ip=$(getDNSIP A)
    else
      dig_response=$(dig @${_DNS_checkServer} in a +short "$DYNB_DYN_DOMAIN")
      #TODO: this is doublicated code, refactor this some time
      if [[ $dig_response == ";; connection timed out; no servers could be reached" ]]; then
        echoerr "DNS request failed $dig_response"
        return 0
      fi
      dns_ip=$dig_response
    fi
  fi
  if [[ ${1} == 6 ]]; then
    remote_ip=$(getRemoteIP 6 $_ipv6_checker)
    #TODO: this is doublicated code, refactor this some time
    if [[ $? -gt 0 ]]; then
      echoerr "IPCheck (getRemoteIP) request failed $remote_ip"
      return 0
    fi
    if [[ $DYNB_UPDATE_METHOD == domrobot ]]; then
      dns_ip=$(getDNSIP AAAA)
    else
      dig_response=$(dig @${_DNS_checkServer} in aaaa +short "$DYNB_DYN_DOMAIN")
      #TODO: this is doublicated code, refactor this some time
      if [[ $dig_response == ";; connection timed out; no servers could be reached" ]]; then
        echoerr "DNS request failed $dig_response"
        return 0
      fi
      dns_ip=$dig_response
    fi
  fi

  if [[ ${1} == 4 ]]; then
    _new_IPv4=$remote_ip
    debugMessage "New IPv4: $_new_IPv4 old was: $dns_ip"
  else
    _new_IPv6=$remote_ip
    debugMessage "New IPv6: $_new_IPv6 old was: $dns_ip"
  fi

  if [[ "$remote_ip" == "$dns_ip" ]]; then
    return 0
  else
    return 1
  fi
}

################
## parameters ##
################

function handleParameters() {
  if [[ $_arg_version == "on" ]]; then
    echo $_version
    exit 0
  fi
  if [[ $_arg_link == "on" ]]; then
    ln --verbose --symbolic "$(realpath "$0")" "$HOME/.local/bin/dynb"
    exit 0
  fi
  if [[ $_arg_reset == "on" ]]; then
    rm --verbose "$_statusFile"
    exit 0
  fi
    if [[ $_arg_debug == "on" ]]; then
    _debug=1
  fi
  if [[ $_arg_update_method != "" ]]; then
    DYNB_UPDATE_METHOD=$_arg_update_method
  fi
  if [[ $_arg_ip_mode != "" ]]; then
    DYNB_IP_MODE=$_arg_ip_mode
  fi
  if [[ $_arg_domain != "" ]]; then
    DYNB_DYN_DOMAIN=$_arg_domain
  fi
  if [[ $_arg_service_provider != "" ]]; then
    DYNB_SERVICE_PROVIDER=$_arg_service_provider
  fi
  if [[ $_arg_username != "" ]]; then
    DYNB_USERNAME=$_arg_username
  fi
  if [[ $_arg_password != "" ]]; then
    DYNB_PASSWORD=$_arg_password
  fi
  if [[ $_arg_token != "" ]]; then
    DYNB_TOKEN=$_arg_token
  fi
  if [[ $_arg_interval != "" ]]; then
    DYNB_INTERVAL=$_arg_interval
  fi

  if [[ -z $DYNB_INTERVAL ]]; then
    _loopMode=0
  elif [[ $DYNB_INTERVAL -lt _minimum_looptime ]]; then
    DYNB_INTERVAL=$_minimum_looptime
    _loopMode=1
  else
    _loopMode=1
  fi
    if [[ $_network_interface != "" ]]; then
    _interface_str="--interface $_network_interface"
  fi

  if [[ $DYNB_IP_MODE == d* ]]; then
    _is_IPv4_enabled=true
    _is_IPv6_enabled=true
  fi
  if [[ $DYNB_IP_MODE == *4* ]]; then
    _is_IPv4_enabled=true
  fi
  if [[ $DYNB_IP_MODE == *6* ]]; then
    _is_IPv6_enabled=true
  fi

  if [[ $DYNB_DEBUG == true ]]; then
    _debug=1
  fi
  return 0
}

##################
## dependencies ##
##################

function checkDependencies() {
  ## If there will be more general dependencies use a loop
  # for i in curl and some other stuff; do
  #   if ! command -v $i >/dev/null 2>&1; then
  #     echoerr "Error: could not find \"$i\", DynB depends on it. "
  #     exit 1
  #   fi
  # done
  [[ -x $(command -v jq 2> /dev/null) ]] || {
    if [[ $DYNB_UPDATE_METHOD != dyndns* ]]; then
      echo "This script depends on jq and it is not available." >&2
      exit 1
    fi
  }
}

function doUnsets() {
  unset _network_interface
  unset _DNS_checkServer
  unset _dns_records
  unset DYNB_DYN_DOMAIN
  unset _has_getopt
  unset _help_message
  unset _INWX_JSON_API_URL
  unset DYNB_IP_MODE
  unset _ipv4_checker
  unset _ipv6_checker
  unset _is_IPv4_enabled
  unset _is_IPv6_enabled
  unset _main_domain
  unset _new_IPv4
  unset _new_IPv6
  unset DYNB_PASSWORD
  unset DYNB_USERNAME
  unset DYNB_SERVICE_PROVIDER
  unset _version
}

function doUpdates() {
  if [[ $DYNB_UPDATE_METHOD == "domrobot" ]]; then
    getMainDomain
    fetchDNSRecords
    if [[ $_is_IPv4_enabled == true ]]; then
      ipHasChanged 4
      if [[ $? == 1 ]]; then
        updateRecord 4
      else
        debugMessage "Skip IPv4 record update, it is already up to date"
      fi
    fi
    if [[ $_is_IPv6_enabled == true ]]; then
      ipHasChanged 6
      if [[ $? == 1 ]]; then
        updateRecord 6
      else
        debugMessage "Skip IPv6 record update, it is already up to date"
      fi
    fi
  fi

  if [[ $DYNB_UPDATE_METHOD == "dyndns" ]]; then
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
      if checkStatus; then
        debugMessage "checkStatus has no errors, try update"
        if dynupdate; then
          debugMessage "DynDNS2 update success"
        else
          debugMessage "Save new status after dynupdate has failed"
          setStatus "$_response" "$(date +%s)" $(( _errorCounter += 1 )) "$DYNB_DYN_DOMAIN" "${DYNB_USERNAME}" "${DYNB_PASSWORD}${DYNB_TOKEN}"
        fi
      else
        debugMessage "Skip DynDNS2 update, checkStatus fetched previous error."
      fi
    else
      debugMessage "Skip DynDNS2 update, IPs are up to date or there is a connection problem"
    fi
  fi
}

#################
## MAIN method ##
#################
function dynb() {
  ## parameters and checks
  checkDependencies

  # shellcheck source=.env
  if test -f "$_configFile"; then
    # shellcheck disable=SC1091
    source "$_configFile"
  else
    alternativeConfig="$(dirname "$(realpath "$0")")/.env"
    if test -f "$alternativeConfig"; then
      # shellcheck disable=SC1091
      source "$alternativeConfig"
    fi
  fi
  if test -f "$_statusFile"; then
    debugMessage "read previous status file"
    # shellcheck disable=SC1090
    source "$_statusFile"
  fi

  handleParameters

  ## execute operations


  if loopMode; then
    while :
    do
      doUpdates
      sleep $DYNB_INTERVAL
    done
  else
    doUpdates
  fi

  doUnsets
  return 0
}
######################
## END MAIN section ##
######################

  dynb "${@}"
  exit $?

# ] <-- needed because of Argbash
