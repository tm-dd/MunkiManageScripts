#!/bin/bash
#
# a 'quick and dirty' script to get information about missed sub packages for munki
#
# Copyright (c) 2022 tm-dd (Thomas Mueller)
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

if [ "$1" -eq "" ]; then echo "USAGE: $0 PACKAGE"; exit -1; fi

echo
echo "Package: $1"
echo

echo "Possible sub packages:"
echo
installer -showChoicesXML -target / -pkg $1  | grep -A 1 "choiceIdentifier\|file://" | sed 's/^--$/\n/' | grep '<' | sed 's/<\/array>/\-\-/g'
echo

echo "possible Munki options for installer:"
echo
installer -showChoicesXML -target / -pkg $1 | grep -A 1 choiceIdentifier | grep -v '__ROOT_CHOICE_IDENT_DISTRIBUTION_TITLE' | grep string | awk -F '>\|<' '{ print "1:" $3 }' | tr '\n' ' '; echo
echo

echo "find missing packages:"
echo
sudo /usr/local/munki/managedsoftwareupdate -vvv | grep -B 2 -A 4 'Need to install '
echo

echo "The software 'Suspicious Package' can be very useful to inspect packages."
echo

exit 0
