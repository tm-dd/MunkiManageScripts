#!/bin/bash
#
# last Update: 2019-09-11
#
# by Thomas Mueller
#

########################################

# Fileseperator neu setzen
OIFS=$IFS
IFS=$'\n'

# read settings
source "`dirname $0`/config.sh"

# pruefe ob ein Parameter (Verzeichnis mit Paketen) angegeben wurde und gehe in diesen Ordner
if [ -d "$munkiManifestOffsets" ]
then
    echo; echo "INFOMATION: DIRECTORY '$munkiManifestOffsets' STILL EXISTS."; echo
    echo "            *** DELETE any content in 3 seconds. ***"; echo
    sleep 3
    rm -rv "$munkiManifestOffsets"
    echo
else
    echo; echo "INFOMATION: NEW DIRECTORY '$munkiManifestOffsets' CREATED."; echo
    mkdir -p $munkiManifestOffsets || exit -1
fi

# den Pfad des Verzeichnisses des Skriptes holen
dirname=`dirname $0`

# ohne Munki-Info-Datei kann es nicht weitergehen
if [ ! -f "$MunkiManifestConfig" ]
then
    echo "ERROR: Could NOT FOUND the Munki manifest configuration file: $MunkiManifestConfig";
    exit -1
fi

# Datei, welche zeilenweise alle Manifests auffuehrt, die in einem Manifest inkludiert werden (fuer ein spaeteres Skript)
rm -f $INCLUDEDCATALOGSFILE; touch $INCLUDEDCATALOGSFILE

# merke die Dateien der Manifests
FoundedManifests=''

########################################

function writeCatalog {

    # $1 entspricht dem $MANIFESTNAME    
    # $2 entspricht dem $IMPORTCATALOG
    # $3 entspricht dem $IMPORTEDMANIFEST

    echo "... change manifest '$1' to import catalog '$2' (and import manifest '$3')"
    
    #
    ## importiere den Katalog der eigenen Zeile
    #
    
    # falls ueberhaupt Kataloge zu einem Manifest imporiert werden sollen
    if [ -n "$1" ] && [ -n "$2" ]
    then
        
        # ... und die zu importierenden Kataloge/Manifests nicht ueber diese CSV-Datei selbst definiert werden
        if [ -z "`cat ${MunkiManifestConfig} | grep -v '^,\|^",\|^"#' | grep '^"'$3'",'`" ]
        then
            
            # fuege den Katalog zu dem Manifest hinzu (falls nicht schon vorher getan)
            defaults write ${munkiManifestOffsets}/${1} catalogs -array-add ${2}
            
        fi
    
    fi
    
    #
    ## falls weitere Manifests importiert werden sollen, die selbst in dieser Textdatei eingetragen sind, rufe die Funktion rekusiv auf, um auch dessen Kataloge zu importieren
    #
    
    if [ -n "$3" ]
    then
        
        # fuer alle Zeilen der Liste, bei denen das Manifest so heist, wie das zu importierende Manifest
        for j in $(cat ${MunkiManifestConfig} | grep -v '^,\|^",\|^"#' | grep '^"'$3'",')
        do
            
            j=`echo $j | sed 's/,,/,"",/g' | sed 's/,,/,"",/g' | sed 's/,$/,""/'`               # damit wird erreicht das Zeilen wie '"WERT1",,,"WERT4",,' zu besser trennbaren Zeilen '"WERT1","","","WERT4","",""' werden
            j=`echo $j | sed 's/^"//g' | sed 's/"$//g'`                                         # dies entfernt das erste und letzte '"', da dieses Zeichen am Anfang und Ende nicht benoetigt wird    
            MANIFESTNAMEFUNCT=`echo $j | awk -F '","' '{ print $1 }'`                           # der Name der Manifestdatei fuer diese Regel/Zeile
            IMPORTCATALOGFUNCT=`echo $j | awk -F '","' '{ print $3 }'`                          # der Name eines zu importierenden Cataloges
            IMPORTEDMANIFESTFUNCT=`echo $j | awk -F '","' '{ print $3 }'`                       # Name des zu importierenden Manifests (BEI MIR IST DER NAME ANALOG ZUM KATALOG)

            writeCatalog $1 $IMPORTCATALOGFUNCT $IMPORTEDMANIFESTFUNCT                          # rufe die Funktion rekursiv auf

        done
    
    fi

    #
    ## INCLUDED MANIFESTS INFO FILE
    #
    if [ `grep "^$1 : " ${INCLUDEDCATALOGSFILE} | wc -l` -lt "1" ]
    then
        
        # falls noch keine Zeile fuer das Manifest beginnt haenge das Manifest in den Importkatalog an 
        echo "$1 : $2" >> ${INCLUDEDCATALOGSFILE}
        
    else
        if [ `grep "^$1 : " ${INCLUDEDCATALOGSFILE} | grep " $2 " | wc -l` -lt "1" ]
        then
            
            # falls eine Zeile fuer das Manifest beginnt haenge den neuen Catalog an diese Zeile an
            sed -i '.tmp' "s/^$1 : /$1 : $2 /g" ${INCLUDEDCATALOGSFILE}
            
        fi
    fi
    
}


#
# untersuche alle CSV-basierten Zeilen in $MunkiManifestConfig
#

for i in $(cat ${MunkiManifestConfig} | grep -v '^,\|^",\|^"#')
do
    
    #
    # LESE MUNKI-PARAMETER
    #
    i=`echo $i | sed 's/,,/,"",/g' | sed 's/,,/,"",/g' | sed 's/,$/,""/'`               # damit wird erreicht das Zeilen wie '"WERT1",,,"WERT4",,' zu besser trennbaren Zeilen '"WERT1","","","WERT4","",""' werden
    i=`echo $i | sed 's/^"//g' | sed 's/"$//g'`                                         # dies entfernt das erste und letzte '"', da dieses Zeichen am Anfang und Ende nicht benoetigt wird    
    MANIFESTNAME=`echo $i | awk -F '","' '{ print $1 }'`                                # der Name der Manifestdatei fuer diese Regel/Zeile
    CONDITIONS=`echo $i | awk -F '","' '{ print $2 }'`                                  # eine Bedingung fuer den Manifesteintrag
    IMPORTCATALOG=`echo $i | awk -F '","' '{ print $3 }'`                               # der Name eines zu importierenden Cataloges
    IMPORTEDMANIFEST=`echo $i | awk -F '","' '{ print $3 }'`                            # Name des zu importierenden Manifests (BEI MIR IST DER NAME ANALOG ZUM KATALOG)
    MANGEDINSTALLS=`echo $i | awk -F '","' '{ print $4 }'`                              # installiere diese Anwendung
    MANGEDUNINSTALLS=`echo $i | awk -F '","' '{ print $5 }'`                            # deinstalliere diese Anwendung
    OPTIONALINSTALLS=`echo $i | awk -F '","' '{ print $6 }'`                            # biete diese Anwendung im Self-Service an

    #
    ## fuege dem Manifest den Katalog hinzu, falls angegeben
    #
    if [ -n "$IMPORTCATALOG" ]
    then

        # nutze eine rekursive Funktion zum Importieren des Kataloges, da Kataloge beliebige verschachtelt sein koennen
        writeCatalog $MANIFESTNAME $IMPORTCATALOG $IMPORTEDMANIFEST

    fi

    #
    ## IMPORT MANIFEST
    # 
    if [ -n "$IMPORTEDMANIFEST" ]
    then
        
        if [ -z "$CONDITIONS" ]
        then

            # fuege dem Manifest die includierten Manifests hinzu, welche KEINE Bedingung haben
            defaults write ${munkiManifestOffsets}/${MANIFESTNAME} included_manifests -array-add ${IMPORTEDMANIFEST}
            
        else

            # quote Hochkommatas und ersetze fehlerhafte ersetzte '""' gegen '"' in $CONDITIONS
            CONDITIONS=$(echo $CONDITIONS | sed 's/""/"/g' | sed 's/"/\\"/g' | sed "s/\'/\\\'/g")
            
            # fuege dem Manifest die includierten Manifests hinzu, welche EINE Bedingung haben
            defaults write ${munkiManifestOffsets}/${MANIFESTNAME} conditional_items -array-add '{ "condition" = "'${CONDITIONS}'"; "included_manifests" = ("'${IMPORTEDMANIFEST}'"); }'

        fi
        
    fi

    #
    ## MANAGED INSTALLS
    #
    
    if [ -n "$MANGEDINSTALLS" ]
    then
        
        if [ -z "$CONDITIONS" ]
        then

            # fuege dem Manifest managed_installs hinzu, welche KEINE Bedingung haben
            defaults write ${munkiManifestOffsets}/${MANIFESTNAME} managed_installs -array-add ${MANGEDINSTALLS}
            
        else
            
            # quote Hochkommatas und ersetze fehlerhafte ersetzte '""' gegen '"' in $CONDITIONS
            CONDITIONS=$(echo $CONDITIONS | sed 's/""/"/g' | sed 's/"/\\"/g' | sed "s/\'/\\\'/g")
            
            # fuege dem Manifest managed_installs hinzu, welche EINE Bedingung haben
            defaults write ${munkiManifestOffsets}/${MANIFESTNAME} conditional_items -array-add '{ "condition" = "'${CONDITIONS}'"; "managed_installs" = ("'${MANGEDINSTALLS}'"); }'
            
        fi
        
    fi


    #
    ## MANAGED UNINSTALLS
    #
    
    if [ -n "$MANGEDUNINSTALLS" ]
    then
        
        if [ -z "$CONDITIONS" ]
        then

            # fuege dem Manifest managed_uninstalls hinzu, welche KEINE Bedingung haben
            defaults write ${munkiManifestOffsets}/${MANIFESTNAME} managed_uninstalls -array-add ${MANGEDUNINSTALLS}
            
        else

            # quote Hochkommatas und ersetze fehlerhafte ersetzte '""' gegen '"' in $CONDITIONS
            CONDITIONS=$(echo $CONDITIONS | sed 's/""/"/g' | sed 's/"/\\"/g' | sed "s/\'/\\\'/g")
            
            # fuege dem Manifest managed_uninstalls hinzu, welche EINE Bedingung haben
            defaults write ${munkiManifestOffsets}/${MANIFESTNAME} conditional_items -array-add '{ "condition" = "'${CONDITIONS}'"; "managed_uninstalls" = ("'${MANGEDUNINSTALLS}'"); }'          
        fi
        
    fi
    
    #
    ## OPTIONAL INSTALLS
    #

    if [ -n "$OPTIONALINSTALLS" ]
    then
        
        if [ -z "$CONDITIONS" ]
        then

            # fuege dem Manifest managed_uninstalls hinzu, welche KEINE Bedingung haben
            defaults write ${munkiManifestOffsets}/${MANIFESTNAME} optional_installs -array-add ${OPTIONALINSTALLS}

        else
            
            # quote Hochkommatas und ersetze fehlerhafte ersetzte '""' gegen '"' in $CONDITIONS
            CONDITIONS=$(echo $CONDITIONS | sed 's/""/"/g' | sed 's/"/\\"/g' | sed "s/\'/\\\'/g")
            
            # fuege dem Manifest managed_uninstalls hinzu, welche EINE Bedingung haben
            defaults write ${munkiManifestOffsets}/${MANIFESTNAME} conditional_items -array-add '{ "condition" = "'${CONDITIONS}'"; "optional_installs" = ("'${OPTIONALINSTALLS}'"); }'

        fi
        
    fi
    
done

#
## konvertiere alle plist-Dateien ins XML-Format und entferne die plist-Dateiendung
#
for i in $(ls -1 ${munkiManifestOffsets}/*.plist)
do
    # wandele die Konfiguration(en) in regulaere XML-Datei(en) um
    plutil -convert xml1 $i

    # entferne die Dateiendung
    newName=$(echo $i | sed 's/.plist$//')
    mv "$i" "$newName"
done


########################################

# Infomeldung an den Benutzer
echo
echo "Die Munki-Manifests wurden nach '${munkiManifestOffsets}' erstellt."
echo


########################################

# alten Fileseperator wieder setzen
IFS=$OIFS

exit 0
