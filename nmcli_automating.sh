
#!/bin/bash
# Read the names of network interfaces with nmcli and parsing the conten in the file listinterfaces
# with gawk, sed, sort and write output in the file NamesFiltred
    nmcli device show |grep 'GENERAL.CONNECTION' |awk -F":[[:space:]]" '{print $2}'| sed 's/[[:space:]]//g' | sed 's/--//g' |sed '/^$/d' > NamesFiltred
    nro=$(wc -l NamesFiltred |awk -F"[[:space:]]" '{print $1}')
    #if [ "$nro" == 0 ];then
    #echo "El equipo no tiene ninguna interfaz de red activa"
    #exit 0;
    #else
    i=0
    while read line   
    do i=$(($i+1));
        #echo $i $line
        arreglo[$i]=$line
        echo "$i --- ${arreglo[$i]}"
    done < "NamesFiltred"
    echo "Desea configurar alguna interfaz s (si)/ n (no):"
    read opcion
    if [ "$opcion" == "n" ] || [ "$opcion" == "no" ];then
        exit 0;
    else
        if [ "$opcion" == "s" ] || [ "$opcion" == "si" ];then
        echo "ingrese el numero correspondiente a la interfaz"   
        read nrointer
        inter="${arreglo[$nrointer]}"
        echo "$inter"
            if [ "$inter" != "" ];then
            echo "usted selecciono:${arreglo[$nrointer]}"
            # Solicitud de ingreso de datos
            echo "Introduzca la direccion ip para la interfaz de red ${arreglo[$nrointer]}"
            read ip
            echo "Introduzca la mascara de red"
            read mask
            echo "introduzca la puerta de enlace"
            read gw
#            if [ "$gw" < 8 ] || [ "$gw" > 31 ];then
#                echo "ingrese una mascara de red valida"
#                exit 0
#            fi
            echo "introduzca la direccion dns"
            read dns
            # modificacion de parametros de red
            nmcli con mod ${arreglo[$nrointer]} ipv4.addresses $ip/$mask
            nmcli con mod ${arreglo[$nrointer]} ipv4.gateway $gw
            nmcli con mod ${arreglo[$nrointer]} ipv4.method manual
            nmcli con mod ${arreglo[$nrointer]} ipv4.dns $dns
            echo "--------Desactivando interfaz---------"
            nmcli con down ${arreglo[$nrointer]}
            echo "--------Activando interfaz---------"
            nmcli con up ${arreglo[$nrointer]}

            # Muestra de la configuracion en fichero
            echo "--------Prueba de ping--------"
            ping -c1 $dns > prueba_conexion
            echo "$(cat prueba_conexion)"
            rm -f prueba_conexion
            echo "Parametros de configuracion persistente:"
            nmcli --fields "GENERAL.NAME, IP4" con show ${arreglo[$nrointer]}

#        echo "la direccion ip de para la interfaz de red  ${arreglo[$nrointer]} se configuro con:"
#        echo "$ip mascara $mask, puerta de enlace $gw y dns $dns"
               
            # Prueba de los parametros de red
           
            else
            echo "ingrese una opcion valida"
            fi
        fi
    fi   
