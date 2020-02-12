#!/bin/bash
#
# a 'quick and dirty' script to manage account for Munki
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


##############################
## DEFINITIONS AND FUNCTION ##
##############################

# read settings
source "`dirname $0`/config.sh"

# read login name from command line 
LOGIN=$2

# Hilfe ausgeben
function getHelp
{
    echo '
Use this dick-and-dirty script to manage your Munki accounts and groups to access protected software.

   PARAMETERS:

   -h ... get this short help
   -l ... list all Munki accounts and here groups
   -c ... list Munki catalogs and needed groups
   -m ... get the list of manifests for clients (to use as "ClientIdentifier") and her included manifests
   -f ... get the file names for the Munki accounts and groups  
   -p LOGIN ... set/change the password for LOGIN
   -d LOGIN ... delete the LOGIN
   -i LOGIN ... shows which groups LOGIN can (not) use
   -a LOGIN ... add LOGIN to a group
   -r LOGIN ... remove LOGIN from a group
   '
   
    exit
}


######################
## WRONG PARAMETERS ##
######################


# input wrong parameters
if ! [ "$1" == "-h" -o "$1" == "-l" -o "$1" == "-c" -o  "$1" == "-m" -o "$1" == "-f" -o "$1" == "-p" -o "$1" == "-d" -o "$1" == "-i" -o "$1" == "-a" -o "$1" == "-r" -o -z "$1" ]
then
    echo -e "\nERROR: WRONG PARAMETERS.";
    getHelp
fi

# get a short help
if [ "$1" == "-h" ] || [ -z "$1" ]
then
    getHelp
fi

# error: use '-p' without parameter
if [ "$1" == "-p" ] && [ -z "$2" ]
then
    echo -e "\nEROOR: Missing parameter for option.";
    getHelp
fi

# error: use '-d' without parameter
if [ "$1" == "-d" ] && [ -z "$2" ]
then
    echo -e "\nEROOR: Missing parameter for option.";
    getHelp
fi

# error: use '-i' without parameter
if [ "$1" == "-i" ] && [ -z "$2" ]
then
    echo -e "\nEROOR: Missing parameter for option.";
    getHelp
fi

# error: use '-a' without parameter
if [ "$1" == "-a" ] && [ -z "$2" ]
then
    echo -e "\nEROOR: Missing parameter for option.";
    getHelp
fi

# error: use '-r' without parameter
if [ "$1" == "-r" ] && [ -z "$2" ]
then
    echo -e "\nEROOR: Missing parameter for option.";
    getHelp
fi


#####################################
## CREATE CONFIGE FILES, IF MISSED ##
#####################################


# the $HTUSERSFILE must exists to add a new account
if [ ! -f "${HTUSERSFILE}" ]
then
    echo "INFO: creating new file '${HTUSERSFILE}' ... PLEASE CHANGE THE FILE PERMISSIONS"
    touch ${HTUSERSFILE}
fi

# the $HTGROUPSFILE must exists to use read groups
if [ ! -f "${HTGROUPSFILE}" ]
then
    echo "INFO: creating new file '${HTGROUPSFILE}' ... PLEASE CHANGE THE FILE PERMISSIONS"
    touch ${HTGROUPSFILE}
fi


#############################
## SINGLE PARAMTER OPTIONS ##
#############################


# list all Munki accounts and groups
if [ "$1" == "-l" ]
then
    echo -e "\nFound the following Munki ACCOUNTS:\n";
    awk -F ':' '{ print " * " $1 }' ${HTUSERSFILE} | sort -u
    echo -e "\nFound the following Munki GROUPS: \n";
    awk -F ':' '{ print " * " $1 }' ${HTGROUPSFILE} | sort -u
fi


# list all Munki catalogs and necessary groups
if [ "$1" == "-c" ]
then
    echo -e "\nTo use the following Munki manifests you need to be in this groups:\n"
    
    PROTECTEDCATALOGS=`cat ${ACCESSGROUPFILE} | grep -v '^#' | awk -F ' : ' '{ print $3 }' | sort -u`
    
    for CATALOG in `echo ${PROTECTEDCATALOGS}`
    do
        
        GROUPNAMES=`grep ${CATALOG} ${ACCESSGROUPFILE} | grep -v '^#' | awk -F ' : ' '{ print $1 }'`
        
        for GROUPNAME in `echo ${GROUPNAMES}`
        do
            # get the groups and manifest from ${ACCESSGROUPFILE}
            echo "   * CATALOG '${CATALOG}' needs accounts from GROUP '${GROUPNAME}'"

            # get the groups and manifest from ${INCLUDEDCATALOGSFILE}
            INCLUDEDCATALOGS=`grep "${CATALOG}" "${INCLUDEDCATALOGSFILE}" | awk -F ' : ' '{ print $1 }'`
            for INCLUDEDCATALOG in `echo ${INCLUDEDCATALOGS}`
            do
                echo "   * CATALOG '${INCLUDEDCATALOG}' needs accounts from GROUP '${GROUPNAME}'"
            done
        done
        
    done | sort -u
fi


# list all Munki manifests and groups
if [ "$1" == "-m" ]
then
    echo -e "\nMunki clients can use this manifests as 'ClientIdentifier' :\n";
    cat ${INCLUDEDCATALOGSFILE} | awk -F ':' '{ print $1 "  (INCLUDE:" $2 ")\n" }'
fi


#############################
## DOUBLE PARAMTER OPTIONS ##
#############################

# setup a new account or change a password
if [ "$1" == "-p" ]
then

    # login from command line 
    LOGIN=$2

    # input password (visible)
    PASSWORD=''; echo;
    while [ -z "$PASSWORD" ]
    do
        echo -n 'Please enter the password for the account "'${LOGIN}'" (not hidden input): '
        read PASSWORD
    done
    echo

    # create a backup file
    cp -a ${HTUSERSFILE} /tmp/.htusers.last

    # set password
    htpasswd -B -b "${HTUSERSFILE}" "${LOGIN}" "${PASSWORD}"

    # get password hash
    HASH=`python -c 'import base64; print "%s" % base64.b64encode("'${LOGIN}':'${PASSWORD}'")'`
    echo -e '\nOn the Munki client please type now:\n\n\tsudo defaults write /Library/Preferences/ManagedInstalls.plist AdditionalHttpHeaders -array "Authorization: Basic '${HASH}'"\n'

    # write the password to the password file
    if [ "${SAVECLEARTEXTPASSWORDS}" = "y" ]
    then
        echo -n "SET NEW PASSWORD '${PASSWORD}' FOR '${LOGIN}' ">> ${MUNKIPASSWORDLOGFILE}
        date "+ON %Y-%m-%d %H:%M:%S" >> ${MUNKIPASSWORDLOGFILE}
        echo -e '   USE ON CLIENT: sudo defaults write /Library/Preferences/ManagedInstalls.plist AdditionalHttpHeaders -array "Authorization: Basic '${HASH}'"\n' >> ${MUNKIPASSWORDLOGFILE}
        chmod 600 ${MUNKIPASSWORDLOGFILE}
    fi

    # show changes
    (echo; set -x; diff /tmp/.htusers.last ${HTUSERSFILE})

fi


# delete the account LOGIN
if [ "$1" == "-d" ]
then

    # login from command line 
    LOGIN=$2

    # create a backup file
    cp -a ${HTUSERSFILE} /tmp/.htusers.last

    # delete the account 
    echo; htpasswd -D "${HTUSERSFILE}" "${LOGIN}"

    # remove the password to the password file
    if [ "${SAVECLEARTEXTPASSWORDS}" = "y" ]
    then
        echo -n "REMOVE ACCOUNT '${LOGIN}' ">> ${MUNKIPASSWORDLOGFILE}
        date "+ON %Y-%m-%d %H:%M:%S" >> ${MUNKIPASSWORDLOGFILE}
        echo >> ${MUNKIPASSWORDLOGFILE}
    fi
    
    # show changes
    (echo; set -x; diff /tmp/.htusers.last ${HTUSERSFILE})

fi


# list all files for the Munki accounts and groups
if [ "$1" == "-f" ]
then
    echo -e "\nFILES FOR THE HTACESS OF MUNKI:\n"
    echo " * The Munki ACCOUNTS should be define here: '${HTUSERSFILE}'"
    echo " * The Munki GROUPS should be define here: '${HTGROUPSFILE}'"
    if [ -f "${MUNKIPASSWORDLOGFILE}" ]; then echo " * Used logins and password will be stored in: '${MUNKIPASSWORDLOGFILE}'"; fi
    echo " * The following file contains the information about the nesseary groups and catalogs for protected software: '${ACCESSGROUPFILE}'"
    echo -e " * Look at the following file to see which catalog import which other catalogs: '${INCLUDEDCATALOGSFILE}'\n"
    echo "!!! Please verify if your Munki repository use this files to protect your packages. Check the '.htaccess' files, there. !!!"
fi


#########################
# BUILD LISTS FOR LOGIN #
#########################

# get the list of groups where LOGIN is members of
export ISINGROUP=`awk -v search=" ${LOGIN} " -F ':' '{ if ($2 ~ search) print $1 }' "${HTGROUPSFILE}" | sort -u`

# get a list of all groups
export LISTOFALLGROUPS=`awk -F ":" '{ print $1 }' ${ACCESSGROUPFILE} | grep -v "^# group_name " | sort -u`

# build the list of groups where LOGIN is NOT a member of
export ISNOTINGROUP=''
for g in ${LISTOFALLGROUPS}
do
    FOUND='n'
    for e in ${ISINGROUP}
    do
        if [ "${g}" = "${e}" ]
        then
            FOUND='y'
        fi
    done
    if [ "${FOUND}" = 'n' ]; then ISNOTINGROUP="${ISNOTINGROUP} ${g}"; fi
done


# get the groups how LOGIN have access
if [ "$1" == "-i" ]
then
    
    echo -e "\nThe account '${LOGIN}' have access to the following: GROUP:SOFTWARE:MANIFEST \n"
    for g in ${ISINGROUP}; do grep "${g}" "${ACCESSGROUPFILE}" | sort -u | sed 's/^/   /g'; done
    for g in ${ISINGROUP}; do if [ -z "`grep "^\${g} :" "${ACCESSGROUPFILE}"`" ]; then echo "   *** FOUND UNUSED GROUP '${g}' IN '${HTGROUPSFILE}'. ***"; fi done

    echo -e "\nBut he CAN'T ACCESS to this: GROUP : SOFTWARE : MANIFEST \n"
    for g in ${ISNOTINGROUP}; do grep "${g}" "${ACCESSGROUPFILE}" | sort -u | sed 's/^/   /g'; done

    if [ -z "`grep ${LOGIN}: ${HTUSERSFILE}`" ]; then echo -e "\nWARNING: The account '${LOGIN}' is NOT ACTIVE in '${HTUSERSFILE}'."; fi
    
fi


# add LOGIN to a group
if [ "$1" == "-a" ] && [ -n "$2" ]
then
    
    if [ -z "${ISNOTINGROUP}" ]; then echo -e "\nThe '${LOGIN}' is already in ALL groups of Munki.\n"; exit; fi

    echo -e "\nPossible groups to add the '${LOGIN}' are:\n"
    for i in ${ISNOTINGROUP}; do echo " * $i"; done

    # input group
    NEWGROUP=''; echo;
    while [ -z "$NEWGROUP" ]
    do
        echo -n 'Add "'${LOGIN}'" to the group: '
        read NEWGROUP
        # test if the input is a valid name
        if [ -z "`echo ${LISTOFALLGROUPS}' ' | grep ${NEWGROUP}`" ]; then echo "Wrong group: '${NEWGROUP}'"; NEWGROUP=''; fi
    done
    echo
    
    # all group, if missing
    FOUNDLINES=`grep "${NEWGROUP}:" ${HTGROUPSFILE} | wc -l`
    if [ "${FOUNDLINES}" -lt 1 ]; then echo "${NEWGROUP}: " >> ${HTGROUPSFILE}; fi
    
    # put the login to the group
    sed -i '.last' "s/$NEWGROUP: /$NEWGROUP: $LOGIN /" ${HTGROUPSFILE}
    
    (echo; set -x; diff ${HTGROUPSFILE}.last ${HTGROUPSFILE})
    
fi


# remove LOGIN from a group
if [ "$1" == "-r" ] && [ -n "$2" ]
then
    ISINGROUP=`awk -v search=" ${LOGIN} " -F ':' '{ if ($2 ~ search) print $1 }' "${HTGROUPSFILE}"`
    GROUPLIST=`echo ${ISINGROUP} | sed 's/\$/ /g'`

    if [ "${GROUPLIST}" = " " ]; then echo -e "\nThe '${LOGIN}' is NOT in ANY group of Munki.\n"; exit; fi

    echo -e "\nYou can remove '${LOGIN}' from the following groups:\n"
    for i in ${GROUPLIST}; do echo " * $i"; done
    
    # input group
    OLDGROUP=''; echo;
    while [ -z "$OLDGROUP" ]
    do
        echo -n 'Remove "'${LOGIN}'" from the group: '
        read OLDGROUP
        # test if the input is a valid name
        if [ -z "`echo ${LISTOFALLGROUPS}' ' | grep ${OLDGROUP}`" ]; then echo "Wrong group: '${OLDGROUP}'"; OLDGROUP=''; fi
    done
    echo
    
    # remove the login to the group
    cp -a ${HTGROUPSFILE} ${HTGROUPSFILE}.last
    grep -v "$OLDGROUP: " ${HTGROUPSFILE} > ${HTGROUPSFILE}.t1
    grep "$OLDGROUP: " ${HTGROUPSFILE} | sed "s/$LOGIN //g" > ${HTGROUPSFILE}.t2
    cat ${HTGROUPSFILE}.t1 ${HTGROUPSFILE}.t2 | sort -u > ${HTGROUPSFILE}
    rm ${HTGROUPSFILE}.t1 ${HTGROUPSFILE}.t2
    
    (echo; set -x; diff ${HTGROUPSFILE}.last ${HTGROUPSFILE})
    
fi

echo

exit 0
