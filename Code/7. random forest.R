
# last update: 02/06/2025 by Sarah Eckhardt

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
    # industry is not ordered
    # education and employer size are
          
          education = factor(EEDUC, ordered = TRUE),
          industry = factor(INDUSTRY_BROAD, ordered = FALSE),
          
          employer_size = factor(EJB1_EMPSIZE, ordered = TRUE),
          
          metro_status = factor(case_when(
            METRO_STATUS == "Metropolitan area" ~ 1,
            METRO_STATUS == "Non-metropolitan area" ~ 0,
            TRUE ~ NA
          ), ordered = TRUE)) %>%

  
  # select desired vars
  select(WPFINWGT,
         
         # outcome vars
         access, matching, participates, account_value,
         
         # regressors
         age, education, income, industry, metro_status, employer_size
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


############################################
# export bootstrapped random forest results
      
setwd(output_path)
      
    write.csv(access_results, "rf_access.csv")
    write.csv(matching_results, "rf_matching.csv")
    write.csv(participation_results, "rf_participation.csv")
    write.csv(account_value_results, "rf_account_value.csv")

    
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
      