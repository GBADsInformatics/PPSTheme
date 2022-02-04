####################################
# Creator: Gabriel Dennis
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited:2021-11-80
#
# File Description: This script calculates scenario O1
# from FAO data and produces outputs in constant 2014-2016 US dollars.
####################################

# https://datahelpdesk.worldbank.org/knowledgebase/articles/114968-how-do-you-derive-your-constant-price-series-for-t




## 0 - Libraries ------------------------------#
library(tidyverse, quietly = TRUE, warn.conflicts = FALSE)

# Source functions (Move into this script)
source(here::here("src", "utils", "FAOSTAT_helper_functions.R"))
source(here::here("src", "utils", "functions.R"))

# Renaming function
renamer <- function(df) {
  dplyr::rename_with(df, ~ tolower(gsub(" ", "_", .x)))
}


# Constants
cutoff_year <- 1992

## 1 - Data ------------------------------#


# FAOSTAT Value of Production Data in constant 2014-2016 US dollars


animal_sector <- function(df) {
  df %>%
    separate(item, c("sector", "animal"), sep = ", ", extra = "merge") %>%
    mutate(
      sector = trimws(str_remove_all(sector, "indigenous")),
      animal = trimws(str_remove_all(animal, "whole fresh"))
    ) %>%
    filter(sector != "Wool") %>%
    mutate(
      animal = plyr::mapvalues(
        animal, c("hen, in shell", "other bird, in shell"),
        c("chicken", "bird")
      )
    )
}

constant_usd_element <- 58
fao_vop <- arrow::read_parquet(get_gbads_file("Value_of_Production_E_All_Data_(Normalized).parquet")) %>%
  renamer() %>%
  filter(year > cutoff_year, element_code == constant_usd_element) %>%
  add_country_codes(area_code, area) %>%
  select_fao_items(item_code, "vop_items") %>%
  animal_sector() %>%
  mutate(constant_usd_value = value * 1000) %>%
  select(iso3_code, country, animal, sector, year, constant_usd_value)




# FAO Fisheries data
#  Calculate the per tonne value - Then backcalculate to 2014-2016 prices

fao_fisheries_folder <- here::here("data", "raw", "20210716_FAO_Global_Aquaculture_Production")
value_file <- "AQUACULTURE_VALUE.csv"
quantity_file <- "AQUACULTURE_QUANTITY.csv"

iso3codes_file <- readr::read_csv(here::here(fao_fisheries_folder, "CL_FI_COUNTRY_GROUPS.csv")) %>%
  renamer() %>%
  select(un_code, iso3_code, name_en)

CPC_Group_En_file <- "CL_FI_SPECIES_GROUPS.csv"


fao_fisheries_values <- readr::read_csv(here::here(fao_fisheries_folder, value_file)) %>%
  renamer() %>%
  filter(period >= cutoff_year)

fao_fisheries_quantity <- readr::read_csv(here::here(fao_fisheries_folder, quantity_file)) %>%
  renamer() %>%
  filter(period >= cutoff_year) %>%
  rename(tonnes = value)



fao_fisheries <- left_join(fao_fisheries_quantity,
  fao_fisheries_values,
  by = c("country.un_code", "species.alpha_3_code", "period")
) %>%
  mutate(usd_price = if_else(tonnes > 0, (value / tonnes) * 1000, 0)) %>%
  filter(usd_price > 0) %>%
  rename(un_code = country.un_code) %>%
  left_join(iso3codes_file, by = c("un_code")) %>%
  rename(species_code = species.alpha_3_code, year = period) %>%
  select(iso3_code, name_en, species_code, year, tonnes, usd_price) %>%
  drop_na(usd_price) # Price is per tonne

#  Convert prices back into local currency to create an index using the 2014-2015 price

# FAOSTAT exchange rates
fao_exchange_rates <- arrow::read_parquet(get_gbads_file("Exchange_rate_E_All_Data_(Normalized).parquet")) %>%
  renamer() %>%
  add_country_codes(area_code, area)


# Join by year and country
fao_fisheries <- fao_fisheries %>%
  left_join(fao_exchange_rates, by = c("iso3_code", "year")) %>%
  mutate(lcu_price = usd_price * value)


# Create mean prices
mean_fisheries_prices <- fao_fisheries %>%
  filter(year %in% 2014:2016) %>%
  group_by(iso3_code, country, species_code) %>%
  summarise(mean_lcu_price = mean(lcu_price, na.rm = TRUE), .groups = "drop")

mean_exchange_rates <- fao_exchange_rates %>%
  filter(year %in% 2015:2016) %>%
  group_by(iso3_code, country) %>%
  summarise(mean_exchange = mean(value, na.rm = TRUE), .groups = "drop")

# Join back mean LCU prices and calculate constant values
fao_fisheries <- fao_fisheries %>%
  left_join(mean_fisheries_prices, by = c("iso3_code", "country", "species_code")) %>%
  left_join(mean_exchange_rates, by = c("iso3_code", "country")) %>%
  mutate(constant_usd_price = (lcu_price / mean_lcu_price) * (mean_lcu_price / mean_exchange)) %>%
  mutate(constant_usd_value = tonnes * constant_usd_price) %>%
  select(iso3_code, country, year, species_code, constant_usd_value)


###############################################################################
###############################################################################
# The exchange rates for Venezuala appear incorrect, remove
# from data
############################################################################
fao_fisheries <- fao_fisheries %>% filter(!((iso3_code == "VEN")))
# --------------------------------------------------------

# Join and calculate O1
o1 <- fao_fisheries %>%
  mutate(
    sector = "aquaculture",
    animal = species_code
  ) %>%
  select(iso3_code, country, year, sector, animal, constant_usd_value) %>%
  bind_rows(fao_vop)


arrow::write_parquet(o1, here::here("data", "output", "O1_Value_of_Direct_Outputs_Constant-2004-2016-USD.parquet"))

ggplot(o1 %>% filter(year < 2020) %>% group_by(year) %>% summarise(value = sum(constant_usd_value, na.rm = TRUE)), aes(year, value)) +
  geom_point() +
  scale_y_continuous(labels = scales::dollar_format())

############################################################################
clean_global_aquaculture_data <- function() {
  # TODO:FIX THIS
  ## 0 - Load the Libraries
  library(dplyr)
  library(magrittr)
  library(tidyr)
  library(stringr)



  ## 1 - Import the data
  data_folder <- file.path(
    "data", "raw", "20210716_FAO_Global_Aquaculture_Production" # Change to latest file
  )

  # Files to use
  data_file <- "AQUACULTURE_VALUE.csv"
  iso3codes_file <- "CL_FI_COUNTRY_GROUPS.csv"
  CPC_Group_En_file <- "CL_FI_SPECIES_GROUPS.csv"

  # Production data
  aqua_production_df <- readr::read_csv(
    file.path(data_folder, data_file),
    col_select = c("COUNTRY.UN_CODE", "SPECIES.ALPHA_3_CODE", "PERIOD", "VALUE"),
    col_types = "icdd"
  ) %>%
    rename_with(
      tolower
    ) %>%
    rename(
      un_code = country.un_code,
      alpha_3_code = species.alpha_3_code,
      year = period
    )

  # iso3 codes
  iso3codes_df <- readr::read_csv(
    file.path(data_folder, iso3codes_file),
    col_select = c("UN_Code", "ISO3_Code"),
    col_types = "ii"
  ) %>%
    rename_with(
      tolower
    )

  # CPC_Group_Encodes
  groups_df <- readr::read_csv(
    file.path(data_folder, CPC_Group_En_file),
    col_select = c("3A_Code", "CPC_Group_En"),
    col_types = "cc"
  ) %>%
    # Inputs:
    rename(
      alpha_3_code = `3A_Code`,
      group = CPC_Group_En
    ) %>%
    separate(
      group, c("grouping", "misc"),
      sep = " ", remove = FALSE
    ) %>%
    mutate(
      group = tolower(if_else(!str_detect(grouping, "Other"),
        str_remove_all(grouping, ","), group
      ))
    ) %>%
    select(-grouping, -misc)


  ##  2 - Code the data to ISO3C and CPC_Group_En
  aqua_production_df <- aqua_production_df %>%
    left_join(iso3codes_df, by = "un_code") %>%
    left_join(groups_df, by = "alpha_3_code") %>%
    mutate(unit = "1000_usd") %>%
    select(iso3_code, group, year, unit, value) %>%
    group_by(iso3_code, group, year, unit) %>%
    summarise(
      value_usd = sum(value, na.rm = TRUE) * 1000,
      .groups = "drop"
    ) %>%
    filter(value_usd > 0)

  return(select(aqua_production_df, iso3_code, year, group, value_usd))
}
