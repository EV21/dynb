
.. include:: man-defs.rst


===
man
===

-----------------------------------------
DynB - dynamic DNS update script for bash
-----------------------------------------

:Author: |AUTHOR|
:Date:   2021-04-21
:Version: |VERSION|
:Manual section: |MAN_SECTION|


SYNOPSIS
========

``man  [--version] [--link] [--reset] [--debug] [--update-method UPDATE-METHOD] [--ip-mode IP-MODE] [--domain DOMAIN] [--service-provider SERVICE-PROVIDER] [--username USERNAME] [--password PASSWORD] [--token TOKEN] [--interval INTERVAL] [--help]``


DESCRIPTION
===========

|DESCRIPTION|


ARGUMENTS
=========

-v, --version                                             outputs the client version.
                                                          [Default: off]

                                                          |OPTION_VERSION|

-l, --link                                                links to your script at ~/.local/bin/dynb.
                                                          [Default: off]

                                                          |OPTION_LINK|

-r, --reset                                               deletes the client blocking status file.
                                                          [Default: off]

                                                          |OPTION_RESET|

--debug                                                   enables debug mode.
                                                          [Default: off]

                                                          |OPTION_DEBUG|

-m UPDATE-METHOD, --update-method UPDATE-METHOD           choose if you want to use DynDNS2 or the DomRobot RPC-API.

                                                          |OPTION_UPDATE_METHOD|

-i IP-MODE, --ip-mode IP-MODE                             updates type A (IPv4) and AAAA (IPv6) records.

                                                          |OPTION_IP_MODE|

-d DOMAIN, --domain DOMAIN                                set the domain you want to update.

                                                          |OPTION_DOMAIN|

-s SERVICE-PROVIDER, --service-provider SERVICE-PROVIDER  set your provider in case you are using DynDNS2.

                                                          |OPTION_SERVICE_PROVIDER|

-u USERNAME, --username USERNAME                          depends on your selected update method and your provider.

                                                          |OPTION_USERNAME|

-p PASSWORD, --password PASSWORD                          depends on your selected update method and your provider.

                                                          |OPTION_PASSWORD|

-t TOKEN, --token TOKEN                                   depends on your selected update method and your provider.

                                                          |OPTION_TOKEN|

--interval INTERVAL                                       choose the seconds interval to run the script in a loop, minimum is 60.

                                                          |OPTION_INTERVAL|

-h, --help                                                Prints help.

                                                          |OPTION_HELP|
