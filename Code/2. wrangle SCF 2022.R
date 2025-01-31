

# last update: 01/30/2025 by Sarah Eckhardt

# Project: Retirement Update 2025; Urban versus Rural

# File Description: read in 2022 Survey of Consumer Finances data and prepare for analysis
# Source: https://www.federalreserve.gov/econres/scfindex.htm

# remove dependencies
rm(list = ls())

# load packages
library(dplyr)
library(haven)

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
scf_path = file.path(data_path, "SCF/2022")
output_path = file.path(project_path, "Output")


# set working directory for 2022 SCF
setwd(scf_path)


###################
# read in SCF data


scf_2022_load = read_dta("p22i6.dta")


scf_2022 = scf_2022_load %>%
  
  # rename age and weight variables. 
  # see code book: https://www.federalreserve.gov/econres/files/bulletin.macro.txt
  rename(AGE = x14,
         WGT = x42001, # Revised Kennickell-Woodburn consistent weight
        INDUSTRY = x7402,
        WAGE_SALARY = x4112) %>% # for respondent only.
  
  mutate(FULL_PART_TIME = case_when(
    x4511 == 1 ~ "full time",
    x4511 == 2 ~ "part time",
    TRUE ~ NA),
    
    NON_GOVT_WORKER = case_when(
      INDUSTRY < 9370 ~ "non-government",
      TRUE ~ "government or out of universe"
    ),
    
    IN_AGE_RANGE = case_when(
      AGE >=18 & AGE <=65 ~ "yes",
      TRUE ~ "no"
    ),
    
    PARTICIPATES = case_when( 
    # (see https://www.federalreserve.gov/econres/files/bulletin.macro.txt) 
    # DCPLANCJ
      x11032 > 0 ~ "Yes",
      x11132 > 0 ~ "Yes",
      x11032 == -1 ~ "Yes",
      x11132 == -1 ~ "Yes",
      x5316 == 1 & x6461 == 1 ~ "Yes",
      x5324 == 1 & x6466 == 1 ~ "Yes",
      TRUE ~ "No"),
    
    ANY_RETIREMENT_ACCESS = case_when(
      PARTICIPATES == "Yes" ~ "Yes",
      x4136 == 1 ~ "Yes", # does the employer offer retirement plans
      TRUE ~ "No"
    ),
    
    MATCHING = case_when(
      x11047 == 1 ~ "Yes",
      x11147 == 1 ~ "Yes"),
    
    RETIREMENT_ACCT_VAL = # for reference person only; excl. family account vals.
      x6551 + x6552 + x6553 + # IRA accounts
      x6554 + # Keogh account
      x11032 # 401(k).403(B)/SRA/Thrift or Savings
  )

##############################
# select relevant sub-sample:
     # 18-65 years old
    # Private employees
    # Full-time workers with non-zero hours worked per week
    # Non-zero income

scf_2022 = scf_2022 %>%
  filter(IN_AGE_RANGE == "yes") %>%
  filter(NON_GOVT_WORKER == "non-government") %>%
  filter(FULL_PART_TIME == "full time") %>%
  filter(WAGE_SALARY > 0) %>%
  
  select(AGE, WAGE_SALARY, INDUSTRY, WGT,
         PARTICIPATES,
         ANY_RETIREMENT_ACCESS,
         MATCHING,
         RETIREMENT_ACCT_VAL)



# save output.
setwd(output_path)

save(scf_2022, file = "SCF_2022_WRANGLED.RData")
