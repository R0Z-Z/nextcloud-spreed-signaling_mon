#!/bin/bash
LANG=C
LC_ALL=C

declare -A PKT_DROPS
declare -A USER_IP
declare -A CLIENT_RTT
declare -A LOST_PKTS
declare -A OS_BROWSER
declare -A COUNTRY
declare -A DATE_TIME
declare -A LOST_PKTS_TIME
BACKLOG_LINES=8000
LOOP_COUNTER=100

while read line; do
	eval $(echo "$line" | sed -nr "s/^([a-zA-Z]{3} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}) .*: Register.* ([a-z_]{3,14})@compat from ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}) in ([A-Z]{2}|unknown-country) (\(.*\)) (.*) \(private=.*\)$/unset 'DATE_TIME[\6]'; USER_IP+=([\6]=\2' '\3) DATE_TIME+=([\6]='\1') COUNTRY+=([\6]='\4') OS_BROWSER+=([\6]='\5')/p")
	eval $(echo "$line" | sed -nr "s/^([a-zA-Z]{3} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}) .*: Client ([A-Za-z0-9_\-]{230,}) has RTT of ([0-9]{1,4}) ms \(.*\)$/unset 'DATE_TIME[\2]'; CLIENT_RTT+=([\2]=\3ms' ') DATE_TIME+=([\2]='\1')/p") 
	eval $(echo "$line" | sed -nr "s/^[a-zA-Z]{3} [0-9]{1,2} ([0-9]{2}:[0-9]{2}:[0-9]{2}) .*: (Subscriber|Publisher) (.*) \(.*\) is reporting ([0-9]{1,4}) lost packets on the (up|down)link .*$/unset 'LOST_PKTS_TIME[\3]'; LOST_PKTS+=([\3]=\4:\5' ') LOST_PKTS_TIME+=([\3]='\\\e[1;31m! \\\e[0m\\\e[1;33m\1\\\e[0m')/p") 
	CLIENT_UNREGISTER=( $(echo "$line" | sed -nr "s/^[a-zA-Z]{3} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2} .*: Unregister (.*) \(private=.*\)$/\1/p") )

#	echo "${USER_IP[@]}"
#	echo "${CLIENT_RTT[@]}"
#	echo "${LOST_PKTS[@]}"
#	echo "${OS_BROWSER[@]}"
#	echo "${DATE_TIME[@]}"
#	echo "${COUNTRY[@]}"
#	echo "$CLIENT_UNREGISTER"


if [ $CLIENT_UNREGISTER ]
	then
#	echo "${!USER_IP[ $CLIENT_UNREGISTER ]}"
#	echo -e "## PRE-UNSET ## USER Array Size: ${#USER_IP[*]} ; RTT Array Size: ${#CLIENT_RTT[*]}"
#	echo "$CLIENT_UNREGISTER"
	unset 'USER_IP[$CLIENT_UNREGISTER]'	
	unset 'CLIENT_RTT[$CLIENT_UNREGISTER]'	
	unset 'LOST_PKTS[$CLIENT_UNREGISTER]'	
	unset 'OS_BROWSER[$CLIENT_UNREGISTER]'	
	unset 'DATE_TIME[$CLIENT_UNREGISTER]'	
	unset 'LOST_PKTS_TIME[$CLIENT_UNREGISTER]'	
	unset 'COUNTRY[$CLIENT_UNREGISTER]'	
	clear 
	printf 'Processing last %b log lines...\nArray Sizes:\n | USER_IP    => %b\n | CLIENT_RTT => %b\n | LOST_PKTS  => %b\n | OS_BROWSER => %b\n | DATE_TIME  => %b\n | COUNTRY    => %b\n \r' $BACKLOG_LINES ${#USER_IP[*]} ${#CLIENT_RTT[*]} ${#LOST_PKTS[*]} ${#OS_BROWSER[*]} ${#DATE_TIME[*]} ${#COUNTRY[*]} 
fi 

if [ "$LOOP_COUNTER" -gt "$BACKLOG_LINES" ];
	then
	clear
	COLUMNS=$(tput cols)
	PADDING=$(printf '%.1b' "#"{1..20})
	eval "printf '%.1b' "-"{1..$COLUMNS}"; printf "\n"
	printf '%-'$(((COLUMNS-45)/2))'b %b %'$(((COLUMNS-45)/2))'b\n' "$PADDING" " CURRENT SIGNALING SERVER CONNECTION STATUS " "$PADDING"
	eval "printf '%.1b' "-"{1..$COLUMNS}"; printf '\n'
	printf '\e[1;31m%-18b%-29b%-42b%b\e[0m\n' "Updated:" "user@IP:" "RTT:" "Packet Loss:"
	printf '%-18b%-29b%-42b%b\n' "----------" "----------" "------" "--------------"
	for key in ${!USER_IP[@]};
		do
		case $1 in
		"")
                printf '%-16b| \e[1;32m%-12b\e[0m%-15b %-42b%-40b\n'  "${DATE_TIME[$key]}" ${USER_IP[$key]} "| ${CLIENT_RTT[$key]:(-40)}" "|${LOST_PKTS_TIME[$key]} - ${LOST_PKTS[$key]:(-40)}"
		;;
		"--extended")
		printf '%-16b| \e[1;32m%-12b\e[0m%-15b %-42b%-40b\n' "${DATE_TIME[$key]}" ${USER_IP[$key]} "| ${CLIENT_RTT[$key]:(-40)}" "|${LOST_PKTS_TIME[$key]} - ${LOST_PKTS[$key]:(-40)}" 
		printf '\e[1;33m%b\e[0m %-6b %b\n' Country: ${COUNTRY[$key]} "| \e[1;33mO/S Info:\e[0m \e[1;30m${OS_BROWSER[$key]}\e[0m"
		;;
		esac
	done
#	CLIENT_RTT[$key]=$(echo "${CLIENT_RTT[$key]}" | sed -r 's/\\e\[1;33m(.*)\\e\[0m/\1/')
	sleep 0.2
fi

let LOOP_COUNTER++
#echo -e "$LOOP_COUNTER\r"

done < <(journalctl -n $BACKLOG_LINES -f -u mkr-signaling.service)
#done < <(journalctl -n $BACKLOG_LINES -f -u mkr-signaling.service | egrep -E '^.*Register user.*$|^.*Client .* has RTT of .*$|^.*Unregister.*|^.*Subscriber.* is reporting.*$')
