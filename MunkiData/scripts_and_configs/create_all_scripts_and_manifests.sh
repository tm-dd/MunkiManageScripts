#!/bin/bash
#
# a start script
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

# read settings
source "`dirname $0`/config.sh"

date
echo

# create a new file which should contains all used groups in the later '.htgroups' file
echo '# group_name : protected_munki_software : munki_catalog #' > ${ACCESSGROUPFILE}

# for all folders with software, create munki import and remove scripts
for i in $(ls -1d "${pathOfSoftware}"'/'* | grep -v '.txt$\|.asc$')
do
	if [ "$1" == '--debug' ]
		then "${pathOfScripts}/create_munki_import_and_remove_scripts.sh" "$1" $i "${munkiTestingPath}"; echo
		else "${pathOfScripts}/create_munki_import_and_remove_scripts.sh" $i "${munkiTestingPath}"
	fi
done


# update the Munki manifests
bash ${pathOfScripts}/update_manifests.sh

echo
echo "Import and remove scripts and Munki manifests are (hopefully) created now."
echo "To update Munki please start: ${pathOfScripts}/create_new_munki_repository.sh"
echo

date

exit 0
