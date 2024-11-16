#!/usr/bin/env Rscript


## load libraries
no_warming = suppressPackageStartupMessages
library(optparse) 
library(lattice)
library(permute)
no_warming(library(vegan))
no_warming(library(gplots))
library(ggplot2)
library(pheatmap)
library(reshape)
# library(qpdf)
# library(Rcpp)

## script description
cat ("\n  Heatmap generating...\n\n")

# cat (
# "
# ---------------------------------------------------------------------------------------------
# Description: This script was used to plot a heatmap using an already-transfered OTU table as
#              input (from func_heatmap.sh). Input format: each row of the 1st column are OTU
#              name, each column of the 1st row are sample, other cells are numbers (of each
#              each OTU for each sample)
# ---------------------------------------------------------------------------------------------
# \n\n")



## default parameters
workDir = getwd()
distance_type = "euclidean"

## arguments
args = commandArgs(trailingOnly=TRUE)

parser = OptionParser()
parser = add_option(parser, c("-w", "--work-directory"), dest="work_directory", type="character", default=workDir, help="working directory to generate outputs [current default: %default]", metavar="")
parser = add_option(parser, c("-f", "--input-file"), dest="input_file", type="character", help="Required argument!! OTU table - alrady transfered", metavar="")
parser = add_option(parser, c("-b", "--break-orderfile"), dest="break_orderfile", type="character", help="Required argument!! the mataches between break and orders; generated from func_heatmap.sh", metavar="")
parser = add_option(parser, c("-l", "--len-break"), dest="len_break", type="integer", help="Required argument!! color number", metavar="")
parser = add_option(parser, c("-c", "--color-type"), dest="color_type", type="integer", help="Required argument!! color type, explained in bash script", metavar="")
parser = add_option(parser, c("-s", "--file-name"), dest="file_name", type="character", help="input file name, useful for output file", metavar="")
parser = add_option(parser, c("-d", "--distance-type"), dest="distance_type", type="character", default=distance_type, help="Optional argument. Only two options: euclidean or manhattan", metavar="")
parser = add_option(parser, c("-m", "--cluster-row"), dest="cluster_row", type="character", default=F, help="whether cluster rows [current default: %default]", metavar="")
parser = add_option(parser, c("-n", "--cluster-col"), dest="cluster_col", type="character", default=F, help="whether cluster columns [current default: %default]", metavar="")

# parser = add_option(parser, c("-r", "--cluster-row"), dest="cluster_row", type="character", default="T", help="Optional argument. Only two options: T or F", metavar="")
# parser = add_option(parser, c("-c", "--cluster-col"), dest="cluster_col", type="character", default="T", help="Optional argument. Only two options: T or F", metavar="")

opt = parse_args(parser)

## help if no argument used
if (is.null(opt$input_file)){
  print_help(parser)
  stop("At least one argument must be supplied -f", call.=FALSE)
}


#############################################################################################################
#### run script from below
#############################################################################################################
## enter the working directory
workDir <- opt$work_directory
setwd(workDir)

## file name
name=opt$file_name

## read input file and process it
input_table_tem <- opt$input_file
input_table <- read.table(opt$input_file,header = T,sep ="\t",row.names = 1)



## get colors 
colorType=opt$color_type
if (colorType == 1){
# col <-colorRampPalette(c(rgb(255,255,217,max=255),rgb(212,238,178,max=255),rgb(190,229,180,max=255),rgb(120,202,187,max=255),rgb(56,172,195,max=255),rgb(31,116,178,max=255),
#                          rgb(36,51,146,max=255),rgb(17,36,107,max=255)))(opt$len_break)
# col <-colorRampPalette(c(rgb(255,255,217,max=255),rgb(212,238,178,max=255),rgb(190,229,180,max=255),rgb(120,202,187,max=255),rgb(56,172,195,max=255),rgb(31,116,178,max=255),
#                          rgb(36,51,146,max=255)))(opt$len_break)

# col <-colorRampPalette(c(rgb(255,255,255,max=255),rgb(255,255,217,max=255),rgb(212,238,178,max=255),rgb(190,229,180,max=255),rgb(120,202,187,max=255),rgb(56,172,195,max=255),rgb(31,116,178,max=255),rgb(36,51,146,max=255)))(opt$len_break)
col <-colorRampPalette(c(rgb(255,255,255,max=255),rgb(212,238,178,max=255),rgb(190,229,180,max=255),rgb(120,202,187,max=255),rgb(56,172,195,max=255),rgb(31,116,178,max=255),rgb(36,51,146,max=255)))(opt$len_break)

} else {

col <-colorRampPalette(c("white",rgb(210,210,210,max=255),"bisque","orange","navy"))(opt$len_break)
# col <-colorRampPalette(c("white","grey","bisque","orange"))(opt$len_break)

}

## read input break-vs-order file - to get the heatmap legend
break_order_file <- opt$break_orderfile
input_break_order <- read.table(opt$break_orderfile,header = F,sep ="\t")
legend_break_input = input_break_order[,2]
legend_label_input = input_break_order[,1] 
# legend_label <- input_break_order [,1]
# file_legend <- paste(name, "_heatmap_legend.pdf", sep="")
# pdf(file_legend)
# plot.new();legend(x="right", legend=legend_label,fill=col, border = col, cex = 1,
#                   bty = "n", y.intersp = 0.6, text.width = 0.5) # cex, legend and text size; y.intersp, space between to legend
# dev.off()

## the distance matrix - two options here
distance_type <- opt$distance_type
# distanceType=opt$distance_type
# if (distanceType == "euclidean"){
#     drows1 <- "euclidean"
#     dcols1 <- "euclidean"
# } else if (distanceType == "manhattan"){
# 	drows1 <- "manhattan"
# 	dcols1 <- "manhattan"
# } else {
# 	print ("Wrong arguement, use euclidean or manhattan")
# 	quit(save = "no")
# }

## font size of labels
break_num <- opt$len_break

if (break_num > 50) {
  label_font_size = 1
} else if (break_num > 40 && break_num <=50) {
  label_font_size = 2
} else if (break_num > 30 && break_num <=40) {
  label_font_size = 4
} else if (break_num > 20 && break_num <= 30) {
  label_font_size = 5
} else if (break_num > 10 && break_num <= 20) {
  label_font_size = 8
} else {
  label_font_size = 10
}


## if cluster the rows or columns
cluster_row_or_not <- as.logical(opt$cluster_row)
cluster_col_or_not <- as.logical(opt$cluster_col)


## generate output file and heatmap figure
if (cluster_row_or_not || cluster_col_or_not) {
  filename <- paste(name, "_heatmap_", distance_type, "_c", colorType, ".pdf", sep="")
  } else {
    filename <- paste(name, "_heatmap_no-cluster_c", colorType, ".pdf", sep="")
  }

outfile <- paste(workDir, filename, sep="/")

hm.parameters <- list(input_table, 
                      color = col, main = "",
                      cellwidth = 15, cellheight = 5, scale = "none",
                      treeheight_row = 200, legend = TRUE, fontsize = label_font_size,
                      kmeans_k = NA, border=FALSE,
                      legend_breaks = legend_break_input, 
                      legend_labels = legend_label_input,
                      show_rownames = T, show_colnames = T,fontsize_row = 4, fontsize_col = 6,                      
                      clustering_method = "average",
                      cluster_rows = cluster_row_or_not, cluster_cols = cluster_col_or_not,
                      clustering_distance_rows = distance_type,
                      clustering_distance_cols = distance_type)


# do.call("pheatmap", hm.parameters)
do.call("pheatmap", c(hm.parameters, filename=outfile))

# ## combine heatmap and new legend
# pdf_combine(input = c(outfile_tem, file_legend), output = outfile)
# # file.remove(outfile_tem, file_legend)


## clean
cat ("  Congratulation! Heatmap has been generated here: ", filename, "\n\n", sep = "")

invisible(file.remove(break_order_file,input_table_tem))
