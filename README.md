# MunkiManageScripts

Some (quick and dirty) scripts to manage a Munki repository, based on CSV files.
I currently manage more the hundert Macs with nearly 400 possible Applications, based on Munki with this simple bash scripts.

## WHY not use MunkiAdmin ?

On smaler software repositories it should be easier to use MunkiAdmin.

But if you need:
* to update more the 100 packages
* to configure access to commercial packages to different clients (with a tool)
* to define a lot of different Munki manifests

it could be much easier to use MunkiManageScripts manage your repository
It define the rules in text files and have scripts from updating whole repository to single packages.

## How it works:

The script **create_munki_import_and_remove_scripts.sh** create scripts for importing and removing of your defined software in "munki_infos.csv".

A different script **update_manifests.sh** read the rules from "munki_manifests.csv" and create induvidual manifests for your Macs.

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

With the script **manage_software_access.sh** you can **configure your** clients and allow or permit the download of **commercial licences**. 

## Please view the following video demonstration (with scripts versions before 2020-10-02):

http://developer.thomastrid.de/Example_Using_MunkiManageScripts.mp4

## How to use:

* View the video demonstration, to see how the scripts works.
* Copy the directory "MunkiData" into "/usr/local/" (or to an other place).
* Change the configuration file "MunkiData/scripts_and_configs/config.sh".
* Create software directories and place your packages and icons.
* Adapt the example files "munki_infos.ods" and "munki_manifests.ods" and create new valid CSV files (look to the examples) for your software.
* Run "MunkiData/scripts_and_configs/create_all_scripts_and_manifests.sh" to create the scripts for importing and removing software and your own manifests.
* Start "MunkiData/scripts_and_configs/create_new_munki_repository.sh" to create a new  munki testing repository.
* Use "MunkiData/scripts_and_configs/manage_software_access.sh" to manage which clients can download commercial or other non-public software packages.
* Try you new Munki testing repository.
* Start "MunkiData/scripts_and_configs/make_munki_testing_to_stable.sh" and make the testing repository as your stable one.

## Well-known stumbling block:

* Avoid using of the charter '-' in combination of numbers (like adobe_il_2020-01-13_en_Install.dmg) in Munki packages. Sometimes Munki could to find this software, later.
* Do not use the String combination '","' in the description CSV files, because this is the delimiter of the fields. Please use '" , "' or other combinations instead.


Thomas Mueller <><
