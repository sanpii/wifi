#!/bin/bash

INTERFACE="$1"
[ -z "$1" ] && INTERFACE="wlan1"

# "yes" : pretty color output ; anything else : good ol' B&W
color="yes"

# iwlist output parsing
PARSER='
BEGIN { FS=":"; OFS="="; }
/\<Cell/ { if (essid) print essid, channel, security, quality[2]/quality[3]*100; security="none" }
/\<Channel/ { channel=$2 }
/\<ESSID:/ { essid=substr($2, 2, length($2) - 2) } # discard quotes
/\<Quality/ { split($1, quality, "[=/]") }
/\<IE:.*WPA.*/ { security="wpa" }
/\<Encryption key:on/ { if(!security) security="wep" }
END { if (essid) print essid, channel, security, quality[2]/quality[3]*100 }
'

fail () {
    echo "$1"
    exit 0
}

pretty_printing () {
    bldred='\e[1;31m' # Red
    bldgrn='\e[1;32m' # Green
    bldylw='\e[1;33m' # Yellow
    bldblu='\e[1;34m' # Blue
    bldpur='\e[1;35m' # Purple
    txtrst='\e[0m'    # Text Reset

    local IFS='='
    while read essid channel security signal
    do
    if [ "$security" = "wep" -o "$security" = "none" ]
    then
        comment=" ~~=)"
    else
        comment=
    fi
    found_one="yep"
    if [ "$color" = "yes" ]
    then
        echo -e "→ ${bldylw}${essid}${txtrst} [${bldgrn}${channel}${txtrst}] (${bldblu}${security}${bldpur}${comment}${txtrst}) : ${bldred}${signal/.*/}${txtred}%${txtrst}"
    else
        echo "-> $essid [$channel] ($security) : ${signal/.*/}%"
    fi
    done
    if [ -z "$found_one" ]
    then
    echo "Sorry, I don't get anything, this place somewhat lacks datalove…"
    fi
}

[ $(id -u) -ne 0 ] && fail "Hey, get off, this should only be run by root."

ip link set $INTERFACE up
iwlist $INTERFACE scan 2>/dev/null | awk "$PARSER" | sort -t= -nrk4 | pretty_printing
