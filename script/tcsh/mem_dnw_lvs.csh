#!/usr/bin/csh -f
############################
# File Name: mem_dnw_lvs.csh
# Author: albert_ye
# Version: 0.1
# Last Modified:
############################

if ($1 == "-help") then
	echo "-->	Usage: lvs_block.csh block.list"
	echo "-->	example for block.lsit file:"
	echo "----------------------------------------"
	echo "USBPHY"
	echo "pcie_top"
	echo "video_group"
	echo "----------------------------------------"
	exit
endif

echo "======================================================="
echo "-->	Please make sure the orignal lvs_script.bkend is right configurd!"
echo "-->	Check the gds/spi directory"
echo "======================================================="

set block_list = $1

if ( $#argv == 0 ) then
	echo "Error! Missing the block list file!"
	exit
endif

## check the exist of lvs_script.bkend file
if ( ! -e lvs_script.bkend ) then 
	echo "Error! No bkend script file!"
	exit
endif

## clear the lvs.sum and lvs.status, if exists
if (-s lvs.sum) then
	echo "Deleted the lvs.sum!"
	rm -rf lvs.sum
endif
if (-e lvs.status) then
	echo "Deleted the lvs.status!"
	rm -rf lvs.status
endif

set work_path = `pwd`
set gds_dir = "/project/RL1234/..../top_sram"
set spi_dir = "/project/RL1234/..../top_sram"


## check the number of macros which need to check lvs
set n = `wc -l < $block_list`
## modefy the layout/source top name and create a lvs_script.bkend for each macro
set i = 1
while ( $i <= $n )
	set cell_name = "`gawk '{if (NR == $i) print}' $block_list`"
	mkdir -p ${cell_name}

	cd ${cell_name}

	set gds_path = `find $gds_dir -name ${cell_name}.gds`
	set spi_path = `find $spi_dir -name ${cell_name}.cir`

	## create the dnw gds
	## Layer :108.0 - PRBOUNDAR ;1.0 - DNW 
	echo '''set L [ layout create '"${gds_path}"' -dt_expand -preserveTextAttributes ] \
	$L SIZE 108.0 1.0 BY 1 \
	$L gdsout '"${cell_name}_dnw.gds"'''' >> add_dnw_${cell_name}.tcl
	## perform calibredrv
	calibredrv add_dnw_${cell_name}.tcl +grid	

	## modify the spice file for dnw version
	sed 's/\<nch\>/nch_dnw; s/\<nch_lvt\>/nch_lvt_dnw/' $spi_path > ${cell_name}_dnw.spi

	## modify the layout/source top name
	#sed 's/^\(LAYOUT PRIMARY\) .*/\1 \"'"${cell_name}"'\"/ \
	#	s#^\(LAYOUT PATH\) .*#\1 \"'"${work_path}/${cell_name}/${cell_name}_dnw.gds"'\"# \
	#	s/^\(SOURCE PRIMARY\) .*/\1 \"'"${cell_name}"'\"/ \
	#	s#^\(SOURCE PATH\) .*#\1 \"'"${work_path}/${cell_name}/${cell_name}_dnw.spi"'\"#' bkend_rule.lvs > bkend_rule.lvs.${cell_name}

	sed 's/\(set_layout_top\) .*/\1 '"${cell_name}"'/ \
		s/\(set_spice_top\) .*/\1 '"${cell_name}"' / \
		s#\(set_layout_file\) .*#\1 '"${work_path}/${cell_name}/${cell_name}_dnw.gds"' #\
		s#\(set_spice_file\) .*#\1 '"${work_path}/${cell_name}/${cell_name}_dnw.spi"' #' ../lvs_script.bkend > lvs_script.bkend

	## create dir for each macro to run lvs check, be careful to remove the last version lvs_script.bkend
	
	echo "====================== STATUS =======================" >> ../lvs.status
	echo "-->	Cell: ${cell_name} ......"

	## perform the lvs check
	bkend lvs_script.bkend

	## write lvs result summary report
	set result = `tail -11 lvs.rep.log | head -1 | gawk '{print $3}'`
	if ($result == "CORRECT.") then
		echo "$i.	${cell_name}	$result" >> ../lvs.sum
	else if ($result == "INCORRECT.") then
		echo "$i.	${cell_name}	$result" >> ../lvs.sum
	else
		echo "$i.	${cell_name} doesn't perform lvs. Please check the layout/spi name." >> ../lvs.sum
	endif

	cd ..
	echo "-->	${cell_name} done!" >> ../lvs.status
	## remove the tmp file
	#\rm -rf lvs_script.bkend.$cell_name.tmp*

	@ i++
end

exit
