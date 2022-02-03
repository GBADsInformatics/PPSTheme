################################################################
#
# Project: GBADS: Global Burden of Animal Disease
#
# Author: Gabriel Dennis 
# 
# Position: Research Technician, CSIRO
#
# Email: gabriel.dennis@csiro.au
#
# CSIRO ID: den173
#
# GitHub ID: denn173
#
# Date Created:  20220201  
# 
# Description:  This script returns values from the FAO global Aquaculture production 
# database
####################################


## 0 - Libraries  ------------------------------#
pkgs <- c('here', 'tidyr', 'readr', 'dplyr', 'magrittr', 'janitor')
sapply(pkgs, require, character.only = TRUE)

source(here('src', 'utils', 'FAOSTAT_helper_functions.R'))

## 1 - Parameters ------------------------------#
params <- list(
  data_dir  =  here('data', 'FAO_Global_Aquaculture_Production') , 
  value_file  =  "AQUACULTURE_VALUE.csv",
  quantity_file  =  "AQUACULTURE_QUANTITY.csv",
  cpc_group_en_file  =  "CL_FI_SPECIES_GROUPS.csv", 
  iso3_codes_files = "CL_FI_COUNTRY_GROUPS.csv", 
  use_years = 1994:2019, 
  exchange_rates_file = Sys.glob(here::here('data', 'FAOSTAT', '*Exchange_rate_E_All_Data.parquet'))
)


## number - Read in and Convert  ------------------------------#

aqua <- list()

# Read in Codes and Value Files
aqua$iso3codes <- readr::read_csv(file.path(params$data_dir, params$iso3_codes_files)) %>%
  janitor::clean_names()%>%
  select(un_code, iso3_code, name_en)

aqua$fisheries_values <- readr::read_csv(file.path(params$data_dir, params$value_file)) %>%
  clean_names() %>%
  filter(period  %in% params$use_years) %>%
  group_by(country_un_code, species_alpha_3_code, measure, period) %>%
  summarise(
    value_1000_usd = sum(value, na.rm = TRUE), .groups = "drop"
  ) %>% 
  unique()

aqua$fisheries_quantity <- readr::read_csv(file.path(params$data_dir, params$quantity_file)) %>%
  clean_names() %>%
  filter(period  %in% params$use_years) %>%
  group_by(country_un_code, species_alpha_3_code, measure, period) %>%
  summarise(
    tonnes = sum(value, na.rm = TRUE), .groups = "drop"
  ) %>% 
  unique()


#################################################################
# Get the USD price for every reported quantity
#
# Note: Can keep Hong Kong and Taiwan as they are not double counted.
#################################################################
fao_fisheries <- left_join(aqua$fisheries_quantity,
                           aqua$fisheries_values,
                           by = c("country_un_code", "species_alpha_3_code", "period")
) %>%
  mutate(usd_price = if_else(tonnes > 0, (value_1000_usd / tonnes) * 1000, 0)) %>%
  filter(usd_price > 0) %>%
  rename(un_code = country_un_code) %>%
  left_join(iso3codes_file, by = c("un_code")) %>%
  rename(species_code = species_alpha_3_code, year = period) %>%
  select(iso3_code, name_en, species_code, year, tonnes, value_1000_usd, usd_price) %>%
  ungroup()


# FAOSTAT exchange rates
aqua$fao_exchange_rates <- arrow::read_parquet(params$exchange_rates_file) %>%
  clean_names() %>%
  filter(year %in% params$use_years) %>%
  clean_countries() %>%
  rename(exchange_rate = value)

# Join by year and country
fao_fisheries <- fao_fisheries %>%
  left_join(aqua$fao_exchange_rates, by = c("iso3_code", "year")) %>%
  mutate(slc_price = usd_price / exchange_rate)


# Create mean prices
mean_fisheries_prices <- fao_fisheries %>%
  filter(year %in% 2014:2016) %>%
  group_by(iso3_code, species_code) %>%
  summarise(mean_slc_price = mean(slc_price, na.rm = TRUE), .groups = "drop")

mean_exchange_rates <- aqua$fao_exchange_rates %>%
  filter(year %in% 2014:2016) %>%
  group_by(iso3_code) %>%
  summarise(mean_exchange = mean(exchange_rate, na.rm = TRUE), .groups = "drop")

# Join back mean LCU prices and calculate constant values
fao_fisheries <- fao_fisheries %>%
  left_join(mean_fisheries_prices, by = c("iso3_code", "species_code")) %>%
  left_join(mean_exchange_rates, by = c("iso3_code")) %>%
  mutate(aquaculture_constant_2014_2016_usd_price = (mean_slc_price * mean_exchange)) %>%
  mutate(aquaculture_constant_2014_2016_constant_usd_value = tonnes * aquaculture_constant_2014_2016_usd_price)

