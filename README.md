# MunkiManageScripts

Some (quick and dirty written) scripts to manage a Munki repository, based on CSV files.
I currently manage more the hundert Macs with nearly 400 possible Applications, based on Munki with this simple bash scripts.

## How it works:

The script **create_munki_import_file_for_packages.sh** create scripts for importing and removing of your defined software in "munki_infos.csv".

A different script **create_munki_manifests.sh** read the rules from "munki_manifests.csv" and create induvidual manifests for your Macs.

For **all of your applications** you can **define the following settings** in the CSV file "munki_infos.csv" for you Munki repository (and self service):

* password protection (only allowed clients can download and install software)
* catalog name
* category
* the description
* the display name
* the developer name
* define software as: silent install or silent uninstall or put it to the self service
* minimal and maximum versions of macOS
* software dependencies (required software)
* software updates (for automatic patching)
* logout and restart actions, after installing
* uninstall rules and scripts
* individual check scripts (for special cases)
* options for installing packages
* and more (patch version number, ...)

With the script **manage_software_access.sh** you can handle your clients and allow or permit the download of commercial applications. 

**Please view the following video demonstration:** http://developer.thomastrid.de/Example_Using_MunkiManageScripts.mp4

Well-known stumbling block:

* Avoid using of the charter '-' in combination of numbers (like adobe_il_2020-01-13_en_Install.dmg) in Munki packages. Sometimes Munki could to find this software, later.
* Do not use the String combination '","' in the description CSV files, because this is the delimiter of the fields. Use '" , "' or other combinations instead.

Thomas Mueller <><
