#!/bin/bash
#
# by Thomas Mueller
#

# read settings
source "`dirname $0`/config.sh"

ANSWER='unknown'

while [ "$ANSWER" = "unknown" ] 
do
    echo
    echo "please type:"
    echo " - 'move' to use the current TESTING repository as repository for STABLE as well"
    echo " - 'sync' to clone the current TESTING repository as STABLE"
    echo " - 'exit' to stop this script"
    echo
    echo -n "Your choice: "
    read ANSWER
    if [ "$ANSWER" = "move" ] || [ "$ANSWER" = "sync" ] || [ "$ANSWER" = "exit" ]; then true; else ANSWER='unknown'; fi
done

if [ "$ANSWER" = "exit" ]; then echo "Exit without changes."; exit 1; fi

echo
echo "OK, waiting 5 seconds and change the repositorys ..."
echo

if [ "$ANSWER" = "sync" ]
then
    echo "TRY RUN:"
    (set -x; rsync -avn --delete ${munkiTestingPath}/ ${munkiStablePath}/)
    echo
    echo "starting REAL SYNC in 30 seconds ..."        
    sleep 30
    (set -x; rsync -av --delete ${munkiTestingPath}/ ${munkiStablePath}/)
fi

if [ "$ANSWER" = "move" ]
then
    set -x
    df -h $munkiStablePath
    rm -rf $munkiStablePath
    mv $munkiTestingPath $munkiStablePath
    ln -s $munkiStablePath $munkiTestingPath
    chmod -R a+rx $munkiStablePath
    df -h $munkiStablePath
    set +x
fi

echo
echo "The new Munki repository is now found on the STABLE and testing URL."
echo
echo 'On the mac clients do: '
echo
echo '   1. install the Munki tools from: https://github.com/munki/munki/releases'
echo
echo '   2. use commands like this: (as an example):'
echo 
echo '      sudo defaults write /Library/Preferences/ManagedInstalls ClientIdentifier "standard_mac_en"              # or use an other repository like: "standard_mac_de", "full_mac_en" or "full_mac_de"'
echo '      sudo defaults write /Library/Preferences/ManagedInstalls SoftwareRepoURL  "https://'`hostname`'/repo/"   # to setup the URL to your repository'
echo '      sudo defaults read /Library/Preferences/ManagedInstalls                                                  # print the current settings of the munki client'
echo '      sudo /usr/local/munki/managedsoftwareupdate'
echo '      open /Applications/Managed\ Software\ Center.app'
echo
echo '   3. additionally install the "munki reports", at your choice'
echo

date

exit 0

