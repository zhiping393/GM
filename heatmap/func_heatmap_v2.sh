#!/bin/bash


###########################################################################
## for help message, run func_heatmap_v2.sh -h
##
##
## Contact: zhongzhipingemail@gmail.com
###########################################################################



## help message
usage() {
echo -e "
This script plot a heatmap

Required arguments:
-i      input out table (required: 1st column is otu names, 1st row is sample names; columns are tab seperated)

-b      values (integer) of break for colors (required: values were connected by '-'; e.g., 0-1-5-10-20-40-60-70; may also works for decimals) 

-c      Gradient color type: 1 or 2. 1: blank-yellow-green-blue; 2: blank-grey-orange-blue (default: 1)

-d      the distance matrix type for clustering OTUs and samples: euclidean, manhattan, maximum, canberra,
        binary, minkowski, or correlation (default: euclidean)
        'correlation', 'euclidean', 'maximum', 'manhattan', 'canberra', 'binary', 'minkowski'

-r      if cluster the rows: T or F (default: F)

-m      if cluster the columns: T or F (default: F)

Optional arguments:
-h, --help   show this help message
"
}

if [ -z "$1" ] || [[ $1 == -h ]] || [[ $1 == --help ]]; then
  usage
  exit 1
fi

## determine if the 1st argument is start with "-"
head=${1:0:1}
if [[ $head != - ]]; then
  echo "syntax error. You need an argument"
  usage
  exit 1
fi

## arguments, variables, and default values
color_type="1"
distance_type="euclidean"
row_cluster="F"
col_cluster="F"
while getopts "i:b:c:d:r:m:" opt
do
  case $opt in
    i)
        input_out_table=$OPTARG;;

    b) 
        breaks=$OPTARG;;

    c) 
        color_type=$OPTARG;;

    d)
        distance_type=$OPTARG;;

    r)
        row_cluster=$OPTARG;;

    m) 
        col_cluster=$OPTARG;;

    \?)
        echo "invalid argument"
        exit 1;;
  esac
done

## path of base working directory
path_input=$(readlink -f $input_out_table)
workDir=${path_input%/*}
cd $workDir

## names
input_name_tem=${path_input##*/}
input_name=${input_name_tem%.*}

#########################

## message
echo -e "\n  Data analyzing..."

## break
# breaks="0-1-5-10-20-40-60-70"
break_len=$(echo $breaks | sed "s/-/\n/g" | wc -l)

echo $breaks | sed "s/-/\n/g" > break_line.txt

echo -n > break_vs_order.txt
for break_order in $(seq 1 $break_len)
do
  echo $break_order >> break_vs_order.txt
done

paste break_line.txt break_vs_order.txt > ${input_name}_break_vs_order.txt
rm break_line.txt break_vs_order.txt

## get script - func_break.sh
break_first=$(echo $breaks | cut -f1 -d "-")
echo -e '#!/bin/bash' > func_break.sh
echo -e 'cat output_data_all_cell.txt | while read num; do' >> func_break.sh
echo -e '    if (( $(echo "$num == '$break_first'" | bc -l) )); then' >> func_break.sh
echo -e '        echo 1 >> output_tem.txt' >> func_break.sh

for break_num in $(seq 2 ${break_len})
do
	break_left=$(echo $breaks | cut -f $((break_num - 1)) -d "-")
	break_right=$(echo $breaks | cut -f ${break_num} -d "-")
	echo -e '    elif (( $(echo "$num > '$break_left'" | bc -l) )) && (( $(echo "$num <= '$break_right'" | bc -l) )); then' >> func_break.sh
	echo -e '        echo '$break_num' >> output_tem.txt' >> func_break.sh
done
echo -e "    fi\ndone" >> func_break.sh




#############################################################
input_file=$path_input
row_num=$((`cat $input_file | wc -l` - 1))
col_num=$((`cat $input_file | sed -n 2p | sed "s/\t/\n/g" | wc -l` - 1))

## headers
head -1 $input_file > output_header_row.txt
cut -f1 $input_file | sed "1"d > output_header_col.txt

## get the range file
data_all_cells=$(cat $input_file | sed "1"d | cut -f 1 --complement)
echo $data_all_cells | sed "s/ /\n/g" | sort -u | sort -g > ${input_name}_value-range.txt
echo $data_all_cells | sed "s/ /\n/g" > output_data_all_cell.txt

## change numbers %%%%%% need to change the range
echo -e "\c" > output_tem.txt
sh func_break.sh
mv func_break.sh ${input_name}_func_break.sh

## make table back
for column in $(seq 1 ${col_num}); do echo -e "- \c" >> col_num_tem.txt; done; echo >> col_num_tem.txt
col_num_tem=$(head -1 col_num_tem.txt)
cat output_tem.txt | paste $col_num_tem > output_tem_table_tem.txt

## add headers back
paste output_header_col.txt output_tem_table_tem.txt > output_tem_table_tem_1.txt
cat output_header_row.txt output_tem_table_tem_1.txt > output_table.txt

## clean files
rm output_tem*
rm col_num_tem.txt
rm ${input_name}_func_break.sh
rm output_header*
rm output_data_all_cell.txt



##################################################################################################
## Below are R scripts
##
##################################################################################################

## tools 
module use /users/PAS1117/osu7810/local/share/modulefiles
module load R &> /dev/null
module load R/3.6.1 &> /dev/null

## run R script
# export PATH=/users/PAS1117/osu7810/functions/:$PATH
Rscript /users/PAS1117/osu7810/functions/func_heatmap_R_v2.R --work-directory $workDir --input-file output_table.txt --break-orderfile ${input_name}_break_vs_order.txt --len-break $break_len --file-name $input_name --color-type $color_type --distance-type $distance_type --cluster-row $row_cluster --cluster-col $col_cluster

