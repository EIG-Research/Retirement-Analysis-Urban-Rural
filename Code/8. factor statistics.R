
# last updated: 02/06/2025 by Sarah Eckhardt

# Project: Retirement Update 2025; Urban versus Rural

# Description:
  # generate statistics cited in the important factors section of the blog post.


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
output_path = file.path(project_path, "Output")


setwd(output_path)

load("SIPP_2023_WRANGLED.RData")


###########################
# topline bullet points:
###########################

##############
# age stats
      sipp_2023 = sipp_2023 %>%
        
        # generate age groups
        mutate(AGE_GROUP = case_when(
          TAGE >=18 & TAGE <30 ~ "early career",  # 18 - 29
          TAGE >=30 & TAGE < 55 ~ "mid career",   # 30 - 54
          TAGE >=55 ~ "late career"               # 55 - 65 
        ))
        
      
  # access
      print("Access by age group of worker")
      
      sipp_2023 %>%
        filter(ANY_RETIREMENT_ACCESS != "Missing") %>%
        ungroup() %>%
        group_by(AGE_GROUP, ANY_RETIREMENT_ACCESS) %>%
        summarise(count = sum(WPFINWGT)) %>%
        
        ungroup() %>% group_by(AGE_GROUP) %>%
        mutate(share = count/sum(count)) %>% select(-c(count)) %>%
        pivot_wider(names_from = ANY_RETIREMENT_ACCESS,
                    values_from = share)
  
  # matching    
      print("Matching by age group of worker")
      
      sipp_2023 %>%
        filter(MATCHING != "Missing") %>%
        ungroup() %>%
        group_by(AGE_GROUP, MATCHING) %>%
        summarise(count = sum(WPFINWGT)) %>%
        
        ungroup() %>% group_by(AGE_GROUP) %>%
        mutate(share = count/sum(count)) %>% select(-c(count)) %>%
        pivot_wider(names_from = MATCHING,
                    values_from = share)


      
############
# education

      # % of people with matching and access and participation by education group..

      sipp_2023 %>%
        filter(ANY_RETIREMENT_ACCESS != "Missing") %>%
        group_by(ANY_RETIREMENT_ACCESS, EDUCATION) %>%
        summarise(count = sum(WPFINWGT)) %>%
        
        ungroup() %>% group_by(EDUCATION) %>%
        mutate(share = count/sum(count)) %>% select(-c(count)) %>%
        pivot_wider(names_from = ANY_RETIREMENT_ACCESS,
                    values_from = share)
      
      sipp_2023 %>%
        filter(MATCHING != "Missing") %>%
        group_by(MATCHING, EDUCATION) %>%
        summarise(count = sum(WPFINWGT)) %>%
        
        ungroup() %>% group_by(EDUCATION) %>%
        mutate(share = count/sum(count)) %>% select(-c(count)) %>%
        pivot_wider(names_from = MATCHING,
                    values_from = share)
      
###########
# industry

# need to generate that chart....
      
      sipp_2023 %>%
        filter(ANY_RETIREMENT_ACCESS != "Missing") %>%
        
        ungroup() %>%
        group_by(ANY_RETIREMENT_ACCESS, INDUSTRY_BROAD) %>%
        
        summarise(count = sum(WPFINWGT, na.rm = TRUE)) %>%
        ungroup() %>% group_by(INDUSTRY_BROAD) %>%
        mutate(Share = 100*count / sum(count)) %>%
        select(-c(count)) %>% pivot_wider(names_from = ANY_RETIREMENT_ACCESS,
                                          values_from = Share) %>%
        
        # sort descending by % with access.
        arrange(desc(Yes))
      
      
      sipp_2023 %>%
        filter(MATCHING != "Missing") %>%
        
        ungroup() %>%
        group_by(MATCHING, INDUSTRY_BROAD) %>%
        
        summarise(count = sum(WPFINWGT, na.rm = TRUE)) %>%
        ungroup() %>% group_by(INDUSTRY_BROAD) %>%
        mutate(Share = 100*count / sum(count)) %>%
        select(-c(count)) %>% pivot_wider(names_from = MATCHING,
                                          values_from = Share) %>%
        
        # sort descending by % with access.
        arrange(desc(Yes))
      
      
###############
# employer size

      # access
      sipp_2023 %>%
        filter(ANY_RETIREMENT_ACCESS != "Missing") %>%
        
        ungroup() %>%
        group_by(ANY_RETIREMENT_ACCESS, EMPLOYER_SIZE) %>%
        
        summarise(count = sum(WPFINWGT, na.rm = TRUE)) %>%
        ungroup() %>% group_by(EMPLOYER_SIZE) %>%
        mutate(Share = 100*count / sum(count)) %>%
        select(-c(count)) %>% pivot_wider(names_from = ANY_RETIREMENT_ACCESS,
                                            values_from = Share)
      
      # match
      sipp_2023 %>%
        filter(MATCHING != "Missing") %>%
        
        ungroup() %>%
        group_by(MATCHING, EMPLOYER_SIZE) %>%
        
        summarise(count = sum(WPFINWGT, na.rm = TRUE)) %>%
        ungroup() %>% group_by(EMPLOYER_SIZE) %>%
        mutate(Share = 100*count / sum(count)) %>%
        select(-c(count)) %>% pivot_wider(names_from = MATCHING,
                                         values_from = Share)
      
      
      
      
#######################################      
# rural versus urban discrepancy table
      
    # median income urban vs. rural
    # using median; long right tail.

    median_income = sipp_2023 %>%
            ungroup() %>%
            filter(!is.na(METRO_STATUS)) %>% filter(METRO_STATUS != "Not identified") %>%
            group_by(METRO_STATUS) %>%
              summarise(`Median income` = Hmisc::wtd.quantile(TOTYEARINC, WPFINWGT, probs = 0.5))
   
      
    # education   
    edu =   sipp_2023 %>%
        ungroup() %>%
        filter(!is.na(METRO_STATUS)) %>% filter(METRO_STATUS != "Not identified") %>%
        group_by(METRO_STATUS, EDUCATION) %>%
        summarise(count = sum(WPFINWGT)) %>%
        
        ungroup() %>% group_by(METRO_STATUS) %>%
        mutate(share = 100*count/sum(count)) %>%
        select(-c(count)) %>%
        pivot_wider(names_from = EDUCATION, 
                    values_from = share) %>%
      rename(`% with HS or less` = `High School or less`) %>%
      select(-c(`Some college`, `Bachelor's degree or higher`))
      

    
      # age (on our restricted sample)
      age = sipp_2023 %>%
        ungroup() %>%
        filter(!is.na(METRO_STATUS)) %>% filter(METRO_STATUS != "Not identified") %>%
        group_by(METRO_STATUS) %>%
        summarise(`Mean age*` = weighted.mean(TAGE, weight = WPFINGWT))
      
      
      
    # low access. what should this be?
   low_access_list =  sipp_2023 %>%
      ungroup() %>%
      group_by(INDUSTRY_BROAD, ANY_RETIREMENT_ACCESS) %>%
      
      filter(ANY_RETIREMENT_ACCESS!= "Missing") %>%
      
      summarise(count = sum(WPFINWGT)) %>%
      ungroup() %>%
      group_by(INDUSTRY_BROAD) %>%
      mutate(share = count/sum(count)) %>%
      filter(ANY_RETIREMENT_ACCESS =="Yes") %>%
      select(-c(count, ANY_RETIREMENT_ACCESS)) %>%
      arrange(desc(share)) %>%
      
      # define low-access to be the 70th percentile 
      filter(share < .45)
    
   low_access_list = low_access_list$INDUSTRY_BROAD
    
          
      low_access = sipp_2023 %>%
        mutate(low_access_industry = case_when(
          INDUSTRY_BROAD %in% low_access_list ~ "low access",
          TRUE~ "not low access"
        )) %>%
        filter(METRO_STATUS != "Not identified") %>%
        ungroup() %>%
        group_by(METRO_STATUS, low_access_industry) %>%
        summarise(count = sum(WPFINWGT)) %>%
        ungroup() %>% group_by(METRO_STATUS) %>%
        mutate(share = 100*count/sum(count)) %>%
        filter(low_access_industry == "low access") %>%
        select(-c(count, low_access_industry)) %>%
        rename(`% in a low-access industry` = share)
        
    
    # large employers

      large_employer = sipp_2023 %>%
        filter(METRO_STATUS != "Not identified") %>%
        ungroup() %>%
        group_by(METRO_STATUS, EMPLOYER_SIZE) %>%
        summarise(count = sum(WPFINWGT)) %>%
        ungroup() %>%
        group_by(METRO_STATUS) %>%
        mutate(share = 100*count/sum(count)) %>%
        filter(EMPLOYER_SIZE == "> 1,000") %>%
        rename(`% at a company with >1,000 employees` = share) %>%
        select(-c(EMPLOYER_SIZE, count))
        

   stats = median_income %>% left_join(edu)  %>% left_join(age) %>% left_join(low_access) %>% left_join(large_employer)

   setwd(output_path)
    write.csv(stats, "summary_stats_urban_rural_discrepancies.csv")