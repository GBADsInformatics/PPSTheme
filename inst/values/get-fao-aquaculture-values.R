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

renv::activate(project = '.')

## 0 - Libraries  ------------------------------#
pkgs <- c("here", "tidyr", "readr",
          "dplyr", "magrittr", "janitor", "logging")
sapply(pkgs, require, character.only = TRUE)

# Setup logging
basicConfig()

# Helper Functions --------------------------------------------------------
source(here::here("R", "utils", "FAOSTAT_helper_functions.R"))


# Config ------------------------------------------------------------------
loginfo("Parsing configurations")
config <- config::get()


## 1 - Parameters ------------------------------#
data_dir <- list.dirs(config$data$source$tables$global_aquaculture_production$dir)[2]

# Locations of each file inside the global aquaculture production directory
params <- list(
    data_dir = data_dir,
    value_file = "AQUACULTURE_VALUE.csv",
    quantity_file = "AQUACULTURE_QUANTITY.csv",
    cpc_group_en_file = "CL_FI_SPECIES_GROUPS.csv",
    iso3_codes_files = "CL_FI_COUNTRY_GROUPS.csv",
    use_years = 1994:2019,
    exchange_rates_file = Sys.glob(here::here("data", "FAOSTAT",
                                              "*Exchange_rate_E_All_Data.parquet"))
)
loginfo("File Directory: %s", data_dir)


# Read in files and Convert  ------------------------------#

aqua <- list()

# Read in Codes and Value Files

# ISO3 codes for country mappings
loginfo("Importingo ISO3 Codes")
aqua$iso3codes <- readr::read_csv(
    file.path(params$data_dir, params$iso3_codes_files),
    show_col_types = FALSE
) %>%
    janitor::clean_names() %>%
    select(un_code, iso3_code, name_en)


# Aquatic values in 1000 USD
loginfo("Importing Aquaculture Values")
aqua$fisheries_values <- readr::read_csv(
    file.path(params$data_dir, params$value_file),
    show_col_types = FALSE
)%>%
    janitor::clean_names() %>%
    filter(period %in% params$use_years) %>%
    group_by(country_un_code, species_alpha_3_code, measure, period) %>%
    summarise(
        value_1000_usd = sum(value, na.rm = TRUE), .groups = "drop"
    ) %>%
    unique()


# Aquaculture production quantities in tonnes of
# wet weight
loginfo("Importing Aquaculture quantities")
aqua$fisheries_quantity <- readr::read_csv(
    file.path(params$data_dir, params$quantity_file),
    show_col_types = FALSE
) %>%
    clean_names() %>%
    filter(period %in% params$use_years) %>%
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
    left_join(aqua$iso3codes, by = c("un_code")) %>%
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
    summarise(mean_2014_2016_slc_price = mean(slc_price, na.rm = TRUE), .groups = "drop")

mean_exchange_rates <- aqua$fao_exchange_rates %>%
    filter(year %in% 2014:2016) %>%
    group_by(iso3_code) %>%
    summarise(mean_2014_2016_exchange = mean(exchange_rate, na.rm = TRUE), .groups = "drop")

# Join back mean LCU prices and calculate constant values
fao_fisheries <- fao_fisheries %>%
    left_join(mean_fisheries_prices, by = c("iso3_code", "species_code")) %>%
    left_join(mean_exchange_rates, by = c("iso3_code")) %>%
    mutate(aquaculture_constant_2014_2016_usd_price = (mean_2014_2016_slc_price * mean_2014_2016_exchange)) %>%
    mutate(aquaculture_constant_2014_2016_constant_usd_value = tonnes * aquaculture_constant_2014_2016_usd_price)





##  - Save the data  ------------------------------#
aqua_table <- arrow::Table$create(fao_fisheries %>%
  select(
    iso3_code,
    faost_code,
    name_en,
    species_code,
    year,
    tonnes,
    value_1000_usd,
    exchange_rate,
    slc_price,
    mean_2014_2016_slc_price,
    mean_2014_2016_exchange,
    aquaculture_constant_2014_2016_usd_price,
    aquaculture_constant_2014_2016_constant_usd_value
  ))


# Add initial metadata
aqua_table$metadata <- list(
  iso3_code = "ISO 3166-1 alpha-3",
  faost_code = "FAOSTAT Area Code",
  name_en = "FAO Area Name",
  species_code = "ASFIS Species Code",
  year = "Year in YYYY format",
  tonnes = "Metric Tonnes of live weight",
  value_1000_usd = "Current value in thousands of US dollars",
  exchange_rate = "FAO Exchange rate for SLC",
  slc_price = "SLC prices per tonne  calculated using the FAO annual exchange rate",
  mean_2014_2016_slc_price = "Average SCL price between 2014 and 2016",
  mean_2014_2016_exchange = "Average exchange rate between SLC and USD between 2014 and 2016",
  aquaculture_constant_2014_2016_usd_price = "Constant prices per tonne of aquaculture using the 2014-2016 SLC prices and the mean exchange rates for the same period",
  aquaculture_constant_2014_2016_constant_usd_value = "Constant prices multiplied by production quantities",
  date = iso_date(),
  contributor = "Gabriel Dennis CSIRO, gabriel.dennis@csiro.au",
  format = "Arrow Table",
  language = "English",
  source = paste0("FAO.GLOBAL AQUACULTURE PRODUCTION. License: CC BY–NC–SA 3.0 IGO.",
                   "Extracted from:  https://www.fao.org/fishery/statistics-query/en/aquaculture.",
                   "Data of Access: 2022-02-01.")
)



# Write to File -----------------------------------------------------------
if (!dir.exists(dirname(config$data$output$crop_values))) {
    dir.create(dirname(config$data$output$crop_values))
}

loginfo("Writing to parquet file")
arrow::write_parquet(
    aqua_table,
    config$data$output$aquaculture_values
)


