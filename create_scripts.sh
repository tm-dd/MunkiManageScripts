#!/bin/bash
#
# by Thomas Mueller 
#

# read settings
source "`dirname $0`/config.sh"

echo
date

# create a new file which should contains all used groups in the later '.htgroups' file
echo '# group_name : protected_munki_software : munki_catalog #' > ${pathOfSoftware}/munki/munki_internal_files/all_htgroups_and_protected_munki_software

# for all folders with software, create munki import and remove scripts
for i in $(ls -1d "${pathOfSoftware}"'/'* | grep -v '.txt$\|.asc$')
do
	mkdir -p "${pathOfMunkiRepo}"
	"${pathOfScripts}/create_munki_import_and_remove_scripts.sh" $i "${pathOfMunkiRepo}"
done

echo
echo "Import and remove scripts are (hopefully) created now."
echo "Don't forget to update the manifest files, with: ${pathOfScripts}/update_manifests.sh"
echo "To update Munki please start: ${pathOfScripts}/create_new_munki_repository.sh"
echo

date
exit 0


