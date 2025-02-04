
# last update: 02/03/2025 by Sarah Eckhardt

# Project: Retirement Update 2025; Urban versus Rural

# Description: use CPS workforce size (better estimator than SIPP) to estimate
# the number of people without access, not participating, without matching.

# remove dependencies
rm(list = ls())

# load packages
library(dplyr)
library(tidyr)
library(readxl)

# set user path
project_directories <- list(
  "sarah" = "/Users/sarah/Documents/GitHub/Retirement-Analysis-Urban-Rural",
  "jiaxinhe" = "/Users/jiaxinhe/Documents/projects/Retirement-Analysis-Urban-Rural"
)

current_user <- Sys.info()[["user"]]
if (!current_user %in% names(project_directories)) {
  stop("Root folder for current user is not defined.")
}


# set project paths
project_path = project_directories[[current_user]]
data_path = file.path(project_path, "Data")
cps_path = file.path(data_path, "CPS")
output_path = file.path(project_path, "Output")


# set working directory for 2023 CPS
setwd(cps_path)


###################
# read in cps data

cps_2023 = read.csv("cps_00027.csv")


# filtering for relevant universe
cps_2023_sub = cps_2023 %>%
  filter(UHRSWORK1 >=35) %>% filter(UHRSWORK1 <999) %>% # full time, excl. nius.
  
  filter(AGE >=18 & AGE<=65) %>% # age filtering
  
  filter(CLASSWKR >=20 & CLASSWKR<24) %>% # non-government
  
  filter(INCTOT > 0) %>% # non-zero income
  
  mutate(METRO_STATUS = case_when(
    METRO >= 2 ~ "Metropolitan area",
    METRO == 1 ~ "Non-metropolitan area",
    TRUE ~ "not identified"
  ))


# generate population estimates by metro / non-metro
lab_force = cps_2023_sub %>% ungroup() %>% group_by(METRO_STATUS) %>%
  filter(METRO_STATUS != "not identified") %>%
  
  summarise(workers = sum(ASECWT, na.rm = TRUE))

    # print out
    lab_force  

    
###############################################################################
# merge in the counts of participation, access, matching. metro / non-metro.
load(paste(output_path, "SIPP_2023_WRANGLED.RData", sep="/"))

    
# participation
    participation = sipp_2023 %>%
    
      filter(METRO_STATUS != "Not identified" & !is.na(METRO_STATUS)) %>%
      filter(PARTICIPATING != "Missing") %>%
      
      ungroup() %>%  
      group_by(METRO_STATUS, PARTICIPATING) %>%
      summarise(count = sum(WPFINWGT)) %>%
      ungroup() %>% group_by(METRO_STATUS) %>%
      mutate(Share = count / sum(count)) %>%
      select(-c(count)) %>%
      
      left_join(lab_force) %>%
      mutate(worker_counts = Share*workers)

    
# access    
    access = sipp_2023 %>%
      filter(METRO_STATUS != "Not identified" & !is.na(METRO_STATUS)) %>%
      filter(ANY_RETIREMENT_ACCESS != "Missing") %>%
      
      ungroup() %>%
      group_by(METRO_STATUS, ANY_RETIREMENT_ACCESS) %>%
    
      summarise(count = sum(WPFINWGT)) %>%
      ungroup() %>% group_by(METRO_STATUS) %>%
      mutate(Share = count / sum(count)) %>%
      select(-c(count)) %>%
      
      left_join(lab_force) %>%
      mutate(worker_counts = Share*workers)


# matching    
    matching = sipp_2023 %>%
      ungroup() %>%
      group_by(METRO_STATUS, MATCHING) %>%
      filter(METRO_STATUS != "Not identified" & !is.na(METRO_STATUS)) %>%
      filter(MATCHING != "Missing") %>%
      summarise(count = sum(WPFINWGT)) %>%
      ungroup() %>% group_by(METRO_STATUS) %>%
      mutate(Share = count / sum(count)) %>%
      select(-c(count)) %>%
      
      left_join(lab_force) %>%
      mutate(worker_counts = Share*workers)


    
      # print out results
      access
      participation
      matching
