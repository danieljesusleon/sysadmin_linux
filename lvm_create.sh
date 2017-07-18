
#!/bin/bash
# Menu
#This script is intended to create and manage logical volumes from disk partitioning onwards

until [ "$op" == 6 ];do
function menu {
    echo "Please choice a option"
    echo "--------------------------"
    echo "1- Disk partition"
    echo "2- Physical volumes"
    echo "3- Group volumes"
    echo "4- Logical volumes"
    echo "5- File systems"
    echo "6- Exit"
}


menu
    read op

    case $op in
        1)echo "Disk partitions:"
          echo "----------------"
          echo "1- To list Disk partition"
          echo "2- Create disk partition"
          echo "3- Remove disk partition"
          echo "4- Return"
          read oppd
        case $oppd in
            1)
            fdisk -l|sed '/^Units/d' |sed '/^Sector/d' |sed '/^I/d' |sed '/label/d' |sed '/^$/d' |sed '/^Disk\ identifier/d' |sed '/^[[:space:]]/d'
            ;;
            2)echo "Please indicate the path of the partition to be created"
              echo "example: /dev/sdb"
            read pathpart
              echo "Enter the sub-partition number, example / dev / sda1 -> 1, / dev / sdb2 -> 2"
            read npart
              echo "Specify the size of the partition"
            read sizepart
              echo "Indicate the type of partition <p - primary/ e - extended>"
            read typepart
              echo "Specify the format <linux 83 |swap 82 |lvm 8e >"
            read formatpart
            echo -e "o\nn\n$typepart\n$npart\n\n+$($sizepart)M\nt\n$formatpart\nw" |fdisk $pathpart
            partprobe $pathpart$npart
            ;;

            3)echo "Please indicate the path of the partition to be created"
              echo "example: /dev/sdb"
            read pathpart
              echo "Enter the sub-partition number, example / dev / sda1 -> 1, / dev / sdb2 -> 2"
            read npart
            echo -e "d\n$npart\nw\n" |fdisk $pathpart
            ;;

            4) sleep 2
               clear
                ;;

        esac    
        ;;
        2)echo "Physical volumes:"
          echo "-----------------"
          echo "1- To list physical volumes"
          echo "2- Create volume physical"
          echo "3- Return"
          read oppv
        case $oppv in
            1)pvs
            ;;

            2)echo "Please indicate the partition to create the new pv, example pv: </dev/sda1>"
            read pvdev
              echo "Creating the new vp"
            pvcreate $pvdev
            ;;

            3) clear
                ;;
            *) echo "Invalid option"
               sleep 2
                clear
                ;;
        esac    
        ;;
        3)echo "Groups volumes:"
          echo "---------------"
          echo "1- To list groups volumes"
          echo "2- Create group volume"
          echo "3- Return"
          read opvg
        case $opvg in
            1)vgs
            ;;

            2)echo "Please enter the name of the new group volume"
            read vgname
              echo "Please indicate the physical volume to create the new pv, example pv: </dev/sda1>"
            read vgdev
              echo "Creating the new vp"
            vgcreate $vgname $vgdev
            ;;

            3) clear

                ;;
            *) echo "Invalid option"
               sleep 2
               clear
                ;;
        esac    

        ;;
        4) echo "Logical volumes"
          echo "----------------"
          echo "1- To list group volumes"
          echo "2- Create logical volume"
          echo "3- Return"
          read opvl
        case $opvl in
            1)lvs
            ;;

            2)echo "Please indicate the name of logical volume"
            read lvname
              echo "indicate the size"
            read lvsize
              echo "indicate the path to logical volume, example: /dev/mapper/lvname"
            read lvpath
            lvcreate -n $lvname -L $lvsize $lvpath
              echo "Creating the new vp"
            ;;

            3) clear
                ;;

            *) echo "Invalid option"
               sleep 2
               clear
                ;;
        esac    
        ;;
        5) echo "File systems"
          echo "----------------"
          echo "1- To list file systems"
          echo "2- Create file system"
          echo "3- Return"
          read opfs
        case $opfs in
            1)df -h
            
            ;;

            2)echo "Please indicate the type of file system, example: ext3,ext4,xfs"
            read fstype
              echo "indicate the path to file system, example: /dev/mapper/lvname"
            read fspath
            mkfs.$fstype $fspath
              echo "Creating the new file system"
            mkdir -p /mnt$fspath
            mount -f $fstype $fspath /mnt$fspath
            
            ;;

            3)clear
                ;;

            *) echo "Invalid option"
             sleep 2
             clear
                ;;
        esac    
        ;;
        6)
        clear
        exit
        ;;
        *) echo "Invalid option"
           sleep 2
           clear
            ;;
    esac
done
