# Ben Glasner
# State of the American Worker Project
library(readxl)
library(tidyr)
library(dplyr)
library(mapview)
library(tigris)
library(tidycensus)
library(ranger)

#################
### Set paths ###
#################
# Define user-specific project directories
project_directories <- list(
  "bglasner" = "C:/Users/bglasner/EIG Dropbox/Benjamin Glasner/GitHub/transfer-income",
  "bngla" = "C:/Users/bngla/EIG Dropbox/Benjamin Glasner/GitHub/transfer-income",
  "Benjamin Glasner" = "C:/Users/Benjamin Glasner/EIG Dropbox/Benjamin Glasner/GitHub/transfer-income"
)

# Setting project path based on current user
current_user <- Sys.info()[["user"]]
if (!current_user %in% names(project_directories)) {
  stop("Root folder for current user is not defined.")
}
path_project <- project_directories[[current_user]]

# Define paths to data and output directories
path_data <- file.path(path_project, "Data")
path_output <- file.path(path_project, "output")

# Set working directory for CEPR data
setwd(path_data)

################################
# Load data cleaned by Daniel Newman
Transfers <- read_excel("transfers_dataset.xlsx", 
                                   sheet = "Transfers Long") %>%
  filter(year>=2009) %>%
  rename(GEOID = GeoFIPS)

################################
# load census data on elderly population
acs_var <- tidycensus::load_variables("acs5", year = 2022)
# B01001_001 Estimate!!Total:
# B01001_020:B01001_025 Estimate!!Total:!!Male:!!65+
# B01001_044:B01001_049 Estimate!!Total:!!Female:!!65 and 66 years

# B01002_001 Estimate!!Median age --!!Total:
ACS_list <- list()
yearlist <- c(2009:2022)
for(i in seq_along(yearlist)){
  ACS_list[[i]] <- get_acs(survey = "acs5",
                      geography = "county",
                      year = yearlist[[i]],
                      variables = c(Total = "B01001_001",Median_age = "B01002_001",
                                    men_65_66 = "B01001_020",
                                    men_67_69 = "B01001_021",
                                    men_70_74 = "B01001_022",
                                    men_75_79 = "B01001_023",
                                    men_80_84 = "B01001_024",
                                    men_85_over = "B01001_025",
                                    women_65_66 = "B01001_044",
                                    women_67_69 = "B01001_045",
                                    women_70_74 = "B01001_046",
                                    women_75_79 = "B01001_047",
                                    women_80_84 = "B01001_048",
                                    women_85_over = "B01001_049"),
                      geometry = FALSE)  %>% 
    pivot_wider(
      id_cols = c(GEOID, NAME),
      values_from = estimate,
      names_from = variable
    ) %>%
    mutate(men_65_over = men_65_66 + men_67_69 + men_70_74 + men_75_79 + men_80_84 + men_85_over,
           women_65_over = women_65_66 + women_67_69 + women_70_74 + women_75_79 + women_80_84 + women_85_over,
           share_65_over = ((men_65_over + women_65_over)/Total)*100,
           year = yearlist[[i]]) %>%
    select(GEOID,year,Total,men_65_over,women_65_over,share_65_over,Median_age)
}

ACS <- bind_rows(ACS_list)

################################
# link geographic information
county <- tigris::counties(year = 2022)
county <- county %>%
  mutate(FIPS = as.numeric(paste0(STATEFP,COUNTYFP)))

################################
# Merge ACS age info with transfer info
Transfers_ACS <- Transfers %>%
  inner_join(ACS)


################################
# Select relevant data for random forest prediction
Transfers_ACS <- Transfers_ACS  %>%
  mutate(ratio_transfers_govt_net_earnings = transfers_govt/net_earnings) %>% 
  select(year,GeoName,GEOID,
         population,
         men_65_over,women_65_over,share_65_over,Median_age,
         personal_income_pce_per_capita,
         net_earnings_pce_per_capita,
         dividends_interest_rent_pce_per_capita,
         transfers_govt_pce_per_capita,
         ratio_transfers_govt_net_earnings) %>%
  na.omit()


# Compare out of sample fit between RF and FEOLS models using 80/20 split
# RF parameters
n_trees = 500
# mtry_para = 3

# Fully remote
# RF model on training data
ratio_rf <- ranger(
  ratio_transfers_govt_net_earnings ~ share_65_over + Median_age + year, 
  data = Transfers_ACS, 
  # case.weights = "wtfinl",
  num.trees = n_trees,
  classification = FALSE,
  importance = 'permutation',
  scale.permutation.importance = TRUE,
  respect.unordered.factors=TRUE,
  write.forest = TRUE,
  verbose = TRUE)

predicted = predict(ratio_rf, data = Transfers_ACS)
Transfers_ACS$predicted <- predicted$predictions
Transfers_ACS$Excess <- Transfers_ACS$ratio_transfers_govt_net_earnings - Transfers_ACS$predicted

Transfers_ACS_2022 <- Transfers_ACS %>% filter(year == 2022)

##############################
county_2022 <- county %>% 
  left_join(Transfers_ACS_2022)


map_layer <- mapview(county_2022,
                     zcol = "Excess",
                     layer.name = "Excess",
                     # col.regions = colors,
                     # legend = legend_include,
                     map.types = "CartoDB.Positron",
                     alpha = 0.2) # Breaks for the colors
