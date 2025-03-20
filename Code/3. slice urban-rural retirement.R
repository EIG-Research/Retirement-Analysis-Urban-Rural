
# last update: 02/04/2025 by Jason He

# Project: Retirement Update 2025; Urban versus Rural

# File Description: read in cleaned SIPP 2023 data to find urban-rural differences in
# retirement account size, access to employer plan, share of employer who offer matching
# benefits, and share of workers who participate in employers' retirement plan.

# remove dependencies
rm(list = ls())

# load packages
library(dplyr)
library(tidyverse)

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
sipp_path = file.path(data_path, "SIPP/2023")
output_path = file.path(project_path, "Output")

####################
# load in cleaned SIPP data
load(file.path(output_path, "SIPP_2023_WRANGLED.RData"))

# list of retirement-related features
ret_features <- c("TVAL_RET", "ANY_RETIREMENT_ACCESS", "MATCHING", "PARTICIPATING")
ret_features_weighted <- unlist(lapply(ret_features, FUN = function(x){paste0("weighted_", x)}))

# extract 2023 SIPP responses with identifiable metropolitan residency status and pre-process data
sipp_2023_metro <- sipp_2023 %>% filter(METRO_STATUS != "Not identified") %>%
  
  # convert yes-no responses into binary
  mutate(across(ret_features[-1], function(feature){ifelse(feature == "No",0,1)})) %>%
  
  # weigh variables by population weight
  mutate(across(ret_features, ~ .x * WPFINWGT, .names = "weighted_{.col}"))

####################
# summarise with respect to a respondent's residence in an urban or rural area
ret_sipp_2023 <- sipp_2023_metro %>%
  
  # group by if residence is in a metro or non-metro area as proxy for urban-rural
  drop_na(METRO_STATUS) %>% group_by(METRO_STATUS) %>%
  
  # find weighed averages of retirement account size and the fractions of respondents who:
  #   1. Have access to any employer retirement plan
  #   2. Work for firms offering matching retirement plans
  #   3. Participate in a retirement plan
  summarise(across(ret_features_weighted, ~ sum(.x)/sum(WPFINWGT))) %>%
  
  # calculate size of urban / rural group
  left_join(sipp_2023_metro %>% count(METRO_STATUS), by = "METRO_STATUS") %>%
  
  # rename variables
  rename(AVG_ACCOUNT_SIZE = weighted_TVAL_RET,
         SHARE_RETIREMENT_ACCESS = weighted_ANY_RETIREMENT_ACCESS,
         SHARE_MATCHING = weighted_MATCHING,
         SHARE_PARTICIPATION = weighted_PARTICIPATING,
         SAMPLE_SIZE = n)

# Change retirement access, matching, and participation to percent without
ret_sipp_2023 <- ret_sipp_2023 %>%
  mutate(across(c("SHARE_RETIREMENT_ACCESS", "SHARE_MATCHING", "SHARE_PARTICIPATION"), ~1-.x))

# save output
setwd(output_path)
write.csv(ret_sipp_2023, "urban_rural_retirement.csv", row.names = FALSE)


# national mean retirement account value
sipp_2023 %>%
  ungroup() %>%
  summarise(mean(TVAL_RET))
  
  summarise(weighted.mean(TVAL_RET, w = WPFINWGT, na.rm = TRUE))
  

# crosstab: retirement match, access
sipp_2023 %>%
  filter(METRO_STATUS == "Non-metropolitan area") %>%
  ungroup() %>%
  group_by(MATCHING, ANY_RETIREMENT_ACCESS) %>%
  summarise(count = sum(WPFINWGT)) %>%
  
  # we want -- the share who has access, but no match
  ungroup() %>% mutate(sum = sum(count),
                       shae = count/sum*100)
