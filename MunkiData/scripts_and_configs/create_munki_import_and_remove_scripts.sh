#!/bin/bash
#
# analyse the CSV and create scripts to import and remove a software in Munki
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

########################################

# read settings
source "`dirname $0`/config.sh"

# debug mode
DEBUG="0"
if [ "$1" == "--debug" ]
then
    DEBUG="1"
    set -- "${@:2}" "${@:3}"
fi

# the path to the folder with the software files to import 
PkgPath="$1"

# check if the software path exists
if [ ! -d "$PkgPath" ]
then
    echo "ERROR: You need to define the folder with your software. Optional the folder for your Munki repository as the second parameter."
    echo "    Example 1: $0 /path/to/packages MunkiRepoPath"
    echo "    Example 2: $0 /Data/Munki/software/standard_pkgs /Library/WebServer/Documents/testing"
    exit -1
else
    cd "$PkgPath" || exit -1
fi

# the path to the new munki repository
MunkiRepoPath="$2"

# if not set, use the default $MunkiRepoPath
if [ ! -d "$MunkiRepoPath" ]
then
    MunkiRepoPath="$pathOfMunkiRepo"
fi

########################################

# Fileseperator neu setzen
OIFS=$IFS
IFS=$'\n'

# der Verzeichnisname aller dieser Pakete wird zur Kategorie im Munki
CATALOG=`basename $(pwd)`

# ohne Munki-Info-Datei kann es nicht weitergehen
if [ ! -f "$FileMunkiInfos" ]
then
    echo "ERROR: Could NOT FOUND the Munki config file: $FileMunkiInfos"
    exit -1
fi

# lege die Verzeichnisse fuer die Skripte zum Importieren und Loeschen der Software im Repository an und loesche ggf. alte Skripte
mkdir -p "$PkgPath/_remove_from_munki_"
mkdir -p "$PkgPath/_import_to_munki_"
rm -f $PkgPath/_remove_from_munki_/* $PkgPath/_import_to_munki_/*

########################################

#
# fuer alle Zeilen, die den Verzeichnisnamen in der ersten Spalte in der Datei $FileMunkiInfos haben
#

NumberOfSoftware=0

for i in $(grep "^"'"'$CATALOG'","' $FileMunkiInfos | sort -f)
do
    
    #
    # LESE MUNKI-PARAMETER
    #
    i=`echo $i | sed 's/,,/,"",/g' | sed 's/,,/,"",/g' | sed 's/,$/,""/'`               # damit wird erreicht das Zeilen wie '"WERT1",,,"WERT4",,' zu besser trennbaren Zeilen '"WERT1","","","WERT4","",""' werden
    i=`echo $i | sed 's/^"//g' | sed 's/"$//g'`                                         # dies entfernt das erste und letzte '"', da dieses Zeichen am Anfang und Ende nicht benoetigt wird    
    NAME=`echo $i | awk -F '","' '{ print $2 }'`                                        # der Name der Anwendung im $FileMunkiInfos (z.B.: "Adobe_Flash_Player")
    PAKETNAME=`ls -1 | grep -i "^$NAME" | sort -r | grep -i 'pkg\|dmg$' | head -n 1`    # den Dateinamen des Paketes finden im aktuellen Verzeichnis (falls mehrere Pakete mit $NAME anfangen (z.B. App X* ergibt: App X 10.pkg und App X 11.pkg), nimm die vermutlich Neuste)
    MUNKINAME=`echo $i | sed 's/ /_/g' | awk -F '","' '{ print $1 "_" $2 }'`            # der Munki-interne Name der App (z.B.: "standard_pkgs_Adobe_Flash_Player")
    CATEGORY=`echo $i | awk -F '","' '{ print $3 }'`                                    # die Kategorie der Software (z.B.: "network")
    DESCRIPTION=`echo $i | awk -F '","' '{ print $4 }'`                                 # ein Beschreibungstext (z.B.: "A browser plugin for some web content. ...")
    DISPLAYNAME=`echo $i | awk -F '","' '{ print $5 }'`                                 # der Anzeigename (z.B.: "Adobe Flash Player")
    DEVELOPER=`echo $i | awk -F '","' '{ print $6 }'`                                   # der Entwickler (z.B.: "https://get.adobe.com/de/flashplayer" als Angabe der Entwicklerseite des Mozillateams)
    SECTION=`echo $i | awk -F '","' '{ print $7 }'`                                     # Regeln zum Umgang mit der Software (z.B.: "optional_installs" fuer optionale Installationen am Client)
    MINOS=`echo $i | awk -F '","' '{ print $8 }'`                                       # die minimale Mac OS X die man benoetigt, um die Software installieren zu koennen
    MAXOS=`echo $i | awk -F '","' '{ print $9 }'`                                       # die maximale Mac OS X die man benoetigt, um die Software installieren zu koennen
    REQUIRES=`echo $i | awk -F '","' '{ print $10 }'`                                   # enthaellt die/den Munki-Namen von Software der fuer diese Software benoetigt wird
    UPDATEFOR=`echo $i | awk -F '","' '{ print $11 }'`                                  # kennzeichnet fuer welches Software diese Software ein Update darstellt
    ACTION=`echo $i | awk -F '","' '{ print $12 }'`                                     # damit kann man z.B. definieren ob nach der Installation ein Logout oder Reboot noetig ist
    UNINSTALLABLE=`echo $i | awk -F '","' '{ print $13 }'`                              # ueber true oder false definiert man ob die Anwedung deinstallierbar ist (Pakete die per Skript etwas aendern sind normalerweise nicht sauber deinstallierbar)
    OPTIONSINSTALLER=`echo $i | awk -F '","' '{ print $14 }'`                           # hier sollte eine Liste von Optionen im Format "NAME_1:WERT_1:NAME_2:WERT_2:..." stehen, die man beim Installieren verwendet werden sollen
    DONTCHECKPKGS=`echo $i | awk -F '","' '{ print $15 }'`                              # hier sollte eine Liste von Unter-Packetnamen im Format "org.gpgtools.p1:org.gpgtools.p2" stehen, die NICHT installiert werden muessen (und damit "optional" werden)
	INSTALLCHECKFILE=`echo $i | awk -F '","' '{ print $16 }'`							# falls gesetzt steht hier der Dateiname eines Skriptes, welches zum pruefen der Installation dient (ein return=0 bedeutet, die Software ist NICHT installiert)
    UNINSTALLFILE=`echo $i | awk -F '","' '{ print $17 }'`                              # Dateiname eines eigenes Uninstall -Skriptes oder Paketes fuer die Software, welches im Ordner $UNINSTALLFILESPATH liegen muss
    ALLOWUNTRUSTED=`echo $i | awk -F '","' '{ print $18 }'`                             # ueber "true" kann man definieren, dass auch Pakete ohne gueltiges Zertifikat erlaubt werden  
    REPLACEVERSION=`echo $i | awk -F '","' '{ print $19 }'`                             # falls gesetzt, ersetzt dies die Versionsnummer des Paketes nach dem Import
    EXTRAXMLOPTIONS=`echo $i | awk -F '","' '{ print $20 }'`                            # in dieser Spalte kann eigener XML Code angeben werden, der fuer die Software eingetragen werden soll
    ALLOWEDGROUPS=`echo $i | awk -F '","' '{ print $21 }'`                              # falls gesetzt, duerfen nur die Nutzer aus den Gruppen hier eingetragen der Liste der Art "gruppe1 gruppe2 ..." Zugang zur Software bekommen

    #
    # erstelle fuer jedes Paket Import-Zeilen fuer Munki
    #

    if [ "$DEBUG" == "1" ]; then echo "++ DEBUG: CSV NAME PART: $NAME  -  PACKAGE NAME: $PAKETNAME  -  MUNKI NAME: $MUNKINAME  -  MUNKI CATEGORY: $CATEGORY  -  HTACCESS GROUPS: $ALLOWEDGROUPS ++"; fi

    # falls das Paket in der CSV-Datei gefunden wird
    if [ -f "$PAKETNAME" ]
    then

        # $OutfileMunkiImport ist die zu erstellende Datei fuer das Importieren der Software ins Munki-Repository
        OutfileMunkiImport="$PkgPath/_import_to_munki_/import_${PAKETNAME}_to_munki.sh"
        
        # $OutfileMunkiRemove ist die zu erstellende Datei fuer das Loeschen der Software im Munki-Repository
        OutfileMunkiRemove="$PkgPath/_remove_from_munki_/remove_${PAKETNAME}_from_munki.sh"
 
        #####

        #
        # schreibe das Munki-Uninstaller-Skript mit der Angabe der aenderbaren Optionen
        #

        echo '#!/bin/bash
#
# by Thomas Mueller
#
# !!! AUTOMATED CREATED SCRIPT TO REMOVE SOFTWARE FROM A MUNKI REPOSITORY !!!
#

# the name of manifest
MunkiManifests="'$CATALOG'"

# the path to the Munki repository
if [ "$1" != "" ]
then    
    MunkiRepoPath="$1"
else
    MunkiRepoPath="'${MunkiRepoPath}'"
fi

#--------------- REMOVE: '${MUNKINAME}' ---------------#

echo "... removing '${MUNKINAME}' from munki"

# path to the plist file (munki tell that, by the import process) 
PlistPath=$(find "${MunkiRepoPath}/pkgsinfo/'${CATEGORY}'" -name "'${MUNKINAME}'*.plist" | sort | head -n 1)

# package path
PackagePath="${MunkiRepoPath}/pkgs/"`defaults read "${PlistPath}" installer_item_location`

# icon path
IconPath=${MunkiRepoPath}"/icons/'${MUNKINAME}'.png"

# remove the package
echo "      removing package: ${PackagePath}"
(rm "${PackagePath}" || echo "WARNING: Could not remove the package: ${PackagePath}")

# remove the icon
echo "      removing icon: ${IconPath}"
(rm "${IconPath}" || echo "WARNING: Could not remove the icon: ${IconPath}")

# remove the software from Munki
echo "      removing ${PlistPath} from manifest: $MunkiManifests"
/usr/local/munki/manifestutil remove-pkg "'${MUNKINAME}'" --manifest "$MunkiManifests" --section optional_installs

# remove the Plist file
echo "      removing plist: ${PlistPath}"
(rm "${PlistPath}" || echo "WARNING: Could not remove the plist file: ${PlistPath}")

# update catalog
/usr/local/munki/makecatalogs $MunkiRepoPath > /dev/null

exit 0
        ' > $OutfileMunkiRemove  # dieses Munki-Uninstaller-Skript ist hiermit abgeschlossen

        # ein kleines Hilfsskript um alle Pakete dieses Verzeichnisses aus dem Munki-Repository zu entfernen
        echo '#!/bin/bash

cd `dirname "$0"`
OIFS=$IFS
IFS=$'"'"'\n'"'"'
for i in remove_*_from_munki.sh
do
    /bin/bash "./$i"
    echo
done
IFS=$OIFS
exit 0
        ' > "$PkgPath/_remove_from_munki_/_remove_ALL_from_munki.sh"


        #####

        # ein kleines Hilfsskript um alle Pakete dieses Verzeichnisses zu importieren
        echo '#!/bin/bash

cd `dirname "$0"`
pwd
OIFS=$IFS
IFS=$'"'"'\n'"'"'
for i in import_*_to_munki.sh
do
    /bin/bash "./$i"
    echo
done
IFS=$OIFS
exit 0
        ' > "$PkgPath/_import_to_munki_/_import_ALL_to_munki.sh"

        #
        # starte Munki-Installer-Skript mit der Angabe der aenderbaren Optionen
        #

        echo '#!/bin/bash
#
# by Thomas Mueller
#
# !!! AUTOMATED CREATED SCRIPT TO IMPORT SOFTWARE TO A MUNKI REPOSITORY !!!
#

# setup now the Path of the *.pkg or *.dmg for import to munki
PKG=".."

# setup now the name of manifest for the later using computers (manifests can include other manifests)
MunkiManifests="'$CATALOG'"

# setup the path of the Munki repository
if [ "$1" != "" ]
then    
    MunkiRepoPath="$1"
else
    MunkiRepoPath="'${MunkiRepoPath}'"
fi

# go to the directory of the files
DIRNAME=`dirname "$0"`
cd $DIRNAME/.

# the munki temp folder for patching files
MunkiTmpDir="/tmp/munki_tmp_'${CATALOG}'_"`/bin/date +%Y-%m-%d_%Hh%Mm%Ss`
mkdir -p "$MunkiTmpDir"

# check if the package is allready imported
if [ -n "$(find ${MunkiRepoPath}/pkgsinfo/'${CATEGORY}' -name '${MUNKINAME}'*.plist 2> /dev/null | sort | '"sed -e 's/ /\\ /g' -e 's/\!/\\!/g' -e 's/(/\\(/g' -e 's/)/\\)/g'"' | head -n 1)" ]
then
    echo -e -n "\nINFORMATION: It looks like '${MUNKINAME}' is allready imported. - Please check: "
    find "${MunkiRepoPath}/pkgsinfo/'${CATEGORY}'" -name "'${MUNKINAME}'*.plist" | sort | head -n 1; echo
    exit 0
fi

# print an empty line, before the new lines for the package comes
echo ''

#--------------- IMPORT: '${MUNKINAME}' ---------------#

        ' > $OutfileMunkiImport

        #
        ## falls angegeben den Zugriffsschutz zu der Datei einrichten einrichten
        #
        
        if [ -n "$ALLOWEDGROUPS" ]
        then
        
            # Variablen fuer kuerzere Pfade
            echo '# if you know what you do, you can change this value here' >> $OutfileMunkiImport
            echo -e 'HTACCESSFILE=${MunkiRepoPath}/pkgs/'${CATEGORY}'/.htaccess'"\n" >> $OutfileMunkiImport

            # kurze Info an den Benutzer, dass eine '.htaccess'-Datei angelegt wird
            echo 'echo "... creating an .htaccess file for '$MUNKINAME'"' >> $OutfileMunkiImport
            echo 'sleep 1' >> $OutfileMunkiImport

            # lege das Verzeichnis fuer das Paket an, falls es noch nicht existiert
            echo -e 'mkdir -p ${MunkiRepoPath}/pkgs/'${CATEGORY}"\n" >> $OutfileMunkiImport

            # lege eine neue ".htaccess"-Datei an, wenn diese nicht existiert 
            echo 'if [ ! -e "$HTACCESSFILE" ]' >> $OutfileMunkiImport
            echo 'then' >> $OutfileMunkiImport
            echo '   echo "AuthType Basic" > $HTACCESSFILE'  >> $OutfileMunkiImport
            echo '   echo "AuthName \"Commercial Software\"" >> $HTACCESSFILE'  >> $OutfileMunkiImport
            echo '   echo "AuthUserFile '${HTUSERSFILE}'" >> $HTACCESSFILE'  >> $OutfileMunkiImport
            echo '   echo "AuthGroupFile '${HTGROUPSFILE}'" >> $HTACCESSFILE'  >> $OutfileMunkiImport                
            echo '   echo -e "Require all granted\n" >> $HTACCESSFILE'  >> $OutfileMunkiImport
            echo -e "fi\n" >> $OutfileMunkiImport
        
            # schraenke den Zugang zu dem Paket ein
            echo 'echo "<Files \"'$NAME'*\">" >> $HTACCESSFILE'  >> $OutfileMunkiImport
            echo 'echo "   Require group '$ALLOWEDGROUPS'" >> $HTACCESSFILE'  >> $OutfileMunkiImport
            echo -e 'echo "</Files>" >> $HTACCESSFILE'"\n"  >> $OutfileMunkiImport

            # eine Warnung ausgeben, falls AuthUserFile und AuthGroupFile nicht existieren
            echo 'if [ ! -e "'${HTUSERSFILE}'" ]; then echo "INFORMATION: AuthUserFile '${HTUSERSFILE}' not found. Please create it later."; fi' >> $OutfileMunkiImport
            echo -e 'if [ ! -e "'${HTGROUPSFILE}'" ]; then echo "INFORMATION: AuthGroupFile '${HTGROUPSFILE}' not found. Please create it later."; fi'"\n" >> $OutfileMunkiImport
            
            # erstelle eine Datei, welche alle Gruppen fuer die spaetere ".htgroups" enthaellt (nicht sehr effizient, aber funktional)
            touch $ACCESSGROUPFILE
            for group in "$ALLOWEDGROUPS"
            do
                echo "$group : $MUNKINAME : $CATALOG" >> $ACCESSGROUPFILE
            done
        
        fi

        #
        ## das Paket importieren
        #
        
        # falls es ein Uninstall-Paket (noetig z.B. bei Adobe CC) gibt, dieses beim Import angeben und die Variable $UNINSTALLFILE leeren
        if [ -n "`echo $UNINSTALLFILE | grep -e '\.pkg$' -e '\.mpkg$' -e '\.dmg$'`" ]
        then
            APPENDOPT=' --uninstallpkg "$PKG/'$UNINSTALLFILE'"'
            UNINSTALLFILE=''
        else
            APPENDOPT=''
        fi
        echo "# IMPORT $MUNKINAME TO MUNKI" >> $OutfileMunkiImport
        echo 'date' >> $OutfileMunkiImport
        echo "echo -n -e 'DEBUG: current directory: '\`pwd\`'\n' " >> $OutfileMunkiImport
        echo 'echo "... importing '$MUNKINAME' to munki"' >> $OutfileMunkiImport
        echo '(set -x; /usr/local/munki/munkiimport --name="'$MUNKINAME'" --subdirectory="'$CATEGORY'" --description="'$DESCRIPTION'" --catalog="'$CATALOG'" --category="'$CATEGORY'" --minimum_os_vers="'$MINOS'" --maximum_os_vers="'$MAXOS'" --displayname="'$DISPLAYNAME'" --developer="'$DEVELOPER'" --nointeractive "$PKG/'$PAKETNAME'"'$APPENDOPT')' >> $OutfileMunkiImport
        echo '' >> $OutfileMunkiImport

        #
        ## das neu importierte Paket nun patchen
        #

        # in diese Datei legt Munki nach Aufruf von "munkiimport" (im XML-Format) die Daten und Parameter des verwalteten Paketes ab
        echo '# find the plist file of the new package' >> $OutfileMunkiImport   
        echo 'PLISTPATH=$(find ${MunkiRepoPath}/pkgsinfo/'${CATEGORY}' -name '${MUNKINAME}'*.plist 2> /dev/null | sort | head -n 1)' >> $OutfileMunkiImport
        echo 'echo "DEBUG: Found plist file on: ${PLISTPATH}"' >> $OutfileMunkiImport
        echo '' >> $OutfileMunkiImport

        # Abhaengigkeit (Was muss installiert werden damit diese Software startbar ist ?) eintragen
        if [ -n "$REQUIRES" ]
        then
            echo '# Abhaengigkeit "requires" definieren' >> $OutfileMunkiImport
            echo 'echo "... patching software '$MUNKINAME' requires '$REQUIRES' for installing"' >> $OutfileMunkiImport
            echo 'for REQUIREITEM in '${REQUIRES}'; do' >> $OutfileMunkiImport
            echo '   ( set -x; defaults write "${PLISTPATH}" requires -array-add "$REQUIREITEM" )' >> $OutfileMunkiImport
            echo 'done' >> $OutfileMunkiImport
            echo '( set -x; plutil -convert xml1 "${PLISTPATH}" )'  >> $OutfileMunkiImport
            echo '' >> $OutfileMunkiImport
        fi

        # Abhaengigkeit (Ist diese Software ein Update fuer eine andere installierte Software ?) eintragen
        if [ -n "$UPDATEFOR" ]
        then
            echo '# Abhaengigkeit "update_for" definieren' >> $OutfileMunkiImport
            echo 'echo "... patching software '$MUNKINAME' is an update for '$UPDATEFOR' in the repository"' >> $OutfileMunkiImport
            echo 'for UPDATEITEM in '${UPDATEFOR}'; do' >> $OutfileMunkiImport
            echo '   ( set -x; defaults write "${PLISTPATH}" update_for -array-add "$UPDATEITEM" )' >> $OutfileMunkiImport
            echo 'done' >> $OutfileMunkiImport
            echo '( set -x; plutil -convert xml1 "${PLISTPATH}" )'  >> $OutfileMunkiImport
            echo '' >> $OutfileMunkiImport
        fi

        # Abhaengigkeiten (Muss man nach der Installation der Software: den Benutzer ausloggen, neustarten, ... ?) eintragen
        if [ -n "$ACTION" ]
        then
            echo '# Abhaengigkeit "RestartAction" definieren' >> $OutfileMunkiImport
            echo '( set -x; defaults write "${PLISTPATH}" "RestartAction" "'$ACTION'"' >> $OutfileMunkiImport
            echo 'plutil -convert xml1 "${PLISTPATH}" )'  >> $OutfileMunkiImport
            echo '' >> $OutfileMunkiImport
        fi

        # Bedingung (Kann die Software sauber deinstalliert werden ?) eintragen
        if [ -n "$UNINSTALLABLE" ]
        then
            echo '# Bedingung "uninstallable" definieren' >> $OutfileMunkiImport
            echo 'echo "... patching software '$MUNKINAME' requires the condition uninstallable='$UNINSTALLABLE' after installing"' >> $OutfileMunkiImport
            if [ "$UNINSTALLABLE" = "true" ]; then echo '( set -x; defaults write "${PLISTPATH}" "uninstallable" -bool true; plutil -convert xml1 "${PLISTPATH}" )' >> $OutfileMunkiImport; fi
            if [ "$UNINSTALLABLE" = "false" ]; then echo '( set -x; defaults write "${PLISTPATH}" "uninstallable" -bool false; plutil -convert xml1 "${PLISTPATH}" )' >> $OutfileMunkiImport; fi
            echo '' >> $OutfileMunkiImport
        fi

        # definiertes aktivieren/deaktivieren der Optionen des Paketes bei dessen Installation, welche man ueber "installer -showChoicesXML -pkg NAME.pkg -target /" angezeigt bekommt
        if [ -n "$OPTIONSINSTALLER" ]
        then
            # zuerst wird nach "<key>attributeSetting</key>" definiert ob eine Option gesetzt werden soll oder nicht
            echo '# Optionen fuer das "installer"-Kommando angeben (Welcher Harken wuerde bei der manuellen Installation gesetzt werden ?)' >> $OutfileMunkiImport
            echo 'echo "... patching software '$MUNKINAME' to setup options for the installer program"' >> $OutfileMunkiImport
            XML=$(echo "${OPTIONSINSTALLER}" | awk -F ':| ' '{ for (i=1; i<=NF; i++) { print "<dict><key>attributeSetting</key><integer>" $i "</integer><key>choiceAttribute</key><string>selected</string><key>choiceIdentifier</key>"; i++; print "<string>" $i "</string></dict>" } }')
            echo 'plutil -insert installer_choices_xml -xml "<array>'${XML}'</array>" "${PLISTPATH}"' >> $OutfileMunkiImport
            echo '' >> $OutfileMunkiImport
        fi
        
        # Unter-Pakete die nicht installiert werden sollen, muessen zusaetzlich im "receipts"-Abschnitt gekennzeichnet werden um zu verhindern, dass Munki beim naechsten "managedsoftwareupdate"-Lauf diese vermisst und das gesammte Paket erneut installiert
        if [ -n "$DONTCHECKPKGS" ]
        then
            # fuer alle nicht gewuenschten Pakete ist hier ist noch ein weiteres Patchen mit "<key>optional</key><true/>" im "<key>receipts</key>"-Zweig hinter "<string>sub.packet.name</string>" noetig
            echo 'echo "... patching software '$MUNKINAME' to declare the optional installs of his sub pakages"' >> $OutfileMunkiImport
            echo 'for subpkg in '${DONTCHECKPKGS}'; do' >> $OutfileMunkiImport
            echo "  sed -i '.munki_patch_backup7' '/<string>'"'${subpkg}'"'"'<\/string>/a \' >> $OutfileMunkiImport    # Abschnitt vor "<string>sub.packet.name</string>" schreiben
            echo '   <key>optional</key>\' >> $OutfileMunkiImport
            echo '   <true/>\' >> $OutfileMunkiImport
            echo "' "'"${PLISTPATH}"' >> $OutfileMunkiImport
            echo 'done' >> $OutfileMunkiImport
            echo 'mv "${PLISTPATH}.munki_patch_backup7" $MunkiTmpDir/' >> $OutfileMunkiImport
            echo '' >> $OutfileMunkiImport
        fi

        # Ein eigenes "installcheck_script" einbetten (ACHTUNG: Aufgrund des hier eingesetzten sed-Kommandos sollte in dem Skript keine einfachen Hochkommatas vewendet werden.)
        if [ -n "$INSTALLCHECKFILE" ]
        then
            # pruefe ob das Skript installcheck_script existiert
			if [ ! -f "${INSTALLCHECKSCRIPTSPATH}/${INSTALLCHECKFILE}" ]; then echo "ERROR: Could NOT FOUND the script: ${INSTALLCHECKSCRIPTSPATH}/${INSTALLCHECKFILE}"; exit -1; fi
			numbersOfSingleQuoteCharacter=`cat "${INSTALLCHECKSCRIPTSPATH}/${INSTALLCHECKFILE}" | tr -cd "'" | wc -c`
			if [ $numbersOfSingleQuoteCharacter -gt 0 ]; then echo "ERROR and STOP: The file "${INSTALLCHECKSCRIPTSPATH}/${INSTALLCHECKFILE}" contain the character ' (single quote). This is forbidden, at the moment."; exit -1; fi
			# erstelle die Patch-Datei
            echo '# ein eigene installcheck_script benutzen' >> $OutfileMunkiImport
            echo 'echo "... patching software '$MUNKINAME' and insert an installcheck_script"' >> $OutfileMunkiImport
            echo "(set -x; sed -i '.munki_patch_backup8' '/<string>"$MUNKINAME'<\/string>/a \' >> $OutfileMunkiImport
            echo '   <key>installcheck_script</key>\' >> $OutfileMunkiImport
            echo -n '      <string>\' >> $OutfileMunkiImport
			# das Skript einfuegen (mit XML-kompatiblen Zeichen fuer: <,>,& sowie dem escapen von '\' zu '\\' und einem '\' am Ende jeder Zeile)
			cat "${INSTALLCHECKSCRIPTSPATH}/${INSTALLCHECKFILE}" | sed 's/\&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g' | sed 's/\\/\\\\/g' | perl -pe 's/\n/\\\n/' >> $OutfileMunkiImport
            echo '      </string>\' >> $OutfileMunkiImport
            echo "' "'"${PLISTPATH}" )' >> $OutfileMunkiImport
            echo 'mv "${PLISTPATH}.munki_patch_backup8" $MunkiTmpDir/' >> $OutfileMunkiImport
            echo '' >> $OutfileMunkiImport
		fi

        # Ein eigenes "uninstall_script" einbetten (nicht direkt mit sed einbetten um auch einfache Hochkommatas zu erlauben)
        if [ -n "$UNINSTALLFILE" ]
        then
            # pruefe ob das Uninstallscript existiert
            if [ ! -f "${UNINSTALLFILESPATH}/${UNINSTALLFILE}" ]; then echo "ERROR: Could NOT FOUND the uninstall script: ${UNINSTALLFILESPATH}/${UNINSTALLFILE}"; exit -1; fi
			# erstelle die Patch-Datei
            echo '# ein eigene Uninstall-Skript benutzen' >> $OutfileMunkiImport
            echo 'echo "... patching software '$MUNKINAME' and insert an uninstall script"' >> $OutfileMunkiImport
            mkdir -p ./_munki_patch_files || ( echo "ERROR: Could not create directory."; exit -1 )
            echo '   <string>uninstall_script</string>' > ./_munki_patch_files/${MUNKINAME}.with_replace
            echo '      <key>uninstall_script</key>' >> ./_munki_patch_files/${MUNKINAME}.with_replace
            echo -n '         <string>' >> ./_munki_patch_files/${MUNKINAME}.with_replace
            # das uninstall-Skript einfuegen (mit XML-kompatiblen Zeichen fuer: <,>,&)
            cat "${UNINSTALLFILESPATH}/${UNINSTALLFILE}" | sed 's/\&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g' >> ./_munki_patch_files/${MUNKINAME}.with_replace
            echo '</string>' >> ./_munki_patch_files/${MUNKINAME}.with_replace
            echo 'grep "<string>removepackages</string>" "${PLISTPATH}" > ../_munki_patch_files/'${MUNKINAME}'.to_replace' >> $OutfileMunkiImport
            echo 'diff -u ../_munki_patch_files/'${MUNKINAME}'.to_replace ../_munki_patch_files/'${MUNKINAME}'.with_replace > ../_munki_patch_files/'${MUNKINAME}'.patch'  >> $OutfileMunkiImport
            # patche hiermit spaeter die Munki-Datei
            echo '( set -x; pwd; patch "${PLISTPATH}" ../_munki_patch_files/'${MUNKINAME}'.patch || ( echo "ERROR BY PATCHING."; exit -1 ) )' >> $OutfileMunkiImport
            echo 'mv "${PLISTPATH}.orig" $MunkiTmpDir/' >> $OutfileMunkiImport
            echo 'sleep 1' >> $OutfileMunkiImport
            echo '' >> $OutfileMunkiImport
        fi
		
	    # falls der Wert "true" ist, duerfen auch Pakete ohne gueltigen Signaturen installiert werden (DIES BENOETIGT eine Munki Version >= 3)
		if [ -n "$ALLOWUNTRUSTED" ] && [ "$ALLOWUNTRUSTED" != "true" ]; then echo '*** ERROR in config for "'$MUNKINAME'". The parameter for the setting "allow_untrusted" have to be "true" or should be undefine. ***'; echo; sleep 60; fi
        if [ "$ALLOWUNTRUSTED" = "true" ]
        then
            echo 'echo "... patching software '$MUNKINAME' to allow untrusted packages"' >> $OutfileMunkiImport
            echo 'defaults write "${PLISTPATH}" "allow_untrusted" -bool TRUE' >> $OutfileMunkiImport
            echo 'plutil -convert xml1 "${PLISTPATH}"'  >> $OutfileMunkiImport 
            echo '' >> $OutfileMunkiImport
        fi	

	    # falls gesetzt kann man hiermit die Versionsnummer des Paketen ersetzen (sinnvoll vermutlich nur bei Paketen mit Unterpaketen)
        if [ "$REPLACEVERSION" != "" ] && [ "$REPLACEVERSION" != " " ]
        then
            echo '# change the version number of the package' >> $OutfileMunkiImport
            echo 'echo "... patching software '$MUNKINAME' to change the version number"' >> $OutfileMunkiImport
            echo '( set -x; defaults write "${PLISTPATH}" version "'${REPLACEVERSION}'"' >> $OutfileMunkiImport            # aendern der "oberste" Versionsnummer der Software (und nicht der von Unterpacketen)
            echo 'plutil -convert xml1 "${PLISTPATH}" )' >> $OutfileMunkiImport                                            # Umwandlung der gepatchten Datei ins XML-Format
            echo 'sleep 1' >> $OutfileMunkiImport
            echo '' >> $OutfileMunkiImport
        fi	

	    # falls der Wert "EXTRAXMLOPTIONS" gesetzt ist, ergaenze den dort eingetragen XML-Abschnitt in die Munki-Definition
		numbersOfSingleQuoteCharacter=`echo "$EXTRAXMLOPTIONS" | tr -cd "'" | wc -c`
		if [ $numbersOfSingleQuoteCharacter -gt 0 ]; then echo "ERROR: The XML Code for the software $MUNKINAME contain the character ' (single quote). This is forbidden, at the moment. Please fix it, now."; sleep 60; fi
		if [ -n "$EXTRAXMLOPTIONS" ]
        then
            # fuer alle nicht gewuenschten Pakete ist hier ist noch ein weiteres Patchen mit "<key>optional</key><true/>" im "<key>receipts</key>"-Zweig hinter "<string>sub.packet.name</string>" noetig
            echo 'echo "... patching software '$MUNKINAME' to append own XML code"' >> $OutfileMunkiImport
            echo "sed -i '.munki_patch_backup10' '/<string>"$MUNKINAME'<\/string>/a \' >> $OutfileMunkiImport									# hinter den Namen des Paketes
			echo "$EXTRAXMLOPTIONS" >> $OutfileMunkiImport																						# haenge die XML-Zeile(n) an
            echo "' "'"${PLISTPATH}"' >> $OutfileMunkiImport
            echo 'mv "${PLISTPATH}.munki_patch_backup10" $MunkiTmpDir/' >> $OutfileMunkiImport
            echo '' >> $OutfileMunkiImport
        fi
		
        #
        ## Manifest ggf. erstellen, zum Katalog hinzufuegen und Software ins Manifest hinzufuegen
        #
    
        echo '# Munki-Manifest erstellen' >> $OutfileMunkiImport
        echo '/usr/local/munki/manifestutil new-manifest $MunkiManifests' >> $OutfileMunkiImport
        echo '' >> $OutfileMunkiImport
        
        echo '# Manifest mit dem OBEREN Katalog verknuepfen' >> $OutfileMunkiImport
        echo '/usr/local/munki/manifestutil add-catalog "'$CATALOG'" --manifest $MunkiManifests' >> $OutfileMunkiImport
        echo '' >> $OutfileMunkiImport 
        
        echo '# die Software dem OBEREN Manifest hinzufuegen' >> $OutfileMunkiImport
        echo '/usr/local/munki/manifestutil add-pkg "'$MUNKINAME'" --manifest $MunkiManifests --section '$SECTION >> $OutfileMunkiImport
        echo '' >> $OutfileMunkiImport  

        #
        ## ICONs koppieren
        #

        # falls moeglich koppiere die ICON-Datei in den Ordner von Munki, so dass die Clients das Icon zu der App in Munki sehen koennen, auch wenn sie die App nicht installiert haben
        echo '# copy icon to the folder for Munki' >> $OutfileMunkiImport
        echo 'if [ -f "$PKG/_icons/'$NAME'.png" ]' >> $OutfileMunkiImport
        echo 'then' >> $OutfileMunkiImport
        echo '   mkdir -p "$MunkiRepoPath/icons"' >> $OutfileMunkiImport
        echo '   ( set -x; cp "$PKG/_icons/'$NAME'.png" "$MunkiRepoPath/icons/'$MUNKINAME'.png" )' >> $OutfileMunkiImport
        echo 'fi' >> $OutfileMunkiImport

        echo '# Kataloge des Imports erstellen (muss nach jedem Softwareimport sowie nach dem Kopieren neuer Icons erfolgen)' >> $OutfileMunkiImport
        echo '(set -x; /usr/local/munki/makecatalogs $MunkiRepoPath > /dev/null)' >> $OutfileMunkiImport
        echo '' >> $OutfileMunkiImport

        # die temp. Dateien verschieben/loeschen und die IMPORT-Datei abschliessen
        echo '# remove temporary files and exit' >> $OutfileMunkiImport
        echo '(set -x; rm -rf "${MunkiTmpDir}_last_import" 2> /dev/null; mv "$MunkiTmpDir" "${MunkiTmpDir}_last_import" )' >> $OutfileMunkiImport
        echo 'exit 0' >> $OutfileMunkiImport
        echo '' >> $OutfileMunkiImport

        NumberOfSoftware=$(($NumberOfSoftware+1))

    else
    
        echo '   Note: There is no (single file) package found with the name "'$NAME'*" in the directory "'$CATALOG'", like written in the Munki file.'

    fi

done

# entferne doppelte Zeilen aus der Liste der Gruppen fuer Software
sort -u ${ACCESSGROUPFILE} -o ${ACCESSGROUPFILE}

########################################

# Suche nach Paketen die NICHT in $FileMunkiInfos eingetragen sind
for i in $(ls -1 | grep -i 'pkg\|dmg$')
do
    FOUNDPKG=`grep -r $i $PkgPath/_import_to_munki_/`
    if [ "" == "$FOUNDPKG" ]
    then
        echo "## Warning: Munki informmation for the package '$i' in '$CATALOG' NOT FOUND ! ##"
        if [ -n "`file $i | awk -F ' ' '{ print $2 }' | grep 'directory' `" ]; then echo "+++ Warning: The package '$i' is a directory not a file. Only single file packages are accepted. Please create a DMG file from the package and use this one. +++"; fi
    fi
done

########################################

# Infomeldung an den Benutzer
if [ $NumberOfSoftware -gt 0 ]
then
    echo "* The Munki import files (for $NumberOfSoftware applications) are (hopefully) created for the catalog '$CATALOG' on '$PkgPath/_import_to_munki_/'. *"
else
    echo "## Warning: There was NO Munki import file created, for the catalog '$CATALOG'. ##"
    rmdir "$PkgPath/_remove_from_munki_"
    rmdir "$PkgPath/_import_to_munki_"
fi

########################################

# alten Fileseperator wieder setzen
IFS=$OIFS

exit 0

