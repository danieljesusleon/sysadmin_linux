#!/bin/sh
cd /path_to_files
for f in *.pdf;
	do fecha=$(ls -l $f|awk '{print $7}')
	a=$((30-$fecha))
	   if [ $a -gt 3 ]; then
		rm -f $f
	   fi
done
