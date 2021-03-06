#!/bin/bash
#
# this script setup Munki on a lokal Mac
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

####### DEFINITIONS #######

# read settings
source "`dirname $0`/config.sh"

# directory of the software for the importing
if [ "$1" != "" -a "$1" != "stable" -a "$1" != "testing" -a "$1" != "debug" -a "$1" != "useRepo" -a "$1" != "doNotImport" ]
then
    munkiTestingPath="$1"
fi

####### HELP AND DEBUG ######

if [ "$1" == "help" -o "$1" == "--help" ]
then
    echo
    echo "Parameters are: [ ThePathOfTheSoftwareDirectory | stable | testing | useRepo | doNotImport | debug | help | --help ]"
    echo "Example 1: $0 '$munkiTestingPath' stable"
    echo "Example 2: $0 '$munkiTestingPath' debug"
    echo "Example 3: $0 '$munkiTestingPath'"
    echo "Example 4: $0"
    echo
    exit 0
fi

if [ "$1" == "debug" -o "$2" == "debug" ]
then
    set -x
fi

####### CREATE THE NEW MUNKI REPOSITORY #######

date

if [ "$1" != "useRepo" -a "$2" != "useRepo" ]
then

    # remove the old Munki repository directory and create new directorys
    rm -rf "$munkiTestingPath" || (echo "ERROR. Press CTRL + C !!!"; read)
    mkdir -p "$munkiTestingPath"
    cd "$munkiTestingPath" || (echo "ERROR. Press CTRL + C !!!"; read)
    mkdir -p catalogs manifests pkgs pkgsinfo icons
    chmod -R a+rx "$munkiTestingPath"
    
    # configure Munki
    echo
    echo 'Please setup a new Munki installation.'
    echo 'You can use a path like "'$munkiTestingPath'" for the repository on a webserver and as "default catalog" e.g. the name "standard_mac_en".'
    echo 'The other fields can be empty to use the default settings, as your option.'
    echo
       
    # create a new Munki repository configuration (also possible with: "/usr/local/munki/munkiimport --configure")
    defaults write ~/Library/Preferences/com.googlecode.munki.munkiimport.plist 'default_catalog' ''
    defaults write ~/Library/Preferences/com.googlecode.munki.munkiimport.plist 'editor' ''
    defaults write ~/Library/Preferences/com.googlecode.munki.munkiimport.plist 'pkginfo_extension' '.plist'
    defaults write ~/Library/Preferences/com.googlecode.munki.munkiimport.plist 'repo_path' "$munkiTestingPath"
    defaults write ~/Library/Preferences/com.googlecode.munki.munkiimport.plist 'repo_url' ''

fi

# copy munki manifests and icons
echo; echo "COPPING manifests and icons ..."; echo

set -x
mkdir -p "${munkiTestingPath}/manifests/" "${munkiTestingPath}/icons"
cp ${munkiManifestOffsets}/* "${munkiTestingPath}/manifests/"
cp ${munkiIconOffsets}/* "${munkiTestingPath}/icons/"
chmod 644 ${munkiTestingPath}/manifests/* ${munkiTestingPath}/icons/*
ls -l "${munkiTestingPath}/manifests/"
ls -l "${munkiTestingPath}/icons/"
set +x
echo

####### IMPORTING SOFTWARE TO MUNKI #######

if [ "$1" != "doNotImport" -a "$2" != "doNotImport" ]
then

    echo; echo "IMPORT software ..."; echo
    
    # Fileseperator neu setzen
    OIFS=$IFS
    IFS=$'\n'

    NUMBEROFIMPORTS=`find $pathOfSoftware -name import_*_to_munki.sh | wc -l | awk '{ print $1 }'`
    NUMBERIMPORT=1

    for importfile in `find $pathOfSoftware -name import_*_to_munki.sh`
    do
        # if running in debug mode, ask before executing any import file
        if [ "$1" == "debug" -o "$2" == "debug" ]
        then
            IMPORT="ask"
            echo; echo -n "Should the file '$importfile' execute now ? (y/*) : "
            read IMPORT
        else
            IMPORT='y'
        fi
            
        if [ "$IMPORT" == "y" ]
        then
            # goto to the directory of the script
            cd `dirname "$importfile"`

            # a progress message for the user 
            echo; echo "Start import script ${NUMBERIMPORT} of ${NUMBEROFIMPORTS}:"; NUMBERIMPORT=$((${NUMBERIMPORT}+1))
            
            # import the Munki files
            bash "$importfile" "$munkiTestingPath"
        else
            echo -e "SKIPPING file '$importfile' by importing new software.\n"
        fi
    done
    
    # alten Fileseperator wieder setzen
    IFS=$OIFS

else

    echo -e "\nTHE SOFTWARE IMPORT WAS SKIPPED, BY USING THE OPTION 'doNotImport'.\n\n"

fi

# setup the access rights for the webserver
chmod -R 755 "$munkiTestingPath"

date

####### TESTS AND CHANGE TO STABLE #######

(
    set +x
    echo -e "\n\n*** THE TESTING MUNKI REPO IS FINISH NOW. ***\n\n"
    echo "PLEASE TEST the new Munki TESTING repository NOW and continue."
    echo
)

ANSWER='';

# if the first or second parameter was "stable", do NOT ASK in the next while loop 
if [ "$1" == "stable" -o "$2" == "stable" ]
then
    ANSWER='stable';
fi

# if the first or second parameter is NOT "TESTING", allow the user to change the Munki repostitory to the stable URL
if [ "$1" != "testing" -a "$2" != "testing" ]
then
    # wait up to typing "stable" to change the testing to the stable repository
    set +x
    while [ "$ANSWER" != "stable" ]
    do
        echo -n "Write 'stable' to use the new TESTING repository as STABLE now or break with [Ctrl] + [C]. "
        read ANSWER
    done
    echo
    echo "OK, waiting 5 seconds and change the repositorys ..."
    echo

    (set -x /bin/bash `dirname $0`"make_munki_testing_to_stable.sh move")

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
fi

date

exit 0
