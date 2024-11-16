#!/bin/bash


#############################################################################################
## This script run lefse using the lefse-formated file, e.g., 1st column = sample names,   ##
##  2nd column = class, other columns = OTUs                                               ##
##                                                                                         ##
## outputs: pdf, png, and svg figures for both cat                                         ##
##                                                                                         ##
## Contact: zhongzhipingemail@gmail.com                                                    ## 
#############################################################################################


## help message
usage() {
echo -e "
This script makes AA db and blastp to db to get format 6 output.

Required arguments:
-i      input file: the format for lefse

-f      set whether the features are on rows (default) or on columns

-c      set which feature use as class (default 2)

-s      set which feature use as subclass (default -1 meaning no subclass)

-u      set which feature use as subject (default 1 meaning the 1st row or column as subject)


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
col_row=r
class=2
subclass=-1
subject=1

while getopts "i:f:c:u:" opt
do
  case $opt in
    i)
        input_file=$OPTARG;;
    
    f)
        col_row=$OPTARG;;

    c)
        class=$OPTARG;;

    s)
        subclass=$OPTARG;;

    u)
        subject=$OPTARG;;

    \?)
        echo "invalid argument"
        exit 1;;
  esac
done


## path of base working directory
path_input=$(readlink -f $input_file)
workDir=${path_input%/*}
input_file=$path_input
cd $workDir



# ## working directory  %%%%%% this needs change
# workDir=/fs/project/PAS1117/zhiping/2_16s/2_Guliya-2018/1_16S_qiime2/2_output-combine_1-2-3/08_picrust2_lefse/01_pathway
# cd $workDir

## input file  %%%%%% this needs change
# input_file=${workDir}/path_abun_unstrat_descrip_Climate.txt

## names
input_file_name_tem=${input_file##*/}
input_file_name=${input_file_name_tem%.*}


## tool
module load anaconda
source activate lefse1

## run lefse
# 1. format %%%%%% this may need change
format_input.py ${input_file} ${input_file_name}_lefse.txt -f $col_row -c $class -s $subclass -u $subject -o 1000000 --output_table ${input_file_name}_tem.txt

# 2. get LDA scores
run_lefse.py ${input_file_name}_lefse.txt ${input_file_name}_lefse_visua.txt

# 3. plot
enriched_class_num=$(cat ${input_file_name}_lefse_visua.txt | cut -f3 | sed "/^$/d" | sort -u | wc -l)
echo $enriched_class_num

if [ $enriched_class_num -eq 1 ]; then
  plot_res.py ${input_file_name}_lefse_visua.txt ${input_file_name}_lefse_visua.pdf --format pdf --left_space 0.6
  plot_res.py ${input_file_name}_lefse_visua.txt ${input_file_name}_lefse_visua.svg --format svg --left_space 0.6
  plot_res.py ${input_file_name}_lefse_visua.txt ${input_file_name}_lefse_visua.png --format png --left_space 0.6
else
  plot_res.py ${input_file_name}_lefse_visua.txt ${input_file_name}_lefse_visua.pdf --format pdf
  plot_res.py ${input_file_name}_lefse_visua.txt ${input_file_name}_lefse_visua.svg --format svg
  plot_res.py ${input_file_name}_lefse_visua.txt ${input_file_name}_lefse_visua.png --format png
fi

# 4. plot cladogram - this is optional step
plot_cladogram.py ${input_file_name}_lefse_visua.txt ${input_file_name}_lefse_visua_cladogram.pdf --format pdf
plot_cladogram.py ${input_file_name}_lefse_visua.txt ${input_file_name}_lefse_visua_cladogram.svg --format svg
plot_cladogram.py ${input_file_name}_lefse_visua.txt ${input_file_name}_lefse_visua_cladogram.png --format png

## deactivate lefse & conda
conda deactivate
module unload anaconda
