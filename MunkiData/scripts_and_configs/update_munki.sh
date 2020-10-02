#!/bin/bash
#
# a start script to create files and the whole repository
#
# Copyright (c) 2020 tm-dd (Thomas Mueller)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#


#
# SETTINGS
#

source "`dirname $0`/config.sh"
SERVER='munki'
REPOURL='smb://munki@munki/munki'
REPOPATH='/Volumes/munki/repositories'


#
# CHECK THE MUNKI_PATH
#

if [ ! -d "${REPOPATH}" ]
then
	echo "Try to mount ${REPOURL} ."
	open ${REPOURL}
	sleep 10
	if [ ! -d "${REPOPATH}" ]
	then
		echo "ERROR: Could not found ${REPOPATH}. Is ${REPOURL} mounted ?"
		exit -1
	fi
fi


#
# SOME NOTES
#

echo
echo 'Use "'$0' testing" to update the munki testing repository and stop.'
echo 'Use "'$0' stable" to update the munki testing repository and move it to STABLE.'
echo 'Use "'$0' * --debug" to enable the debug mode.'
echo
sleep 3


#
# CREATE IMPORT AND REMOVE SCRIPTS
#

bash ${pathOfScripts}/create_all_scripts_and_manifests.sh "$2"


#
# REMOVE OLD AND CREATE A NEW MUNKI REPOSITORY 
#

echo 
echo '*** SYNC CONFIGURATION FILES ***'
echo

( set -x; rsync -av --delete ${pathOfMunkiData} root@${SERVER}:${pathOfMunkiData} )

if [ "$1" == "filesOnly" ]
then
	echo -e "\n*** Files are created and synced. STOP NOW. ***\n" 
	exit 0
fi

echo 
echo '*** START CREATING A NEW REPOSITORY in 5 seconds ***'
echo
sleep 5

caffeinate -i ${pathOfScripts}/create_new_munki_repository.sh testing 

echo
sleep 5


#
# UPDATE LOCAL MUNKI SOFTWARE (TO CHEKC THE REPOSITORY)
#

caffeinate -i sudo /usr/local/munki/managedsoftwareupdate
echo
echo "INSTALL THE LOCAL UPDATES, NOW."
echo
caffeinate -i sudo /usr/local/munki/managedsoftwareupdate --installonly
caffeinate -i sudo /usr/local/munki/managedsoftwareupdate
echo


#
# SOME NOTES TO / OR UPDATE THE TESTING TO THE DEFAULT REPO
#

case "$1" in
testing)	echo "run ${pathOfScripts}/make_munki_testing_to_stable.sh to make the repository to stable, later";;
stable)		caffeinate -i /bin/bash ${pathOfScripts}/make_munki_testing_to_stable.sh move;;
*) echo "Press ENTER to move or sync the testing repository to stable, if it's OK."
   read
   caffeinate -i /bin/bash ${pathOfScripts}/make_munki_testing_to_stable.sh;;
esac

echo
date
exit 0
