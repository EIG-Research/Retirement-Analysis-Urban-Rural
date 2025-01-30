

# last update: 01/30/2025 by Sarah Eckhardt

# Project: Retirement Update 20205; Urban versus Rural

# File Description: read in 2023 SIPP data and prepare for analysis


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
sipp_path = file.path(data_path, "SIPP/2023")
output_path = file.path(project_path, "Output")


# set working directory for 2023 SIPP
setwd(sipp_path)

####################
# load in SIPP data

sipp_2023_load = read_dta("pu2023.dta")

sipp_2023 = sipp_2023_load %>%
  
  filter(MONTHCODE == 12) %>% # Retirement data is collected in December, so we can drop all other months here
  mutate(
    EDUCATION = case_when(
      EEDUC >=31 & EEDUC <= 39 ~ "High School or less",
      EEDUC >= 40 & EEDUC <=42 ~ "Some college",
      EEDUC >= 43 & EEDUC <= 46 ~ "Bachelor's degree or higher",
      TRUE ~ "Missing"
    ),
    SEX = case_when(
      ESEX == 1 ~ "Male",
      ESEX == 2 ~ "Female",
      TRUE ~ "Missing"
    ),
    RACE = case_when(
      ERACE == 1 & EORIGIN ==2 ~ "Non-Hispanic White",
      ERACE == 2 & EORIGIN ==2 ~ "Non-Hispanic Black",
      ERACE == 3 & EORIGIN ==2 ~ "Asian",
      EORIGIN == 1 ~ "Hispanic",
      ERACE == 4 & EORIGIN == 2 ~ "Mixed/Other",
      TRUE ~ "Missing"
    ),
    EMPLOYMENT_TYPE = case_when(
      EJB1_JBORSE == 1 ~ "Employer",
      EJB1_JBORSE == 2 ~ "Self-employed (owns a business)",
      EJB1_JBORSE == 3 ~ "Other work arrangement",
      TRUE ~ "Missing"
    ),
    CLASS_OF_WORKER = case_when(
      EJB1_CLWRK == 1 ~ "Federal government employee",
      EJB1_CLWRK == 2 ~ "Active duty military",
      EJB1_CLWRK == 3 ~ "State government employee",
      EJB1_CLWRK == 4 ~ "Local government employee",
      EJB1_CLWRK == 5 ~ "Employee of a private, for-profit company",
      EJB1_CLWRK == 6 ~ "Employee of a private, not-for-profit company",
      EJB1_CLWRK == 7 ~ "Self-employed in own incorporated business",
      EJB1_CLWRK == 8 ~ "Self-employed in own not incorporated business",
      TRUE ~ "Missing"
    ),
    TOTYEARINC = TPTOTINC*12,
    ANY_RETIREMENT_ACCESS = case_when(
      EMJOB_401 == 1 ~ "Yes", # Any 401k, 403b, 503b, or Thrift Savings Plan account(s) provided through main employer or business during the reference period.
      EMJOB_IRA == 1 ~ "Yes", # Any IRA or Keogh account(s) provided through main employer or business during the reference period.
      EMJOB_PEN == 1 ~ "Yes", # Any defined-benefit or cash balance plan(s) provided through main employer or business during the reference period.
      EMJOB_401 == 2 ~ "No",
      EMJOB_IRA == 2 ~ "No",
      EMJOB_PEN == 2 ~ "No",
      EOWN_THR401  == 2 ~ "No",
      EOWN_IRAKEO  == 2 ~ "No",
      EOWN_PENSION == 2 ~ "No",
      TRUE ~ "Missing"
    ),
    PARTICIPATING = case_when(
      ESCNTYN_401 == 1 ~ "Yes", # During the reference period, respondent contributed to the 401k, 403b, 503b, or Thrift Savings Plan account(s) provided through their main employer or business.
      EECNTYN_401 == 1 ~ "Yes", # if they report having employer matching then we term them as participating 
      ESCNTYN_PEN == 1 ~ "Yes", # During the reference period, respondent contributed to the defined-benefit or cash balance plan(s) provided through their main employer or business.
      ESCNTYN_IRA == 1 ~ "Yes", # During the reference period, respondent contributed to the IRA or Keogh account(s) provided through their main employer or business.
      ESCNTYN_401 == 2 ~ "No",
      ESCNTYN_PEN == 2 ~ "No",
      ESCNTYN_IRA == 2 ~ "No",
      EOWN_THR401  == 2 ~ "No",
      EOWN_IRAKEO  == 2 ~ "No",
      EOWN_PENSION == 2 ~ "No",
      TRUE ~ "Missing"
    ),
    MATCHING = case_when(
      EECNTYN_401 == 1 ~ "Yes", # Main employer or business contributed to respondent's 401k, 403b, 503b, or Thrift Savings Plan account(s) during the reference period.
      EECNTYN_IRA == 1  ~ "Yes", # Main employer or business contributed to respondent's IRA or Keogh account(s) during the reference period.
      EECNTYN_401 == 2 ~ "No",
      EECNTYN_IRA == 2 ~ "No",
      EOWN_THR401  == 2 ~ "No",
      EOWN_IRAKEO  == 2 ~ "No",
      EOWN_PENSION == 2 ~ "No",
      # is.na(EECNTYN_401) ~ "No",
      TRUE ~ "Missing"
    ),
    METRO_STATUS = case_when(
      TMETRO_INTV == 1 ~ "Metropolitan area",
      TMETRO_INTV == 2 ~ "Nonmetropolitan area",
      TMETRO_INTV == 3 ~ "Not identified",
      TRUE ~ NA
    ),
    FULL_PART_TIME = case_when( # Define full time workers as those working at least 35 hours
      TJB1_JOBHRS1 >=35 ~ "full time",
      TJB1_JOBHRS1 >0 & TJB1_JOBHRS1< 35 ~ "part time",
      TRUE ~ NA
    ),
    IN_AGE_RANGE = case_when(
      TAGE >= 18 & TAGE <= 65 ~ "yes",
      TAGE >= 0 & TAGE <= 17 ~ "no",
      TAGE >= 66 & TAGE <= 100 ~ "no",
      TRUE ~ NA 
    ) # 18-65 ages
  ) %>%
  select("SHHADID", "SPANEL", "SSUID", "SWAVE", "PNUM", "MONTHCODE", "WPFINWGT",
         "TAGE", "EDUCATION", "SEX", "RACE", "METRO_STATUS",
         "EMPLOYMENT_TYPE", "CLASS_OF_WORKER",
         "TPTOTINC",
         "ANY_RETIREMENT_ACCESS",
         "PARTICIPATING",
         "MATCHING", "MONTHCODE", "TJB1_JOBHRS1", "TOTYEARINC",
         "IN_AGE_RANGE","FULL_PART_TIME", "TVAL_RET")


############################################################
# extract subset. relevant universe: 
    # 18-65 years old
    # Private employees
    # Full-time workers with non-zero hours worked per week
    # Non-zero income
############################################################


sipp_2023 = sipp_2023 %>%
  filter(IN_AGE_RANGE == "yes") %>%
  
  filter(EMPLOYMENT_TYPE == "Employer") %>%
  filter(CLASS_OF_WORKER ==  "Employee of a private, for-profit company" | 
           CLASS_OF_WORKER == "Employee of a private, not-for-profit company") %>%
  
  filter(FULL_PART_TIME == "full time") %>%
  
  filter(TPTOTINC >0)   %>% # earning an income 


  # extract subsetted variables for export
  select("SHHADID", "SPANEL", "SSUID", "SWAVE", "PNUM", "MONTHCODE", "WPFINWGT",
         "TAGE", "EDUCATION", "SEX", "RACE", "METRO_STATUS",
         "EMPLOYMENT_TYPE", "CLASS_OF_WORKER",
         "TPTOTINC",
         "ANY_RETIREMENT_ACCESS",
         "PARTICIPATING",
         "MATCHING", "MONTHCODE", "TJB1_JOBHRS1", "TOTYEARINC",
         "in_age_range","FULL_PART_TIME", "TVAL_RET")


# save file
setwd(path_output)

save(sipp_2023, file = "SIPP_2023_WRANGLED.RData")


  
  