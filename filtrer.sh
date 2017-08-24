#!/bin/bash
#function to query code
function menuquestion {
  zenity --question --title="Filtro de productos" --text="Filtrar por codigo?"
  option=$(echo $?)
  echo $option
}
function inputfile {
  FILE=`zenity --file-selection --title="Seleccione un archivo para filtrar"`
#  FILE=`zenity --entry --title="Archivo para filtrar" --text="Por favor escriba el nombre del archivo"`
  echo $FILE
}
function querycode {
  CODE=`zenity --entry --title="Codigo del producto" --text="Ingrese el codigo del producto" |gawk -F"|" '{print$1}'`
  echo $CODE
}
function filtred {
  TEXT=$(echo $FILE |gawk -F"\\" '{print$5}')
  echo $TEXT
  cat C:/Users/Administrator/Desktop/$TEXT |grep -v "$CODE" > filtrado.txt | zenity --progress --title="Filtrando el archivo $FILE" --text="Filtrando." --percentage=0
}
#cd C:/cygwin64/home/Administrator/
menuquestion
while [ $option = "0" ];do
  inputfile
    if [ -z "$FILE" ];then
      zenity --error --text "Debe seleccionar un archivo" 
    else
      querycode
        if [ -z "$CODE" ];then
          zenity --error --text="Debe ingresar un codigo" 
        else
          echo $CODE
		  echo "$CODE" > pattern.txt
		  CHARACTERS=$(wc -c pattern.txt |awk -F"[[:space:]]" '{print$1}')
		  echo $CHARACTERS
          PATTERN=`expr $CHARACTERS - 2`
		  echo $PATTERN
	       if [ $PATTERN = "0" ];then
             zenity --error --text "Ingrese un codigo valido, por favor" 
 	       else
             filtred
	         zenity --info --text="El archivo fue filtrado, y se encuentra ahora en su escritorio" 
           fi
        fi
    fi
rm -f pattern.txt
mv filtrado.txt C:/Users/Administrator/Desktop
menuquestion
done
