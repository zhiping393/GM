#!/bin/bash

#############################################################################################################
## run qiime2 for paired end reads
## need to change 5 inputs: 1) workdir=, 2) input_reads=, 3) metadatafile=, 4) classifier=, and 5) bar_name=
##
## Contact: zhongzhipingemail@gmail.com 
#############################################################################################################

## load software
module use /users/PAS1117/osu7810/local/share/modulefiles
module load anaconda/anaconda2
source activate qiime2-2021.2


## work directory %%%%%%
workdir=path/to/working/directory
cd $workdir


## input raw reads directory %%%%%%
input_reads=path/to/raw/reads/directory


## metadata file %%%%%% 
metadatafile=metafile_16S.txt


## classifier to assin the representative reads %%%%%%
classifier=path/to/database/classifier_silver/16S/classifier_notrim.qza


## barcode name %%%%%%
bar_name=BarcodeSequence



################## run qiime2 #####################
## import reads
qiime tools import \
 --type EMPPairedEndSequences \
 --input-path $input_reads \
 --output-path input_reads.qza


## demultiplex the sequence reads; no need for "--p-rev-comp-mapping-barcodes" for 16S outputs in our data
qiime demux emp-paired \
 --m-barcodes-file $metadatafile  \
 --m-barcodes-column $bar_name \
 --p-rev-comp-mapping-barcodes \
 --i-seqs input_reads.qza \
 --o-per-sample-sequences demux.qza \
 --o-error-correction-details demux-details.qza


## inport demultiplexed reads if your reads are already demultiplexed
# qiime tools import --type 'SampleData[PairedEndSequencesWithQuality]' --input-path 01_reads_demultiplexed --input-format CasavaOneEightSingleLanePerSampleDirFmt --output-path demux-paired-end.qza


## summarize and export reads data
qiime demux summarize \
 --i-data demux.qza \
 --o-visualization demux.qzv

qiime tools export \
 --input-path demux.qzv \
 --output-path demux-qzv

qiime tools export \
 --input-path demux.qza \
 --output-path demux

qiime tools export \
 --input-path demux-details.qza \
 --output-path demux-details


## denoise using dada2 - you will need to adjust parameters based on fastQC summary
qiime dada2 denoise-paired \
 --i-demultiplexed-seqs demux.qza \
 --p-trim-left-f 0 \
 --p-trim-left-r 0 \
 --p-trunc-len-f 150 \
 --p-trunc-len-r 150 \
 --o-table table.qza \
 --o-representative-sequences rep-seqs.qza \
 --o-denoising-stats denoising-stats.qza

qiime tools export \
  --input-path table.qza \
  --output-path table-qza


## summarize feature table, get representative sequence
qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file $metadatafile

qiime tools export \
  --input-path table.qzv \
  --output-path table-qzv

qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv

qiime metadata tabulate \
  --m-input-file denoising-stats.qza \
  --o-visualization denoising-stats.qzv

qiime tools export \
  --input-path denoising-stats.qzv \
  --output-path denoising-stats


## Generate a phylogenetic tree for the representative sequences
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza


## Alpha and beta diversity - sampleing depth depends on the sequencing efforts
# get the alpha + beta diversity core set data
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table table.qza \
  --p-sampling-depth 13000 \
  --m-metadata-file $metadatafile \
  --output-dir core-metrics-results


## Alpha rarefaction
qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-steps 50 \
  --p-max-depth 13000 \
  --m-metadata-file $metadatafile \
  --o-visualization alpha-rarefaction.qzv

qiime tools export \
  --input-path alpha-rarefaction.qzv \
  --output-path alpha-rarefaction-qzv

qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-steps 50 \
  --p-max-depth 17000 \
  --m-metadata-file $metadatafile \
  --o-visualization alpha-rarefaction_17000.qzv

qiime tools export \
  --input-path alpha-rarefaction_17000.qzv \
  --output-path alpha-rarefaction_17000-qzv


## Taxonomic analysis
qiime feature-classifier classify-sklearn \
  --i-classifier $classifier \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy.qza

qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv

qiime taxa barplot \
  --i-table table.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file $metadatafile \
  --o-visualization taxa-bar-plots.qzv


