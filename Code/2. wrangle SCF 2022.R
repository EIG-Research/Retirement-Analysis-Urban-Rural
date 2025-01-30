

# last update: 01/30/2025 by Sarah Eckhardt

# Project: Retirement Update 20205; Urban versus Rural

# File Description: read in 2022 SCF data and prepare for analysis


# remove dependencies
rm(list = ls())

# load packages
library(dplyr)
library(haven)

# set user path
project_directories <- list(
  "sarah" = "/Users/sarah/Documents/GitHub/Retirement-Analysis-Urban-Rural"
)

current_user <- Sys.info()[["user"]]
if (!current_user %in% names(project_directories)) {
  stop("Root folder for current user is not defined.")
}


# set project paths
project_path = project_directories[[current_user]]
data_path = file.path(project_path, "Data")
scf_path = file.path(data_path, "SCF/2022")
output_path = file.path(project_path, "Output")


# set working directory for 2022 SCF
setwd(scf_path)