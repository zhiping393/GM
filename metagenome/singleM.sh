#!/bin/bash



## loop
# for input_fastq in /fs/project/PAS1117/VranaLake/10_re-analysis/17_SingleM/01_raw_reads/*.gz; do qsub -v input_fastq=$input_fastq singleM.sh; done


## working directory  %%%%%% need to change
workDir=/workingPath/SingleM/02_singleM
cd $workDir

## input interleaved fastq reads  %%%%%% need to change
# input_fastq=${workDir}/45_GP2.126.8.B_NXT_clean.fastq.gz

## thread number  %%%%%% need to change
thread_num=5

## names
name_tem=${input_fastq##*/}
name=${name_tem%.fastq*}

## tool
module load singularity/current
module use /fs/project/PAS1117/modulefiles
module load singularityImages

## split interleaved reads to forward and reverse reads
sh /fs/project/PAS1117/zhiping/software/bbmap_38.43/reformat.sh in=${input_fastq} out1=${name}_R1.fastq.gz out2=${name}_R2.fastq.gz

## run singleM
# SingleM-0.13.2_alt.sif pipe --forward ${name}_R1.fastq.gz --reverse ${name}_R2.fastq.gz --otu_table output.otu_table_${name}.tsv --threads $thread_num
SingleM-0.13.2.sif pipe --forward ${name}_R1.fastq.gz --reverse ${name}_R2.fastq.gz --otu_table output.otu_table_${name}.tsv --threads $thread_num

## clean files
rm ${name}_R*.fastq.gz



## step 2 ## 
## input OTU table list (space seperated)  %%%%%% need to change
list_OTU_tables="output.otu_table_M100_M.tsv output.otu_table_M225_M.tsv output.otu_table_S100_M.tsv output.otu_table_S225_M.tsv output.otu_table_S50_M.tsv"

## tool
module use /fs/project/PAS1117/zhiping/software/1_modules/modulefiles
module load anaconda3.6

#### run singleM
## combine OTU tables to one table otu_table_combine.tsv
SingleM-0.13.2_alt.sif summarise --input_otu_tables $list_OTU_tables --output_otu_table otu_table_combine.tsv

## cluster combined OTU table - Cluster sequences, collapsing them into OTUs with less resolution, but with more robustness against sequencing error
SingleM-0.13.2_alt.sif summarise --input_otu_tables otu_table_combine.tsv --cluster --clustered_output_otu_table otu_table_combine_cluster.tsv

## convert OTU table to biom format - this step generates 14 biom files as there are 14 single copy marker genes; let's use rplB gene (for qiime analysis)
SingleM-0.13.2_alt.sif summarise --input_otu_tables otu_table_combine_cluster.tsv --biom_prefix otu_table_combine_cluster

## modify biom table by removing the text "Root; " in the taxonomy column, so they could be further used in qiime - some biom files may not work
echo "\nModify biom files..."
for input in *.biom; do 
	name_biom=${input%.biom*}
	biom convert -i $input -o ${name_biom}_tem.tsv --to-tsv --table-type="OTU table" # some biom files don't work if using '--header-key taxonomy'

	echo > ${name_biom}_tem_taxonomy.tsv
	cat ${name_biom}_tem.tsv | sed "1,2"d | cut -f1 | rev | cut -f1 -d ";" --complement | rev | sed "s/^$/Root; d__Others/g" | sed "1 itaxonomy" >> ${name_biom}_tem_taxonomy.tsv
	paste ${name_biom}_tem.tsv ${name_biom}_tem_taxonomy.tsv > ${name_biom}.tsv

	cat ${name_biom}.tsv | sed "s/Root; //g" > ${name_biom}_new.tsv
	biom convert -i ${name_biom}_new.tsv -o ${name_biom}_new.biom --to-hdf5 --table-type="OTU table" --process-obs-metadata taxonomy

	# clean
	rm ${name_biom}_tem.tsv ${name_biom}_tem_taxonomy.tsv

done

