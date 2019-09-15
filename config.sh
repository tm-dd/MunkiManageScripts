#!/bin/bash

#
# settings for the scripts
#

pathOfScripts='/Data/Munki/scripts_and_configs'
pathOfSoftware='/Data/Munki/software'
pathOfMunkiRepo='/Library/WebServer/Documents/testing'

# the testing and the stable path of the Munki database
munkiTestingPath="${pathOfMunkiRepo}"
munkiStablePath='/Library/WebServer/Documents/repo'

# the csv file with all informations about the repository
FileMunkiInfos=${pathOfScripts}'/munki_infos.csv'

# the csv file, which definde the munki presets
MunkiManifestConfig=${pathOfScripts}'/munki_manifests.csv'

# folder of internal files for the import
# munkiInternalFiles=${pathOfMunkiRepo}'/munki/munki_internal_files'

# PATH of uninstall scripts or packages on the munki server
UNINSTALLFILESPATH=${pathOfSoftware}'/munki/munki_internal_files/uninstall_scripts'

# PATH of install check scripts on the munki server
INSTALLCHECKSCRIPTSPATH=${pathOfSoftware}'/munki/munki_internal_files/installcheck_scripts'

# this file contains all group names for the '.htgroups' file, to protect software for unallowed access
ACCESSGROUPFILE=${pathOfSoftware}'/munki/munki_internal_files/all_htgroups_and_protected_munki_software'

# folder for the munki manifests (the files will be created based on the csv file)
munkiManifestOffsets=${pathOfSoftware}'/munki/munki_internal_files/munki_manifests'

# folder for the munki manifests (the files will be created based on the csv file)
munkiIconOffsets=${pathOfSoftware}'/munki/munki_internal_files/icons_offset/'

# list of all manifest which include other catalogs
INCLUDEDCATALOGSFILE=${pathOfSoftware}'/munki/munki_internal_files/info_included_manifests'

# the file with logins and password hashes for accounts
HTUSERSFILE=${pathOfScripts}'/.htusers'

# this file which contains the groups for htaccess and her accounts
HTGROUPSFILE=${pathOfScripts}'/.htgroups'

# backup file with clear text passwords
MUNKIPASSWORDLOGFILE=${pathOfScripts}'/munki-passwords.txt'
SAVECLEARTEXTPASSWORDS="y"

