#!/bin/sh

# This software has no licence.
# There is no court to appeal for intellectual property rights in the Darknet.
# This is by John Tate <john@johntate.org>
#
# Version 0.3, featuring tcp, udp, and sound.
#
# The TCP option might fool you behind a transparent Tor proxy, because a
# socket is opened even if the port is closed.
#
# I use a transparent proxy. You can export environment variables for this to
# work with your super lame Tor configuration, except for ICMP.

#The sound to play when finished
#sound="/usr/share/sounds/KDE-Im-New-Mail.ogg" 			#KDE
sound="/usr/share/sounds/gnome/default/alerts/sonar.ogg"	#Gnome

#nosound="yes"

function proto {
	if [ $proto == "http" ]; then
		pexist="y"
		if curl -I $service > /dev/null 2> /dev/null; then
			echo "up"
		fi
	fi
	if [ $proto == "icmp" ]; then
		pexist="y"
		if ping -c 1 $service > /dev/null 2> /dev/null; then
			echo "up"
		fi
	fi
	if [ $proto == "tcp" ]; then
		pexist="y"
		if echo "" | socat STDIN TCP4:$service > /dev/null 2> /dev/null; then
			echo "up"
		fi
	fi

	if [ $proto == "udp" ]; then
		pexist="y"
		if echo "" | socat STDIN UDP4:$service > /dev/null 2> /dev/null; then
			echo "up"
		fi
	fi

	if [ -z $pexist ]; then
		echo "The protocol specified was invalid."
		exit
	fi
}

function audioloop {
	if [ -f /tmp/serviceup_audio ]; then
		rm /tmp/serviceup_audio
	fi

	echo -n "alive" > /tmp/serviceup_audio_state

	cat << EOF | sed '/^$/d' > /tmp/serviceup_audio
	echo "Sound script starting..."
	state="alive"
	while [ "\$state" == "alive" ]; do
	paplay $sound
	sleep 5
	state=\`cat /tmp/serviceup_audio_state\`
	done
	rm /tmp/serviceup_audio_state
	rm /tmp/serviceup_audio #lol i removd myslf. tri dat wind0z
EOF
	
	bash /tmp/serviceup_audio &
}

if [ -z $1 ]; then
	echo "specify a protocol or help!"
	exit
fi

if [ $1 == "stop" ]; then
	echo -n "dead" > /tmp/serviceup_audio_state
	exit
fi

if [ $1 == "help" ]; then
        echo -e "serviceup.sh [protocol/option] [service] [wait]"
        echo -e "protocol\thttp, icmp, tcp or udp (required)"
        echo -e "service\t\tip address or domain name (required)"
	echo -e "\t\ttcp/udp must specify port (service:port)"
        echo -e "wait\t\thow long to wait between checks, optional, default 120 seconds"
	echo -e "\t\ta wait of 0 means it just checks if the service is up or down"
	echo -e "options: stop, help"
	echo -e "stop\t\tstop the damn audio from playing"
	echo -e "help\t\tthis help information"
        exit
fi

if [ -z $2 ]; then
	echo "specify a service address!"
	exit
fi

if [ -z $3 ]; then
	wait="120"
else
	wait=$3
fi

proto=$1
service=$2

echo "John Tate's great service checker."
echo "Checking for $service via $proto every $wait seconds"

if [ $wait == "0" ]; then
	echo "The service is $(proto)."
	exit
fi

while [ 1 -lt 2 ]; do
	thedate=`date +%H:%M:%S`
	tput sc
	echo -en "$thedate, checking service $service"
	if [ "$(proto)" == "up" ]; then
		thedate=`date +%H:%M:%S`
		echo -e "\n$thedate, service is now online."
		if [ -z $nosound ]; then
			echo "Audio enabled, run serviceup.sh stop to end."
			audioloop
		fi
		exit
	fi		
	sleep $wait
	tput el1
	tput rc
done
