#!/bin/bash


cd $DIR
#rm -rf Binning
mkdir Binning
cd Binning
 
#Load unitem into environment
source /miniconda3/bin/activate unitem
 
 #Run various binning tools
 unitem bin --gm2 --bs --mb2 --max40 --max107 $ASSEMBLY unitem_bins --cov_file coverage.tsv -c 20
# g
 #Obtain set of bins from binning tools using profile,consensus
 unitem profile -c 20 -f unitem_bins/bin_dirs.tsv unitem_bins/profile
 
 unitem consensus -f unitem_bins/bin_dirs.tsv unitem_bins/profile unitem_bins/consensus
 
 conda deactivate
 
# #dependency of das_tool
#module load usearch
export R_LIBS=/miniconda3/envs/das_tool/lib/R/library/
export PATH=$PATH:/users/PAS1018/osu9681/bin/
#  
#  #Load das_tool into environment
source /miniconda3/bin/activate das_tool
#ls 
 #Run Fasta_to_Scaffolds2Bin script from das_tool to obtain my_scaffolds2bin.tsv for each assembly method
while IFS=$'\t' read -r -a myArray
do
         assembly="${myArray[0]}"
         FILEPATH="${myArray[1]}"
         FILETYPE=$(python /miniconda3/envs/das_tool/bin/get_file_type.py "${myArray[1]}")
         #echo $FILETYPE
         if Fasta_to_Scaffolds2Bin.sh -i ${myArray[1]} -e ${FILETYPE} > ${myArray[1]}/my_scaffolds2bin.tsv ; then
         	all_filepath+=${FILEPATH}/my_scaffolds2bin.tsv,
         	all_assembly+=${assembly},
         else
		echo "Fasta to scaffold did not run." 
	 fi
	#break
done < unitem_bins/bin_dirs.tsv
#exit 
all_filepath=${all_filepath::-1}
all_assembly=${all_assembly::-1}
 
echo $all_filepath
echo $all_assembly
#exit 
mkdir das_tool
 #Run das_tool -- doesn't take too long
DAS_Tool  -i ${all_filepath} -l ${all_assembly} -c $ASSEMBLY -o das_tool/${SAMPLE} -t 20 --write_bin_evals 1 --write_bins 1
 
 #Due to a metabat dependency, all bins must have .fa or .fasta extension, so need to change groopm2 bin names
if cd unitem_bins/groopm2 ; then
 
	for d in *; do
	        if [[ ${d: -4} == ".fna" ]]
	        then
	                mv $d ${d::-4}.fa
	        fi
	done
 
	cd ../../
fi

conda deactivate
 
 #Load metawrap into the environment
source /miniconda3/bin/activate metawrap
 
 #Run metawrap on metabat2, groopm2, and maxbin 107 gene marker set
metaWRAP bin_refinement -o metawrap_out -A unitem_bins/metabat2/ -B unitem_bins/groopm2/ -C unitem_bins/maxbin_ms107/ -t 20 -m 100
 
conda deactivate
 
source /miniconda3/bin/activate unitem
 
mkdir All_tools_bins
 
python /miniconda3/envs/unitem/bin/combine_all_bins.py ${SAMPLE}
 
cd All_tools_bins
 
for d in *; do
        if [[ ${d: -3} != ".fa" ]]
        then
 		#echo $d
                mv $d ${d::-4}.fa
        fi
done
 
cd ..
mkdir -p checkm_out
checkm lineage_wf -t 20 -x fa All_tools_bins checkm_out
 
checkm qa --tab_table -t 20 checkm_out/lineage.ms checkm_out/ > checkm_out/qa_report.txt

if cd checkm_out/ ; then

	python /miniconda3/envs/unitem/bin/get_genome_info.py

	cd ..
fi

conda deactivate

# source /miniconda3/bin/activate dRep
# 
# dRep dereplicate dRep_99 -g All_tools_bins/*.fa -comp 70 -con 10 -p 20 --genomeInfo checkm_out/genomeinfo.csv -sa 0.99
# 
# dRep dereplicate dRep_97 -g All_tools_bins/*.fa -comp 70 -con 10 -p 20 --genomeInfo checkm_out/genomeinfo.csv -sa 0.97
# 
# source /miniconda3/bin/activate unitem
# 
# unitem unique dRep_99/dereplicated_genomes -x fa > dRep_99/dRep_99_unitem_uniqueCmd.txt
# 
# unitem unique dRep_97/dereplicated_genomes -x fa > dRep_97/dRep_97_unitem_uniqueCmd.txt
# pwd

#mkdir Binning

#mv All_tools_bins Binning

#mv checkm_out Binning

#mv dRep_9* Binning

#mv metawrap_out Binning

#mv unitem_bins Binning

#mv das_tool Binning

rm singlem_otu_table.csv

###################################################################################################
##	Refinement Step										  #
####################################################################################################
#
#cd Binning
#
#
mkdir Initial_binning/
mv * Initial_binning/
        #cd $d/Binning/All_tools_bins/

#mv Refinement Refinement_old

if [ -d "Initial_binning/das_tool/${SAMPLE}_DASTool_bins/" ]; then
	echo -e "DAS\t${DIR}/Binning/Initial_binning/das_tool/${SAMPLE}_DASTool_bins/" > bin_dirs_refine.txt
fi

if [ -d "Initial_binning/metawrap_out/metawrap_bins/" ]; then
	echo -e "metawrap\t${DIR}/Binning/Initial_binning/metawrap_out/metawrap_bins/" >> bin_dirs_refine.txt
fi

if [ -d "Initial_binning/unitem_bins/consensus/bins/" ]; then
	echo -e "unitem\t${DIR}/Binning/Initial_binning/unitem_bins/consensus/bins/" >> bin_dirs_refine.txt
fi

source /miniconda3/bin/activate unitem

#rm -rf Refinement
mkdir Refinement
cd Refinement
mkdir unitem_bins
cd ..
#Obtain set of bins from binning tools using profile,consensus
unitem profile -c 20 -f bin_dirs_refine.txt Refinement/unitem_bins/profile

unitem consensus -f bin_dirs_refine.txt Refinement/unitem_bins/profile Refinement/unitem_bins/consensus

conda deactivate

#dependency of das_tool
#module load usearch
export R_LIBS=/miniconda3/envs/das_tool/lib/R/library/
export PATH=$PATH:/users/PAS1018/osu9681/bin/

#Load das_tool into environment
source /miniconda3/bin/activate das_tool

#Run Fasta_to_Scaffolds2Bin script from das_tool to obtain my_scaffolds2bin.tsv for each assembly method
while IFS=$'\t' read -r -a myArray
do
         assembly="${myArray[0]}"
         FILEPATH="${myArray[1]}"
         FILETYPE=$(python /miniconda3/envs/das_tool/bin/get_file_type.py "${myArray[1]}")
         #echo $FILETYPE
         Fasta_to_Scaffolds2Bin.sh -i ${myArray[1]} -e ${FILETYPE} > ${myArray[1]}/my_scaffolds2bin.tsv
         all_filepath_two+=${FILEPATH}/my_scaffolds2bin.tsv,
         all_assembly_two+=${assembly},
         #break
done < bin_dirs_refine.txt


all_filepath=${all_filepath_two::-1}
all_assembly=${all_assembly_two::-1}

echo $all_filepath
echo $all_assembly
pwd
mkdir Refinement/das_tool

#Run das_tool -- doesn't take too long
DAS_Tool -i ${all_filepath} -l ${all_assembly} -c $ASSEMBLY -o Refinement/das_tool/${SAMPLE} -t 20 --write_bin_evals 1 --write_bins 1

conda deactivate

cur_dir=$(pwd)

cd Initial_binning/unitem_bins/consensus/bins

for d in *; do
        if [[ ${d: -4} == ".fna" ]]
        then
                mv $d ${d::-4}.fa
        fi
done

cd $cur_dir

#Load metawrap into the environment
source /miniconda3/bin/activate metawrap

mkdir -p Refinement/metawrap_out/

#Run metawrap on ensemble pool of bins
metaWRAP bin_refinement -o Refinement/metawrap_out -A Initial_binning/das_tool/${SAMPLE}_DASTool_bins -B Initial_binning/metawrap_out/metawrap_bins/ -C Initial_binning/unitem_bins/consensus/bins/ -t 20 -m 100

conda deactivate

source /miniconda3/bin/activate unitem

cd Refinement/metawrap_out/

if checkm lineage_wf -t 20 -x fa metawrap_bins/ checkm_out ; then

	checkm qa --tab_table -t 20 checkm_out/lineage.ms checkm_out/ > checkm_out/qa_report.txt
	
	cd checkm_out/

	python /miniconda3/envs/unitem/bin/get_genome_info.py

	#cd $cur_dir
fi

cd $cur_dir

cd Refinement/das_tool

if checkm lineage_wf -t 20 -x fa ${SAMPLE}_DASTool_bins checkm_out ; then

	checkm qa --tab_table -t 20 checkm_out/lineage.ms checkm_out/ > checkm_out/qa_report.txt

	cd checkm_out/

	python /miniconda3/envs/unitem/bin/get_genome_info.py

	#cd $cur_dir
fi

cd $cur_dir

cd Refinement/unitem_bins

if checkm lineage_wf -t 20 -x fna consensus/bins/ checkm_out ; then

	checkm qa --tab_table -t 20 checkm_out/lineage.ms checkm_out/ > checkm_out/qa_report.txt

	cd checkm_out/

	python /miniconda3/envs/unitem/bin/get_genome_info.py

	#cd $cur_dir
fi

cd $cur_dir

cd Refinement

python /miniconda3/envs/unitem/bin/get_good_bins.py ${SAMPLE}

source /miniconda3/bin/activate refinem

FTYPE=$(python /miniconda3/envs/das_tool/bin/get_file_type.py best_tool_bins)

refinem scaffold_stats -x ${FTYPE} -c 20 $ASSEMBLY best_tool_bins scaffold_stats

refinem outliers --gc_perc 95 --td_perc 95 --no_plots scaffold_stats/scaffold_stats.tsv scaffold_stats_outliers

refinem filter_bins -x ${FTYPE} best_tool_bins scaffold_stats_outliers/outliers.tsv best_tool_bins_filtered

source /miniconda3/bin/activate py27

FTYPE=$(python /miniconda3/envs/das_tool/bin/get_file_type.py best_tool_bins_filtered)

source /miniconda3/bin/activate refinem

if checkm lineage_wf -t 20 -x ${FTYPE} best_tool_bins_filtered checkm_out_filtered ; then

        checkm qa --tab_table -t 20 checkm_out_filtered/lineage.ms checkm_out_filtered/ > checkm_out_filtered/qa_report.txt

        cd checkm_out_filtered/

        python /miniconda3/envs/unitem/bin/get_genome_info.py

        #cd $cur_dir
fi

#refinem scaffold_stats -c 20 $ASSEMBLY best_tool_bins_filtered scaffold_stats_filtered
