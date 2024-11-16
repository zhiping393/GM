#!/bin/bash


## working directory
workDir=path/to/fastq/reads
cd $workDir

## run fastqc
export PATH=path/to/software/FastQC/:$PATH

for input_fastq in *.fastq.gz
do
	name=${input_fastq%.fastq.gz*}
	zcat $input_fastq > ${name}.fastq
	mkdir fastqc_output_${name}
	fastqc ${name}.fastq -f fastq -o fastqc_output_${name}
	rm ${name}.fastq
done

## view the results using a browser
