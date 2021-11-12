library(tidyverse)
library(easyfulcrum)
#devtools::install_github("AndersenLab/easyfulcrum")

# set working directory to project directory
setwd(glue::glue("{dirname(rstudioapi::getActiveDocumentContext()$path)}/.."))

# assign the project directory to dir
dir <-  getwd()

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
# remove S-14886 and 18937992 from joined data below, neither are Caenorhabditis. 

# join genotype data with Fulcrum data
join_genofulc_nema <- joinGenoFulc(geno = proc_geno_nema, fulc = anno_fulc, dir = NULL, select_vars = TRUE) %>%
  dplyr::filter(!(s_label %in% c("S-14886", "18937992")))

# Process photos
`2021OctoberHawaii` <- procPhotos2(dir = dir, data = join_genofulc_nema,
                              max_dim = 500, overwrite = TRUE,
                              CeaNDR = TRUE)

# make the species sheet for CeNDR
raw_sp_sheet <- makeSpSheet(data = `2021OctoberHawaii`)

# fix the species sheet
fixed_sp_sheet <- raw_sp_sheet %>%
  dplyr::mutate(isolated_by = case_when(isolated_by == "robyn.tanny@northwestern.edu" ~ "R. Tanny",
                                        isolated_by == "emily.koury@northwestern.edu" ~ "E. Koury"),
                sampled_by = "E. Andersen") %>%
  dplyr::filter(species != "Caenorhabditis oiwi")

# export the fixed species sheet
rio::export(fixed_sp_sheet, file = "reports/spSheet.csv")

# Make final report
generateReport(data = `2021OctoberHawaii`, dir = dir, profile = "nematode")
