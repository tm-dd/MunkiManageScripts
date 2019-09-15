#!/bin/bash
#
# This Script change the owner of Software in "/Applications". It ask for the old username and change all files of this user (in this directory) to a new identity. 
# This is useful for software which have a build in update process and the software was installed not for the user which using the software normally.
#
# by Thomas Mueller
#

# check of root rights
if [ $USER != "root" ]
then
	echo "THIS SCRIPT MUST RUN AS USER root !!!"
        exec sudo $0
fi

# das temporaere Skript, welches die Zugriffsrechte spaeter aendert
TMPFILE="/tmp/change_owner_of_software.sh"

# eine optionale Konfigurationsdatei, die die User-ID und die Gruppen-ID fuer die neuen Dateien enthaelt
USERANDGROUPFILE='/usr/local/default_user_and_group.cfg'

echo 'This script CHANGE THE OWNER of all SOFTWARE in "/Applications" from a specified old login to a new LOGIN.'

# EINGABE DES ALTEN BENUTZERS
echo -n "What is the LOGIN of the OLD OWNER of the software (e.g. admin): "
read OLDUSER
echo


# EINGABE DES NEUEN BENUTZERS
echo -n "Please type the login and/or group name which should be the NEW OWNER (e.g. 'mylogin' or 'mylogin:staff'): "
read NEWUSERANDGROUP
echo

find /Applications -user $OLDUSER -maxdepth 1 -exec echo sudo chown -R $NEWUSERANDGROUP \"{}\" \; > $TMPFILE
echo sudo chown -R $NEWUSERANDGROUP /anaconda* >> $TMPFILE

cat $TMPFILE
echo

# Anzeige der Aenderungen
echo -n "Should I run the upper commands (file: $TMPFILE) to change the login and group ? (y/n) : "
read USERINPUT
echo

# Abfrage ob Aenderungen wirklich gemacht werden sollen (und ggf. Abbruch)
if [ $USERINPUT != y ]
then
	rm $TMPFILE
	echo "EXIT. NOTHING CHANGED NOW."
	exit -1
fi

# Aenderungen durchfuehren
echo
echo "Please wait ..."
bash $TMPFILE
rm $TMPFILE

# Schreibe diesen neuen Eigentuemer nach $USERANDGROUPFILE fuer spaetere NEUE Software
echo "CONFIGURE: $USERANDGROUPFILE"
echo '# this value define the default user and group for some new apps' > $USERANDGROUPFILE
echo 'USERANDGROUP="'$NEWUSERANDGROUP'"' >> $USERANDGROUPFILE
echo
echo "FILE $USERANDGROUPFILE IS CHANGED TO:"
echo
cat $USERANDGROUPFILE
echo

echo "END OF SCRIPT. EXIT NOW."

exit 0

