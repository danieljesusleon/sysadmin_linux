#!/bin/bash
TITLE="Seleccion de Tipo Respaldo"
QUESTION="A continuacion se muestran las opciones:"
OPTIONS=("Archivo" "Directorio" "Programar un respaldo")
#cat originalfile | tr -d "\r" > newfile
function inputfile {
	FILE=`zenity --file-selection --title="Seleccione el $OPTIONS a respaldar"`
	echo $FILE > ruta
	cat ruta
	it=$(cat ruta |gawk -F"\\" '{ print NF }')	#count number of fields
	echo $it
	}
function archive_select {
	TEXT=$(cut -f $it -d\\ ruta )
	#TEXT=$(cat ruta |gawk -F"\\" '{print$it}')
	echo $TEXT
	}
function parsepath {
	COUNTER=1
	while [  $COUNTER -lt $it ]; do
		sed -i 's/\\/\//' path_source										#replace delitator
		let COUNTER=COUNTER+1
	done
    cat path_source
	PATH_SOURCE=$(cat path_source)
	#PARSEPATH=$(cat ruta)
	}
function pathout {
	DESTINY=`zenity  --file-selection --title="Escoja el directorio de destino" --directory`
	echo $DESTINY > ruta2
	echo $DESTINY
	COUNTER=1
	while [  $COUNTER -lt $it ]; do
		sed -i 's/\\/\//' ruta2										#replace delitator
		let COUNTER=COUNTER+1
	done
	PATHOUT=$(cat ruta2)
	}	
function inputfolder {
	INPUTFOLDER=`zenity --file-selection --title="Seleccione el $OPTIONS a respaldar"`
	echo $INPUTFOLDER > ruta_folder
	cat ruta_folder
	it=$(cat ruta_folder |gawk -F"\\" '{ print NF }')	#count number of fields
	echo $it
	}
function folder_select {
	FOLDER_SELECT=$(cut -f $it -d\\ ruta_folder )
	#TEXT=$(cat ruta |gawk -F"\\" '{print$it}')
	echo $FOLDER_SELECT
	}
function pathout_folder {
	PATHOUT_FOLDER=`zenity  --file-selection --title="Escoja el directorio de destino" --directory`
	echo $PATHOUT_FOLDER > ruta_folder2
	echo $PATHOUT_FOLDER
	COUNTER=1
	while [  $COUNTER -lt $it ]; do
		sed -i 's/\\/\//' ruta_folder2										#replace delitator
		let COUNTER=COUNTER+1
	done
	PATHOUT2=$(cat ruta_folder2)
	}	
while opt="$(zenity --title="$TITLE" --text="$QUESTION" --list --column="Seleccione una opcion y presione Ok" "${OPTIONS[@]}")"; do

    case $opt in
		    "${OPTIONS[0]}" ) 
    		#zenity --info --text="Has elegido respaldar un $opt?"
				PARSEPATH=`zenity  --file-selection --title="		Seleccione el directorio de origen" --directory`
				echo $PARSEPATH > path_source
				inputfile
				archive_select
				parsepath
				pathout
				cd $PATH_SOURCE
				pwd
				tar -cvf $TEXT-`date +%F`.tar $TEXT
				mv *.tar $PATHOUT
				cd $PATHOUT
				ls
		        ;;
		    "${OPTIONS[1]}") 
				inputfolder
				folder_select
				pathout_folder
				cd $INPUTFOLDER
				pwd
				tar cvf $FOLDER_SELECT-`date +%F`.tar $INPUTFOLDER
				mv *.tar $PATHOUT2
				cd $PATHOUT2
				ls
				    ;;
				"${OPTIONS[2]}") 
				
        #		zenity --info --text="Has elegido $opt, Opcion 3"
						;;
		    "${OPTIONS[-1]}") 
		    zenity --error --text="Opcion Incorrecta , Intenta con otra."
					  ;;
	    esac

done
