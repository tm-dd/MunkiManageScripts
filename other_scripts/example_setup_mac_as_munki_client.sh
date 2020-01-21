#!/bin/bash
#
# setup the current Mac as a Munki client
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

set -x

MunkiSoftwareRepoURL="https://munki.example.org/repo/"
MunkiDefaultManifest="standard_mac_en"

echo "SETUP the Munki server and the Munki repository ..."
echo
sudo defaults write /Library/Preferences/ManagedInstalls SoftwareRepoURL $MunkiSoftwareRepoURL
sudo defaults write /Library/Preferences/ManagedInstalls ClientIdentifier $MunkiDefaultManifest
echo

echo "FIND the current user (if possible) and define him as owner for new apps"
CURRENTUSER=''
NUMCONSOLEUSERS=`who | grep console | awk -F ' ' '{ print $1 }' | wc -l | awk -F ' ' '{ print $1 }'`

if [ "$NUMCONSOLEUSERS" -eq "1" ]
then
    # only one user is logged in -> use this one
    CURRENTUSER=`who | grep console | awk -F ' ' '{ print $1 }'`
else
    # use the user, who was starting the munki software GUI
    CURRENTUSER=`ps awux | grep "/Applications/Managed Software Center.app" | grep -v grep | awk -F ' ' '{ print $1 }'`
fi

# if a user was found, use this one as default user
if [ "$CURRENTUSER" != '' ]
then
    USERANDGROUP="$CURRENTUSER:staff"
    echo "DEFINE $USERANDGROUP as new standard user and group for some new apps"
    sudo echo '# this value define the default user and group for some new apps' > /usr/local/default_user_and_group.cfg
    sudo echo 'USERANDGROUP="'$USERANDGROUP'"' >> /usr/local/default_user_and_group.cfg
fi

echo "RUN the first Munki update process ..."
echo
sudo /usr/local/munki/managedsoftwareupdate
echo

echo "GET the informations about the configuration ..."
echo
defaults read /Library/Preferences/ManagedInstalls
echo
defaults read /Library/LaunchDaemons/com.googlecode.munki.managedsoftwareupdate-check.plist
echo

set +x

exit 0
