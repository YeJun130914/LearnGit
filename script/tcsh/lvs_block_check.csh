#!/usr/bin/csh -f
#########################################################
# File Name: lvs_block.csh
# Description: 
# Create: 2017-08-17 14:25:36 by S0672
# Version: 0.1
# Last Modified: 2017-08-20 19:43:10
#########################################################

if ($1 == "-help") then
	echo "-->	Usage: lvs_block.csh block.list"
	echo "-->	example for block.list file:"
	echo "----------------------------------------"
	echo "USBPHY"
	echo "pcie_top"
	echo "video_group"
	echo "----------------------------------------"
	exit
endif

echo "=========================================================="
echo "-->   Please make sure the original lvs_script.bkend is right configured!"
echo "-->   Is top gds path/source path correct?"
echo "=========================================================="

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

## clear the lvs.sum, if exists
if ( -e lvs.sum ) then
    echo "Deleted the lvs.sum!"
    rm -rf lvs.sum
endif
if ( -e lvs.status ) then
    echo "Deleted the lvs.status!"
    rm -rf lvs.status
endif

## check the number of macros which need to check lvs
set n = `wc -l < $block_list`
## modefy the layout/source top name and create a lvs_script.bkend for each macro
set i = 1
while ( $i <= $n )
	set cell_name = "`gawk '{if (NR == $i) print}' $block_list`"
	#echo $cell_name
    ## modify the layout/source top name
    set old_layout_name = `gawk '/set_layout_top/{print $3}' lvs_script.bkend`
    set old_source_name = `gawk '/set_source_top/{print $3}' lvs_script.bkend`
    #echo $old_layout_name
    sed 's/'"$old_layout_name"'/'"$cell_name"'/' lvs_script.bkend | sed 's/'"$old_source_name"'/'"$cell_name"'/' > lvs_script.bkend.$cell_name

	## create dir for each macro to run lvs check, be careful to remove the last version lvs_script.bkend
	echo "========================= STATUS ==========================" >> lvs.status
	echo "-->   Checking Cell: $cell_name ......"
	mkdir -p $cell_name
    if ( -e $cell_name/lvs_script.bkend ) then 
        rm -rf ./$cell_name/lvs_script.bkend
    endif
    mv -f lvs_script.bkend.$cell_name $cell_name/lvs_script.bkend

	## perform the lvs check
	cd ./$cell_name
	bkend lvs_script.bkend
	
	## write lvs result summary report
    set result = `tail -11 lvs.rep.log | head -1 | gawk '{print $3}'`
    if ( $result == "CORRECT." ) then 
        echo "$i.   $cell_name      $result" >> ../lvs.sum
    else if ( $result == "INCORRECT." ) then
        echo "$i.   $cell_name      $result" >> ../lvs.sum
    else
        echo "$i.   $cell_name doesn't perform lvs. Please check the layout/spi name!" >> ../lvs.sum
    endif
    
	cd ..

	## remove the tmp file
	#\rm -rf lvs_script.bkend.$cell_name.tmp*

	@ i++
end

exit
```
---
**NOTE:**

实际使用过程中，遍历所有cell的lvs check所花的时间并不理想，因为公司job控制，无法并行执行。这个script只适合无人值守时，下班丢到服务器上，第二天再check report。

**To_Do**

- [x] 遍历所有`lvs.rep.log`，grep出有error的block，然后创建`summary.rep`
- [x] 如果`lvs.rep.log`不存在，即lvs未成功，如何处理？
- [x] 如果lvs "INCORRENT"，如何标记？ 
- [ ] 清除旧版`lvs.rep.log`，如何确认该log是最新的？

### 如何备份所有block lvs的script

分别对每个block run lvs后，如果有某些block update，如果此时script还存在，就可以直接修改script/rule

```
#!/usr/bin/csh -f
mkdir -p script
set dir_names = `find . -maxdepth 1 -type d ! -name "." ! -name "script"`
echo $dir_names
foreach dir ($dir_names)
    cd $dir
    #pwd
    set script_name = `pwd | xargs basename`
    #echo $script_name
    cp lvs_script.bkend ../script/lvs_$script_name.bkend
    cd ..
end

exit
