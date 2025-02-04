
# last update: 02/04/2025 by Sarah Eckhardt

# Project: Retirement Update 2025; Urban versus Rural

# File Description: explore how firm size interacts with urban/rural.
    # larger firms have more resources, theoretically can offer retirement plans
    # with greater ease than smaller firms. Is employment in larger firms concentrated
    # in urban places?

# The median firm in an urban area has XXX employees. The median firm in a 
# rural area has YYY employees. Firms’ participation, access, matching by size.

# EJB1_EMPSIZE About how many people are employed by ... at the location where ... works?



# remove dependencies
rm(list = ls())

# load packages
library(dplyr)
library(tidyr)
library(ggplot2)

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


# set project path for data load and export.
setwd(output_path)


##############
# load data
load("SIPP_2023_WRANGLED.RData")



###################################
# 1. urban vs rural employer size.

empl_size = sipp_2023 %>%
  filter(METRO_STATUS != "Not identified" & !is.na(METRO_STATUS)) %>%

  ungroup() %>%
  group_by(METRO_STATUS, EMPLOYER_SIZE) %>%
  
  summarise(count = sum(WPFINWGT, na.rm = TRUE)) %>%
  ungroup() %>% group_by(METRO_STATUS) %>%
  mutate(Share = 100*count / sum(count))


# graph
empl_size %>% 
  mutate(EMPLOYER_SIZE = factor(EMPLOYER_SIZE,
          levels = c(
                  "< 10",
                  "10 - 25",
                  "26 - 50",
                  "51 - 100",
                  "101 - 200",
                  "201 - 500",
                  "501 - 1,000",
                  "> 1,000"
                  ))) %>%
  
  ggplot(aes(x = interaction(EMPLOYER_SIZE),
                         y = Share, fill = as.factor(METRO_STATUS))) +
           geom_bar(stat = "identity", 
                    position = position_dodge(), color = "black") +
           theme_minimal() +
  labs(title = "Employer size by metro area",
       x = "Employer size",
       y = "% of respondents") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  scale_fill_discrete(name = "Metro status")


# save; reshape to be data-wrapper friendly.
empl_size = empl_size %>%
  pivot_wider(names_from = EMPLOYER_SIZE,
              values_from = Share)

  write.csv(empl_size, "employment_by_employer_size_and_metro_status.csv")

  
  
#################################################################
# (2) Access to retirement savings through employer by firm size
  access_empl_size = sipp_2023 %>%
    filter(ANY_RETIREMENT_ACCESS != "Missing") %>%
    
    ungroup() %>%
    group_by(ANY_RETIREMENT_ACCESS, EMPLOYER_SIZE) %>%
    
    summarise(count = sum(WPFINWGT, na.rm = TRUE)) %>%
    ungroup() %>% group_by(EMPLOYER_SIZE) %>%
    mutate(Share = 100*count / sum(count)) %>%
    select(-c(count))

  # graphing...
  access_empl_size %>%
    mutate(EMPLOYER_SIZE = factor(EMPLOYER_SIZE,
          levels = c(
            "< 10",
            "10 - 25",
            "26 - 50",
            "51 - 100",
            "101 - 200",
            "201 - 500",
            "501 - 1,000",
            "> 1,000"
          ))) %>%
  ggplot(aes(x = EMPLOYER_SIZE,
             y = Share, fill = as.factor(ANY_RETIREMENT_ACCESS))) +
    geom_bar(stat = "identity", position = position_dodge(), color = "black") +
    theme_minimal() +
    labs(title = "Employer size by metro area",
         x = "Employer size",
         y = "Access to employer-based retirement") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    scale_fill_discrete(name = "Access")
  
  
  # save; reshape to be data-wrapper friendly.
  access_empl_size = access_empl_size %>%
    pivot_wider(names_from = EMPLOYER_SIZE,
                values_from = Share)
  
  write.csv(access_empl_size, "access_by_employer_size.csv")
  
    