#!/bin/bash

#####################################################################
##  This script predicts functions based on 16S data using PICRUST2
##
##
#####################################################################

## need to change 3 inputs: 1) workDir=, 2) input_biom=, and 3) input_seqs=


## working directory
workDir=path/to/working/directory/picrust2
cd $workDir

## input files
input_biom=${workDir}/feature-table_sort_de_final_sub_GP2.biom # no taxnomy information here
input_seqs=${workDir}/seqs.fna # dereplicated sequences
# input_metadata=${workDir}/metafile_16S.txt # not used

## output folder name
output_folder=${workDir}/picrust2.4_output_1

## threshold number
threshold_no=8

## tools
module load anaconda
source activate picrust2
KO_path_mapfile=/path/to/KO/mapfile/software/picrust2-2.4.1/picrust2/default_files/pathway_mapfiles/KEGG_pathways_to_KO.tsv

#### run tools - using EC and metacyc pathway by default
# picrust2_pipeline.py -s $input_seqs -i $input_biom -o $output_folder --stratified -p $threshold_no --in_traits EC,KO,COG,PFAM,TIGRFAM --min_align 0.5 --reaction_func EC
picrust2_pipeline.py -s $input_seqs -i $input_biom -o $output_folder --stratified -p $threshold_no --in_traits EC,KO --min_align 0.5 --reaction_func EC

# picrust2_pipeline.py -s $input_seqs -i $input_biom -o $output_folder --stratified -p $threshold_no --in_traits EC,KO --min_align 0.5 --reaction_func KO --no_regroup --pathway_map $KO_path_mapfile

## output KO pathways
cd $output_folder
pathway_pipeline.py -i KO_metagenome_out/pred_metagenome_contrib.tsv.gz -o pathways_out_KO -p $threshold_no -m $KO_path_mapfile --no_regroup


## add descriptions for file
# 1) pathway outputs
cd $output_folder
mv pathways_out pathways_out_EC
add_descriptions.py -i pathways_out_EC/path_abun_unstrat.tsv.gz -o pathways_out_EC/path_abun_unstrat_descrip.tsv.gz -m METACYC
add_descriptions.py -i pathways_out_KO/path_abun_unstrat.tsv.gz -o pathways_out_KO/path_abun_unstrat_descrip.tsv.gz --custom_map_table /path/to/map.table/picrust2-2.4.1/picrust2/default_files/description_mapfiles/KEGG_pathways_info.tsv.gz

# 2) functional outputs
ls | grep 'metagenome_out' | while read line; do 
	name=${line%_meta*}	
	add_descriptions.py -i ${line}/pred_metagenome_unstrat.tsv.gz -m $name -o ${line}/pred_metagenome_unstrat_descrip.tsv.gz
done


