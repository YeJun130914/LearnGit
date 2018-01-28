#!/bin/csh -f
#########################################
# File Name: cat_special_net.csh
# Author: albert_ye
# Version: 0.2
# Last Modified:
#########################################

set cell_name = $1

if ( $1 == '--help') then
	echo "####################################################"
	echo "-->	USAGE:	cat_special_net.csh virtuoso_cell_name"
	echo "####################################################"
	exit
endif

set work_path = `pwd`

set time = `date +%Y%m%d`

## set output file name
set output_file_list = "special_net_rpg.cmd special_net.tcl"

## delete previous output file
rm -rf special_net_rpg.cmd special_net.tcl

## find special net data file from virtuoso with different format
## *.rpg for RPG 
## *.tcl for ICC
## create list file with suffix ".list"
find ${work_path} -name \*.rpg | sed 's/ /\t/' > special_net_rpg.cmd.list
find ${work_path} -name \*.tcl | sed 's/ /\t/' > special_net.tcl.list

foreach file (${output_file_list})
	#echo ${file}
	## add HEADER and mark generated time
	echo ''' \
	################################################################## \
	## 'TIME:	${time}' \
	## special net \
	################################################################## \
	''' > ${file}

	set n = "`wc -l < ${file}.list`"
	set i = 1
	while ($i <= $n)
		set file_name = "`gawk '{if (NR == $i) print}' ${file}.list`"
		#echo ${file_name}
		set net_name = `echo ${file_name} | gawk -F ''"${cell_name}_"'' '{print $2}'`
		#echo ${net_name}
		echo "##"	>> ${file}
		echo "## ${net_name:r}" >> ${file}
		echo "##"	>> ${file}
		cat ${file_name} >> ${file}
		echo " "	>> ${file}

		@ i++
	end
end

## delete tmp file
rm -rf special_net_rpg.cmd.list special_net.tcl.list

exit
