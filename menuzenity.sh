#!/bin/bash
TITLE="Seleccion de respaldo"
QUESTION="Seleccione una opcion:"
OPTIONS=("Archivo" "Directorio" "Programar un respaldo")

function inputfile {
	FILE=`zenity --file-selection --title="Seleccione el $OPTIONS a respaldar"` 2>/dev/null
  #  FILE=`zenity --entry --title="Archivo para filtrar" --text="Por favor escriba el nombre del archivo"`
	echo $FILE > ruta
	}
function parsepath {
	it=$(cat ruta |gawk -F"\\" '{ print NF }')	#count number of fields
	COUNTER=1
  while [  $COUNTER -lt $it ]; do
  	sed -i 's/\\/\//' ruta										#replace delitator
  	let COUNTER=COUNTER+1
	done
  #    cat ruta
	}
function archive_select {
	TEXT=$(echo $FILE |gawk -F"\\" '{print$it}')
  echo $TEXT
	}
#function folder_destiny {
#	
#	}
while opt="$(zenity --title="$TITLE" --text="$QUESTION" --list --column="Opciones de respaldo" "${OPTIONS[@]}")"; do

    case $opt in
		    "${OPTIONS[0]}" ) 
    		zenity --info --text="Has elegido respaldar un $opt?"
				inputfile
				parsepath
				archive_select
#				echo "Has elegido $opt, Opcion 1"
		        ;;
		    "${OPTIONS[1]}") 
				echo "Has elegido $opt, Opcion 2"
        zenity --info --text="Has elegido $opt, Opcion 2"
				    ;;
				"${OPTIONS[2]}") 
        echo "Has elegido $opt, Opcion 3"
				zenity --info --text="Has elegido $opt, Opcion 3"
						;;
		    "${OPTIONS[-1]}") 
		    zenity --error --text="Opcion Incorrecta , Intenta con otra."
					  ;;
	    esac

done
