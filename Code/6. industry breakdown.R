# last update: 02/05/2025 by Jason He

# Project: Retirement Update 2025; Urban versus Rural

# File Description: read in cleaned SIPP 2023 data to find industry-level differences in
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

# load in list of industries that passed robustness checks
load(file.path(output_path, "industry_robust.RData"))

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
# summmarise with respect to firm industries, keeping those that passed robust checks
ret_sipp_industry <- sipp_2023_metro %>% filter(INDUSTRY_BROAD %in% incl) %>%
  
  # group by industries and metro/non-metro
  drop_na(INDUSTRY_BROAD) %>% group_by(INDUSTRY_BROAD) %>%
  
  # calculate the four retirement-related statistics for each industry in urban/rural
  summarise(across(ret_features_weighted, ~ sum(.x)/sum(WPFINWGT))) %>%
  
  # calculate size of each industry group
  left_join(sipp_2023_metro %>% count(INDUSTRY_BROAD)) %>%
  
  # arrange by industry, fix industry names, and rename columns
  arrange(desc(INDUSTRY_BROAD)) %>%
  mutate(INDUSTRY_BROAD = replace(INDUSTRY_BROAD,
                                  INDUSTRY_BROAD == "and Waste Management Services",
                                  "Waste Management Services")) %>%
  rename(AVG_ACCOUNT_SIZE = weighted_TVAL_RET,
         SHARE_RETIREMENT_ACCESS = weighted_ANY_RETIREMENT_ACCESS,
         SHARE_MATCHING = weighted_MATCHING,
         SHARE_PARTICIPATION = weighted_PARTICIPATING,
         SAMPLE_SIZE = n)

# Plot share of workers with retirement plan access by industry
access_plot <- ggplot(ret_sipp_industry, aes(x = INDUSTRY_BROAD,
                                             y = SHARE_RETIREMENT_ACCESS)) +
  geom_bar(stat = "identity", position = position_dodge(), alpha = 0.75) +
  scale_y_continuous(limits = c(0,1), labels = scales::percent) +
  labs(title = "Retirement Account Access by Industry",
       y = "Share of Workers (%)",
       x = "Industry") +
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle=45, vjust=1, hjust=1))

# Plot share of employers offering matching retirement plans by industry
matching_plot <- ggplot(ret_sipp_industry, aes(x = INDUSTRY_BROAD,
                                               y = SHARE_MATCHING)) +
  geom_bar(stat = "identity", position = position_dodge(), alpha = 0.75) +
  scale_y_continuous(limits = c(0,1), labels = scales::percent) +
  labs(title = "Employer Matching Retirement Plans by Industry",
       y = "Share of Employers (%)",
       x = "Industry") +
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle=45, vjust=1, hjust=1))

# Plot employee participation rates in retirement plans by industry
participation_plot <- ggplot(ret_sipp_industry, aes(x = INDUSTRY_BROAD,
                                                    y = SHARE_PARTICIPATION)) +
  geom_bar(stat = "identity", position = position_dodge(), alpha = 0.75) +
  scale_y_continuous(limits = c(0,1), labels = scales::percent) +
  labs(title = "Participation in Retirement Plans by Industry",
       y = "Share of Workers (%)",
       x = "Industry") +
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle=45, vjust=1, hjust=1))


# save output
setwd(output_path)
write.csv(ret_sipp_industry[,-2], "urban_rural_ret_education.csv", row.names = FALSE)

# export graphs
access_plot
ggsave("retirement_access_plot.png")

matching_plot
ggsave("matching_plan_plot.png")

participation_plot
ggsave("plan_participation_plot.png")
