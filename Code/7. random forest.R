
# last update: 02/12/2025 by Jason He

# Project: Retirement Update 2025; Urban versus Rural

# Description:
      # this file constructs non-parametric classifiers for
        # access to employer-based retirement savings plan(s)  = {0,1}
        # participation in employer-based retirement savings plan(s) = {0,1}
        # whether employer offers matching benefits for retirement savings plan(s) = {0,1}
      
      # non-parametric regression for
        # size of the retirement account savings


      # I use random forest for the following reasons:
          # RF does well with categorical & numerical data
          # handles non-linear relationships,
          # and is more robust than decision trees, manages noisy data, 
              # high-variance trees, missing data & outliers well.
          # we care about feature importance.
          
      # to generate standard deviations, I bootstrap the random forest estimates
      

# remove dependencies
rm(list = ls())

# load packages
library(dplyr)
library(tidyr)
library(readxl)
library(ranger)
library(ggplot2)
library(tibble)
library(scales)
library(openxlsx)

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


# set working directory for 2023 SIPP
setwd(output_path)


############################
# read in cleaned SIPP data
load("SIPP_2023_WRANGLED.RData")


# create subset with pretty names
sipp_2023_subset = sipp_2023 %>%
  
  # renaming
          rename(age = TAGE,
                 `account_value` = RETIREMENT_ACCT_VAL,
                 income = TPTOTINC) %>%
         
          
  # booleans for outcome variables
          mutate(access = case_when(
            ANY_RETIREMENT_ACCESS == "Yes" ~ 1,
            ANY_RETIREMENT_ACCESS == "No" ~ 0,
            ANY_RETIREMENT_ACCESS == "Missing" ~ NA
          ),
          
          matching = case_when(
            MATCHING == "Yes" ~ 1,
            MATCHING == "No" ~ 0,
            MATCHING == "Missing" ~ NA
          ),
          
          participates = case_when(
            PARTICIPATING == "Yes" ~ 1,
            PARTICIPATING == "No" ~ 0,
            PARTICIPATING == "Missing" ~ NA
          ),

  
  # categorical conversions (ordered and non-ordered)
    # industry is not ordered, employer size is
          
          education = case_when(
            EDUCATION == "High School or less" ~ 1,
            EDUCATION == "Some college" ~ 2,
            EDUCATION == "Bachelor's degree or higher" ~ 3,
            EDUCATION == "Missing" ~ NA
          ),
  
          industry = factor(INDUSTRY_BROAD, ordered = FALSE),
          
          employer_size = EJB1_EMPSIZE,
          
          metro_status = factor(case_when(
            METRO_STATUS == "Metropolitan area" ~ 1,
            METRO_STATUS == "Non-metropolitan area" ~ 0,
            TRUE ~ NA
          ), ordered = TRUE),
  
          YEAR_INC_QT = as.numeric(cut(TOTYEARINC, quantile(TOTYEARINC, 0:10/10), label = 1:10))
          ) %>%

  
  # select desired vars
  select(WPFINWGT,
         
         # outcome vars
         access, matching, participates, account_value,
         
         # regressors
         age, education, income, industry, metro_status, employer_size, YEAR_INC_QT,
         ) %>% 
  
  na.omit()
  


######################
# run random forest


# split train & test data; 80 / 20
    train_index <- sample(1:nrow(sipp_2023_subset), 0.8 * nrow(sipp_2023_subset))
    train_data <- sipp_2023_subset[train_index, ]
    test_data <- sipp_2023_subset[-train_index, ]
    

# set up bootstrap functions to get standard deviations
    # classifier and regresssion.

bootstrap_classification <-  function(model_formula, model_data, model_weights, num_repeats = 100, num_trees = 500) {
  
  results <- replicate(num_repeats, {
    rf <- ranger(model_formula, data = model_data, 
                 num.trees = num_trees, 
                 case.weights = model_weights,
                 classification = TRUE,
                 write.forest = TRUE,
                 importance = 'permutation',
                 respect.unordered.factors = TRUE,
                 scale.permutation.importance = TRUE)
    
    rf$variable.importance
  }, simplify = "array")
  
  # Compute mean and standard deviation across repeats
  importance_summary <- apply(results, 1, function(x) c(importance = mean(x), sd = sd(x)))
  importance_df <- data.frame(importance_summary)
  
  importance_df =
    rownames_to_column(importance_df, var = "stat") %>%
    
    pivot_longer(cols = names(importance_df),
                 names_to = "variable") %>%
    pivot_wider(names_from = "stat",
                values_from = "value")
  
  return(importance_df)
}



bootstrap_regression <-  function(model_formula, model_data, model_weights, num_repeats = 100, num_trees = 500) {
  
  results <- replicate(num_repeats, {
    rf <- ranger(model_formula, data = model_data, 
                 num.trees = num_trees, 
                 case.weights = model_weights,
                 classification = FALSE,
                 write.forest = TRUE,
                 importance = 'permutation',
                 respect.unordered.factors = TRUE,
                 scale.permutation.importance = TRUE)
    
    rf$variable.importance
  }, simplify = "array")
  
  # Compute mean and standard deviation across repeats
  importance_summary <- apply(results, 1, function(x) c(importance = mean(x), sd = sd(x)))
  importance_df <- data.frame(importance_summary)
  
  importance_df =
      rownames_to_column(importance_df, var = "stat") %>%
        
        pivot_longer(cols = names(importance_df),
                     names_to = "variable") %>%
        pivot_wider(names_from = "stat",
                    values_from = "value")
  
  return(importance_df)
}


######################
# construct estimates

set.seed(42)  # For reproducibility


  access_results <- bootstrap_classification(
    model_formula =  access ~ age + industry + income + education + metro_status + employer_size,
    model_data = train_data,
    model_weights = train_data$WPFINWGT)


  matching_results <- bootstrap_classification(
    model_formula =  matching ~ age + industry + income + education + metro_status + employer_size,
    model_data = train_data,
    model_weights = train_data$WPFINWGT)

  
  participation_results = bootstrap_classification(
    model_formula =  participates ~ age + industry + income + education + metro_status + employer_size,
    model_data = train_data,
    model_weights = train_data$WPFINWGT)

  account_value_results = bootstrap_regression(
    model_formula =  account_value ~ age + industry + income + education + metro_status + employer_size,
    model_data = train_data,
    model_weights = train_data$WPFINWGT)

  
  # display for visual checking
  account_value_results

  
  
###########################################################
# standardize coefficients. many options; using proportions
  
      access_results = access_results %>%
        mutate(importance_scaled = 100*importance/sum(importance))
      
      matching_results = matching_results %>%
        mutate(importance_scaled = 100*importance/sum(importance))
      
      participation_results = participation_results %>%
        mutate(importance_scaled = 100*importance/sum(importance))
      
      account_value_results = account_value_results %>%
        mutate(importance_scaled = 100*importance/sum(importance))
      
# consider adding R^2 values.      
# r2_value <- 1 - (sum((test_data$account_value - predict)^2) / sum((test_data$account_value - mean(test_data$account_value))^2))

      
###########################################################
# generate prediction matrix for different characteristics
      
# find the representative agent within the data set
rep_agent <- sipp_2023_subset %>% select(age, education, income, employer_size) %>%
  summarise_all(., median) %>%
  mutate(industry = sipp_2023_subset %>% count(industry) %>% filter(n == max(n)) %>% .$industry %>% as.character(),
         metro_status = 1) %>%
  mutate(age = as.numeric(age), income = as.numeric(income))
rep_agent

# the representative respondent to SIPP is 42-year-old (median age), has some college education (median education),
# earns the median income of the data set, works for a company with 51 to 100 employees in the Educational Services,
# and Health Care and Social Assistance industry, and resides in a metro area. Think of a middle-class, middle-aged
# healthcare professional holding a nursing or technician degree and working for a small urban hospital.

# extract the industries with the best and worst access
access_ranked_industries <- read.csv(file.path(output_path, "retirement_by_industry.csv"))
minmax.industries <- c(access_ranked_industries %>% filter(SHARE_RETIREMENT_ACCESS == min(SHARE_RETIREMENT_ACCESS)) %>% .$INDUSTRY_BROAD,
  access_ranked_industries %>% filter(SHARE_RETIREMENT_ACCESS == max(SHARE_RETIREMENT_ACCESS)) %>% .$INDUSTRY_BROAD)

##### Alternative representation with more permutations ####
# # permute by minimum and maximum values of age, education, employer size, income, and industry by retirement
# # access; then duplicate the predictions for rural
# permute_agents <- bind_rows(
#   rep_agent %>% mutate(age = replace(age, 1, list(c(rep_agent$age, (18+30)/2, (55+65)/2)))) %>% unnest_longer(age),
#   rep_agent %>% mutate(education = replace(education, 1, list(c(sipp_2023_subset %>% select(education) %>% min(),
#                                                                 sipp_2023_subset %>% select(education) %>% max())))) %>%
#     unnest_longer(education),
#   rep_agent %>% mutate(employer_size = replace(employer_size, 1, list(c(sipp_2023_subset %>% select(employer_size) %>% min(),
#                                                                         sipp_2023_subset %>% select(employer_size) %>% max())))) %>%
#     unnest_longer(employer_size),
#   rep_agent %>% mutate(income = replace(income, 1, list(c(median(sipp_2023_subset %>% filter(YEAR_INC_QT == min(YEAR_INC_QT)) %>% .$income),
#                                  median(sipp_2023_subset %>% filter(YEAR_INC_QT == max(YEAR_INC_QT)) %>% .$income))))) %>%
#     unnest_longer(income),
#   rep_agent %>% mutate(industry = replace(industry, 1, list(minmax.industries))) %>%
#     unnest_longer(industry)
# ) %>% mutate(metro_status = replace(metro_status, which(metro_status == 1),
#                                     list(c(1, 0)))) %>% unnest_longer(metro_status)

# run random forest model 100 times to generate average prediction
bootstrap_prediction <- function(model_formula, model_data, model_weights,
                                 predict_data, num_repeats = 100, num_trees = 500){
  results <- data.frame(matrix(ncol = nrow(predict_data), nrow = 0))
  for(i in 1:num_repeats){
    rf <- ranger(model_formula, data = model_data, 
                 num.trees = num_trees, 
                 case.weights = model_weights,
                 classification = FALSE,
                 write.forest = TRUE,
                 importance = 'permutation',
                 respect.unordered.factors = TRUE,
                 scale.permutation.importance = TRUE)
    results <- rbind(results, predict(rf, data = predict_data)$predictions)
  }
  results %>% summarise_all(., mean)
}
# 
# set.seed(42) # for reproducibility
# 
# # generate probability array and convert to matrix 
# prob.array <- bootstrap_prediction(model_formula = access ~ age + industry + income + education + metro_status + employer_size,
#                                    model_data = sipp_2023_subset,
#                                    model_weights = sipp_2023_subset$WPFINWGT,
#                                    predict_data = permute_agents)

treatment_labels <- c("age 24",
                     "age 60",
                     "high school or less",
                     "bachelors or above",
                     "lowest income decile",
                     "highest income decile",
                     "<= 10 workers",
                     ">= 1000 workers",
                     "worst access industry",
                     "best access industry")

# prob.matrix <- (as.data.frame(split(as.numeric(prob.array[1,]), 1:2)) %>%
#                   rename(urban = X1, rural = X2)) %>%
#   mutate(urban = percent(urban + (urban == 0)*prob.array[1,1], accuracy = 0.01),
#          rural = percent(rural, accuracy = 0.01)) %>%
#   mutate(labels = c("representative agent", treatment_labels)) %>% relocate(labels) %>%
#   mutate_all(~unlist(.))

# Final prediction matrix, upper triangular representation
# Function generating each row in the permutations
create_permutation <- function(base){
  bind_rows(
    base %>% mutate(metro_status = replace(metro_status, 1,
                                                list(c(1, 0)))) %>% unnest_longer(metro_status),
    base %>% mutate(age = replace(age, 1, list(c((18+30)/2, (55+65)/2)))) %>% unnest_longer(age),
    base %>% mutate(education = replace(education, 1, list(c(sipp_2023_subset %>% select(education) %>% min(),
                                                                  sipp_2023_subset %>% select(education) %>% max())))) %>%
      unnest_longer(education),
    base %>% mutate(income = replace(income, 1, list(c(median(sipp_2023_subset %>% filter(YEAR_INC_QT == min(YEAR_INC_QT)) %>% .$income),
                                                       median(sipp_2023_subset %>% filter(YEAR_INC_QT == max(YEAR_INC_QT)) %>% .$income))))) %>%
      unnest_longer(income),
    base %>% mutate(employer_size = replace(employer_size, 1, list(c(sipp_2023_subset %>% select(employer_size) %>% min(),
                                                                          sipp_2023_subset %>% select(employer_size) %>% max())))) %>%
      unnest_longer(employer_size),
    base %>% mutate(industry = replace(industry, 1, list(minmax.industries))) %>%
      unnest_longer(industry)
  )
}

# Corresponding to first row in the output matrix, each row is used to generate a column
first_row <- create_permutation(rep_agent)
permute_agents_matrix <- first_row
for(i in 2:nrow(first_row)){
  permute_agents_matrix <- rbind(permute_agents_matrix, create_permutation(first_row[i,]))
}

set.seed(42) # for reproducibility

# convert probability array to matrix 
prob.array.matform <- bootstrap_prediction(model_formula = access ~ age + industry + income + education + metro_status + employer_size,
                                           model_data = sipp_2023_subset,
                                           model_weights = sipp_2023_subset$WPFINWGT,
                                           predict_data = permute_agents_matrix)
prob.matform <- matrix(prob.array.matform*100, nrow = nrow(first_row), ncol = nrow(first_row))
prob.matform[lower.tri(prob.matform, diag = TRUE)] <- 0
excl_v <- seq(from = 4, to = nrow(first_row), by = 2)
prob.matform[cbind(excl_v - 1, excl_v)] <- 0
prob.matform[1,1] <- prob.array.matform[1]*100
prob.matform[1,2] <- prob.array.matform[2]*100
prob.matform <- as.data.frame(prob.matform[c(-11,-12),])
prob.matform <- prob.matform %>% rename_with(~c("representative agent", "rural",
                                                treatment_labels)) %>%
  mutate(labels = c("representative agent", "rural",
                    treatment_labels[1:(length(treatment_labels)-2)])) %>%
  mutate_all(~unlist(.))

############################################
# export bootstrapped random forest results
      
setwd(output_path)
      
    write.csv(access_results, "rf_access.csv")
    write.csv(matching_results, "rf_matching.csv")
    write.csv(participation_results, "rf_participation.csv")
    write.csv(account_value_results, "rf_account_value.csv")
#    write.csv(prob.matrix, "rf_prediction_matrix_alternative.csv")
    write.xlsx(prob.matform, "rf_prediction_matrix.xlsx")
    
  # combine results for datawrapper display.
      access_datawr = access_results %>% select(variable, importance_scaled) %>%
        mutate(category = "Access to an employer based retirement plan")

      matching_datawr = matching_results %>% select(variable, importance_scaled) %>%
        mutate(category = "Employer provides matching benefits")
      
      participation_datawr = participation_results %>% select(variable, importance_scaled) %>%
        mutate(category = "Participates in employer baesd retirement plan")
      
      account_datawr = account_value_results %>% select(variable, importance_scaled) %>%
        mutate(category = "Retirement account value")

# combine
    datawrapper = bind_rows(access_datawr,
                            participation_datawr,
                            matching_datawr,
                            account_datawr) %>%
      
      mutate(variable = case_when(
        variable == "employer_size" ~ "employer size",
        variable == "metro_status" ~ "metro status",
        TRUE ~ variable
      ))
      
      
      write.csv(datawrapper, "rf_datawrapper_friendly.csv")
      