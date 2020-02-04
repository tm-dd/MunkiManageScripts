#!/bin/bash
#
# Some settings for the scripts. Feel free to change it.
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

pathOfMunkiData='/usr/local/MunkiData'
pathOfScripts="${pathOfMunkiData}"'/scripts_and_configs'
pathOfSoftware="${pathOfMunkiData}"'/software'
pathOfMunkiRepo='/Library/WebServer/Documents/testing'

# the testing and the stable path of the Munki database
munkiTestingPath="${pathOfMunkiRepo}"
munkiStablePath='/Library/WebServer/Documents/repo'

# the csv file with all informations about the repository
FileMunkiInfos=${pathOfScripts}'/munki_infos.csv'

# the csv file, which definde the munki presets
MunkiManifestConfig=${pathOfScripts}'/munki_manifests.csv'

# folder of internal files for the import
munkiInternalFiles=${pathOfMunkiData}'/munki_repo_preset_icon_and_config_files'

# PATH of uninstall scripts or packages on the munki server
UNINSTALLFILESPATH=${munkiInternalFiles}'/uninstall_scripts'

# PATH of install check scripts on the munki server
INSTALLCHECKSCRIPTSPATH=${munkiInternalFiles}'/installcheck_scripts'

# this file contains all group names for the '.htgroups' file, to protect software for unallowed access
ACCESSGROUPFILE=${munkiInternalFiles}'/htgroups_and_protected_software.config'

# folder for the munki manifests (the files will be created based on the csv file)
munkiManifestOffsets=${munkiInternalFiles}'/munki_manifests'

# folder for the munki manifests (the files will be created based on the csv file)
munkiIconOffsets=${munkiInternalFiles}'/icons_offset'

# list of all manifest which include other catalogs
INCLUDEDCATALOGSFILE=${munkiInternalFiles}'/included_manifests.config'

# the file with logins and password hashes for accounts
HTUSERSFILE=${pathOfScripts}'/.htusers'

# this file which contains the groups for htaccess and her accounts
HTGROUPSFILE=${pathOfScripts}'/.htgroups'

# backup file with clear text passwords
MUNKIPASSWORDLOGFILE=${pathOfScripts}'/munki-passwords.txt'
SAVECLEARTEXTPASSWORDS="y"
