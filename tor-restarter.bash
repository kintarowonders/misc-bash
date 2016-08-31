#!/bin/bash

#log file and full path
logfile="notices.log.test1"
#path to store archived logs
logpath="./"

function clearlog {
	logdate=`date +%F-%R:%S`
	echo "${logpath}notices.log-${logdate}"
	mv $logfile ${logpath}notices.log-${logdate}
	echo "$logdate RESTARTER: Service restarted, starting new log file." > $logfile
}

function restarter {
	clearlog
	echo "restarting tor"
}

function logcheck {
	timestamp=`date +%s`
	tempfile="/tmp/tor-restarter-$timestamp"
	cat $logfile | tail -n 20 > $tempfile
	sed -i "/Internal error: Got an INTRODUCE2 cell on an intro circ/!d" $tempfile
	line=`tail -n 1 $tempfile`
	rm $tempfile
	if [[ $line == "" ]]; then
		echo -n ""
	else
		restarter
	fi
}

logcheck
