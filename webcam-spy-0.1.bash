#!/bin/bash

#WEBCAM Spy by John Tate <john@johntate.org>
#Version 0.1 [USE AT YOUR OWN RISK]

CAPTURECMD="mplayer -vo png -frames 1 tv://"
OUTPUTNAME="00000001.png"
REMOTESERV="mises"
REMOTEPATH="/home/john/surveilance/fekete"
CONFDIR="$HOME/.webcam-spy"
INCRFILE="photo_total"
PHOTOTIMER="3"

#This writes a script used to test the remote server
cat > /tmp/.webcam-spy-$USER-script << EOF
#!/bin/bash

if [ -d $REMOTEPATH ]; then
	exit 0;
else
	if mkdir -p $REMOTEPATH; then
		exit 0;
	else
		exit 1;
	fi
fi

EOF

#This uploads the temporary script to the remote server and ensures that the
#path exists. If it doesn't, it is created, if it can't the script throws an
#error.
function remotepathchk {
	echo "Checking remote paths, if it hangs here your SSH is asking a password."
	echo "You can fix that by using public key authentication."
	scp /tmp/.webcam-spy-$USER-script $REMOTESERV:/tmp/.webcam-spy-$USER-script > /dev/null
	rm /tmp/.webcam-spy-$USER-script
	ssh $REMOTESERV chmod +x /tmp/.webcam-spy-$USER-script > /dev/null

	if ssh $REMOTESERV /tmp/.webcam-spy-$USER-script; then
		ssh $REMOTESERV rm /tmp/.webcam-spy-$USER-script > /dev/null
		return 0;
	else
		ssh $REMOTESERV rm /tmp/.webcam-spy-$USER-script > /dev/null
		echo "Script could not create remote path, check permissions on server."
		return 1;
	fi
}	

#This checks if the config directory exists, creates it, or throws an error.
function makecfgdir {
	echo "Checking if the config directory exists."
	if [ -d $CONFDIR ]; then
		return 0
	else
		if mkdir -p $CONFDIR; then
			return 0;
		else
			echo "Could not create config directory"
			return 1;
		fi
	fi
}

#This prepares the config directory.
function prepcfgdir {
	echo "Preparing config directory."
	if [ -d $CONFDIR/.photos ]; then
		echo -n;
	else
		mkdir $CONFDIR/.photos
	fi

	if [ -f $CONFDIR/$INCRFILE ]; then
		echo -n;
	else
		echo 0 > $CONFDIR/$INCRFILE
	fi
}

#This uploads the photo
function photoupload {
	HAPPY="no"
	date=`date +%F`
	declare -i INCREMENT=`sed -n 1p $CONFDIR/$INCRFILE`
	mv $OUTPUTNAME $CONFDIR/.photos/$date-$INCREMENT\.png;

	if scp $CONFDIR/.photos/$date-$INCREMENT\.png $REMOTESERV:$REMOTEPATH > /dev/null; then
		declare -i HAPPY="yes";
	else
		echo "Error, could not upload photo to remote host."
	fi

	let INCREMENT=INCREMENT+1
	echo $INCREMENT > $CONFDIR/$INCRFILE

	if [ $HAPPY = "yes" ]; then
		return 0
	else
		return 1
	fi
}

#This takes the photo
function photograph {
	mkdir -p /tmp/.webcam-spy
	cd /tmp/.webcam-spy

	if $CAPTURECMD > /dev/null 2>&1; then
		if photoupload; then
			return 0;
		else
			return 1;
		fi;
	else
		echo "Error: could not capture photograph."
		return 1;
	fi
}

if remotepathchk; then
	if makecfgdir; then
		if prepcfgdir; then
			echo -n
		else
			exit
		fi
	else
		exit
	fi
else
	exit
fi

echo "Proceeding to take photos, hold CTRL-C to stop."
while [ 1 -lt 2 ]; do
	photograph
	sleep $PHOTOTIMER;
done
