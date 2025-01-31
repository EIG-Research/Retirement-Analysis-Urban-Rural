
# last update: 01/31/2025 by Jason He

# Project: Retirement Update 2025; Urban versus Rural

# File Description: read in cleaned SIPP 2023 data to find urban-rural differences in
# retirement account size, access to employer plan, share of employer who offer matching
# benefits, and share of workers who participate in employers' retirement plan.

# remove dependencies
rm(list = ls())

# load packages
library(dplyr)

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

# summarise with respect to a respondent's residence in an urban or rural area
ret_sipp_2023 <- sipp_2023 %>% filter(SPANEL == 2023, METRO_STATUS != "Not identified") %>%
  # convert yes-no responses into binary
  mutate(across(ret_features[-1], function(feature){ifelse(feature == "No",0,1)})) %>%
  # group by if residence is in a metro or non-metro area as proxy for urban-rural
  drop_na(METRO_STATUS) %>% group_by(METRO_STATUS) %>%
  # find average retirement account size and fraction of respondents who:
  #   1. Has access to any employer retirement plan
  #   2. Employer offers matching retirement plan
  #   3. Participates in a retirement plan
  summarise(across(ret_features, mean, na.rm = TRUE)) %>%
  # calculate size of urban / rural group
  left_join(sipp_2023 %>% filter(SPANEL == 2023, METRO_STATUS != "Not identified") %>%
              count(METRO_STATUS), by = "METRO_STATUS")

# save output.
setwd(output_path)
save(ret_sipp_2023, file = "sipp_2023_urban-rural_retirement.RData")
