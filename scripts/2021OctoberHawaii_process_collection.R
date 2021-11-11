library(tidyverse)
#devtools::install_github("AndersenLab/easyfulcrum")
library(easyfulcrum)

# set the project directory
dir = "~/repos/2021OctoberHawaii"

# make dir structure for processing
makeDirStructure(startdir = dir)

# read fulcrum data
raw_fulc <- readFulcrum(dir = dir)

# process the data
proc_fulc <- procFulcrum(data = raw_fulc)

# check temps, no need to run fixTemperatures()
flag_temp <- checkTemperatures(data = proc_fulc, return_flags = TRUE)

# join the fulcrum data
join_fulc <- joinFulcrum(data = proc_fulc, select_vars = TRUE) %>%
  # correct classes to match easyfulcrum::fulcrumTypes
  dplyr::mutate(gps_speed = as.numeric(gps_speed),
                gps_vertical_accuracy = as.numeric(gps_vertical_accuracy))
                  
# checking the join
flag_join <- checkJoin(data = join_fulc, return_flags = TRUE)
# Two variables with wrong class, gps_speed and gps_vertical_accuracy.
#   These are both fixed above.
# The two C-labels with missing s_labels should be dropped.

# annotate the collections
anno_fulc <- annotateFulcrum(data = join_fulc, dir = NULL, select_vars = TRUE)

# Read genotyping sheet
raw_geno_nema <- readGenotypes(gsKey = c("1wpHcvoWt3y3AsZNMKyPS2m5bEobeP8WEC68XkH6rofU"),
                               col_types = "cDDdcdcddddddDcDDdcdcdddddddcdcccddccc")

# process the genotyping sheet
proc_geno_nema <- checkGenotypes(geno_data = raw_geno_nema, fulc_data = anno_fulc, 
                                 return_geno = TRUE, return_flags = FALSE, profile = "nematode")

# join genotype data with Fulcrum data
join_genofulc_nema <- joinGenoFulc(geno = proc_geno_nema, fulc = anno_fulc, dir = NULL, select_vars = TRUE)

#-------------------------------------
# waiting for Robyn to finish the october sheet
#--------------------------------------

# Process photos
final_data_nema <- procPhotos2(dir = dir, data = join_genofulc_nema,
                              max_dim = 500, overwrite = TRUE,
                              CeNDR = TRUE)

# make the species sheet for CeNDR
sp_sheet <- makeSpSheet(data = final_data_nema, dir = dir)
# lots of issues to fix here, what's up with landscapes?

# Make final report
generateReport(data = final_data_nema, dir = dir, profile = "nematode")
