#!/bin/bash

###################################################################################
##
##
## Usage: func_SCNIC.sh feature_table.biom.txt
## 
####################################################################################

## input biom file 
input_biom_summary=$1


## detect working directory
path_input=$(readlink -f $input_biom_summary)
workDir=${path_input%/*}
cd $workDir


## names
name_input_biom_tem=${path_input##*/}
name_input_biom=${name_input_biom_tem%.*}


## tools
module use /fs/project/PAS1117/zhiping/software/1_modules/modulefiles
module load anaconda3.6
source activate qiime2-2021.2
export PATH=path/to/envs/fastspar/bin:$PATH


## convert to biom file
biom convert -i $path_input -o ${name_input_biom}.biom --to-hdf5 --table-type="OTU table"


## calculate sample number
col_num=$(cat $input_biom_summary | tail -1 | awk -F ' ' '{print NF}')
sample_num=$((col_num - 1))
echo -e "\nThere are ${sample_num} samples\n"


## qiime 2 import biom file
qiime tools import --input-path ${name_input_biom}.biom --type 'FeatureTable[Frequency]' --input-format BIOMV210Format --output-path ${name_input_biom}.qza


## filter features that were present <=6 samples (i.e., seven or more samples are better for correlation analyses)
qiime feature-table filter-features --i-table ${name_input_biom}.qza --p-min-samples 7 --o-filtered-table ${name_input_biom}-filtered_tem.qza


## filter features and samples ()
qiime SCNIC sparcc-filter --i-table ${name_input_biom}-filtered_tem.qza --o-table-filtered ${name_input_biom}-filtered.qza


## calculate correlations
# qiime SCNIC calculate-correlations --i-table ${name_input_biom}-filtered.qza --p-method pearson --o-correlation-table ${name_input_biom}-filtered_correlation.qza
qiime SCNIC calculate-correlations --i-table ${name_input_biom}-filtered.qza --p-method sparcc --o-correlation-table ${name_input_biom}-filtered_correlation.qza


## build network based on correlations
qiime SCNIC build-correlation-network-r --i-correlation-table ${name_input_biom}-filtered_correlation.qza --p-min-val .35 --o-correlation-network ${name_input_biom}-filtered_correlation_net.qza


## make modules (only positive correlations)
qiime SCNIC make-modules-on-correlations \
  --i-correlation-table ${name_input_biom}-filtered_correlation.qza \
  --i-feature-table ${name_input_biom}.qza \
  --p-min-r .35 \
  --o-collapsed-table ${name_input_biom}-filtered_correlation.collapsed.qza \
  --o-correlation-network ${name_input_biom}-filtered_correlation_net.modules.qza \
  --o-module-membership ${name_input_biom}-filtered_correlation_membership.qza


## qiime export files to get viewable data
qiime tools export --input-path ${name_input_biom}-filtered_correlation.qza --output-path ${name_input_biom}-filtered_correlation-qza

qiime tools export --input-path ${name_input_biom}-filtered_correlation_net.modules.qza --output-path ${name_input_biom}-filtered_correlation_net.modules-qza

qiime tools export --input-path ${name_input_biom}-filtered_correlation_net.qza --output-path ${name_input_biom}-filtered_correlation_net-qza

qiime metadata tabulate --m-input-file ${name_input_biom}-filtered_correlation_membership.qza --o-visualization ${name_input_biom}-filtered_correlation_membership.qzv

qiime tools export --input-path ${name_input_biom}-filtered_correlation_membership.qzv --output-path ${name_input_biom}-filtered_correlation_membership-qzv



## clean
conda deactivate

