#!/bin/bash
#
# by Thomas Mueller
# setup the current user as default user for apps
# last Update: 2019-09-14
#

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

exit 0
