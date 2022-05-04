#! /usr/bin/Rscript  --vanilla

# Intro -------------------------------------------------------------------
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
# Date Created:  20220204
#
# Description:  Computes the total economic value
# for Livestock found in the FAOSTAT database.
#
# Inputs:
# Livestock Heads are sourced from the FAOSTAT
# Crop and Livestock Production Table
#
# Livestock Output tonnes are source from the FAOSTAT
# Crop and Livestock Production Table
#
# Livestock #slaughtered are sourced from the FAOSTAT
# Crop and Livestock Production Table
#
# Livestock Carcass Percentages are sourced from the FAO
# Technical Conversion Factors for Agricultural Commodities
#
#

renv::activate(project = ".")

# Libraries ---------------------------------------------------------------
pks <- c(
  "dplyr",
  "tidyr",
  "stringr",
  "janitor",
  "logging"
)


sapply(pks, library, character.only = TRUE, quietly = TRUE)


# Logging -----------------------------------------------------------------
basicConfig()

# Source Files  -----------------------------------------------------------
source(here::here("R", "utils", "FAOSTAT_helper_functions.R"))


# Config ------------------------------------------------------------------
logging::loginfo("Loading configuration file")
config <- config::get(file = file.path("conf", "config.yml"))



# Select correct FAOSTAT Item Codes For Matching --------------------------

#' get_livestock_codes
#'
#' Returns the FAO item codes which will be used in the
#' Valueation of livestock types
#'
#' @param code_dir directory containing rds files of FAOSTAT item codes
#'
#' @return a vector containing the livestock codes used
get_livestock_codes <- function(code_dir = config$data$codes$faostat$dir) {

  # FAOSTAT Item Codes to Use for each category that will be used
  code_rds_files <- list.files(
    config$data$codes$faostat$dir,
    full.names = TRUE,
    pattern = "*.rds$"
  )

  # Name files
  names(code_rds_files) <- basename(code_rds_files) %>%
    stringr::str_remove_all(".rds") %>%
    stringr::str_remove_all("FAOSTAT_")

  # Read in the item code data
  faostat_item_codes <- purrr::map(
    code_rds_files,
    ~ readRDS(.x) %>%
      janitor::clean_names()
  )

  names(faostat_item_codes) <- names(faostat_item_codes) |>
    janitor::make_clean_names()

  # Names of RDS files
  rds_names <- c(
    "livestock_codes",
    "vop_items_non_indigenous_codes",
    "meat_live_weight_codes",
    "livestock_meat_item_codes"
  )

  if (length(setdiff(rds_names, names(faostat_item_codes))) > 0) {
    stop("Incorrect code RDS file names")
  }

  # - Unique Livestock Codes that will be used
  livestock_codes <- unique(
    c(
      faostat_item_codes$livestock_codes$item_code,
      faostat_item_codes$vop_items_non_indigenous_codes$item_code,
      faostat_item_codes$meat_live_weight_codes$item_code,
      faostat_item_codes$livestock_meat_item_codes$item_code
    )
  )

  # Save the current version of codes used
  write.csv(
    faostat_item_codes$item_codes |>
      dplyr::filter(
        item_code %in% livestock_codes,
        domain_code %in% c("QCL", "QV", "PP")
      ),
    file.path(
      code_dir,
      "livestock_item_codes.csv"
    ),
    row.names = FALSE
  )

  return(
    list(
      codes = livestock_codes,
      code_list = faostat_item_codes
    )
  )
}



# Load Data ---------------------------------------------------------------
get_data <- function(files, codes, use_years = 1994:2018) {
  data <- purrr::map(
    files,
    ~ arrow::read_parquet(.) |>
      janitor::clean_names() |>
      dplyr::filter(
        year %in% use_years,
        item_code %in% codes
      ) |>
      clean_countries() |>
      sanitize_columns()
  )
}

# Extract the data, and match it to the correct livestock codes
livestock_codes <- get_livestock_codes()

loginfo("Importing and sanatizing processed tables")
data_tables <- config$data$processed$tables

livestock <- get_data(
  list(
    production = data_tables$crops_and_livestock_products,
    value_of_production = data_tables$value_of_production,
    producer_prices = data_tables$producer_prices
  ),
  livestock_codes$codes
)

# Remove unwanted characters
livestock$value_of_production$item <- stringr::str_remove_all(
  livestock$value_of_production$item,
  "whole_fresh_"
)

livestock$production$item <- stringr::str_remove_all(
  livestock$production$item,
  "whole_fresh_|edible_|_edible"
)


# Select Annual Values: FAOSTAT Months Code = 7021
livestock$prices <- dplyr::filter(
  livestock$producer_prices,
  months_code == 7021
)



# Livestock Yield ---------------------------------------------------------
#
# This is in dressing percentage and will need to be converted to
# Live Weight Equivalent
# This is different across countries and animals in how it is reported,
# however, we will assume that this is the true carcass yield for all animals
# due to the inconsistency in how the FAO collects data it is reported
# to the FAO, see
# https://fenixservices.fao.org/faostat/static/documents/QCL/QCL_methodology_e.pdf
# In most cases data is reported in dressed carcass weights.
loginfo("Computing Livestock Yield")
livestock$yield <- livestock$production %>%
  dplyr::filter(
    element %in% c("producing_animals_slaughtered", "production"),
    item_code %in% unique(livestock_codes$code_list$livestock_meat_item_codes$item_code)
  ) %>%
  dplyr::mutate(
    value = dplyr::case_when(
      stringr::str_detect(unit, "1000") ~ value * 1000,
      TRUE ~ value
    ),
    unit = dplyr::case_when(
      stringr::str_detect(unit, "1000") ~ "head",
      TRUE ~ unit
    )
  ) %>%
  dplyr::select(-element, -element_code, -flag, -year_code) %>%
  tidyr::spread(unit, value) %>%
  dplyr::filter(head > 0) %>% # Only get entries in which some values were recorded
  dplyr::mutate(
    yield_kg = round(tonnes * 1000 / head, 1)
  ) %>%
  tidyr::drop_na(yield_kg) %>%
  dplyr::filter(yield_kg > 0) |>
  assertr::verify((yield_kg > 0) & (yield_kg < 1000))

tapply(livestock$yield$yield_kg, livestock$yield$item, FUN = summary)


# Carcass percentages from the FAO technical conversion factors
carcass_pct <- config$data$processed$tables$technical_conversion_factors %>%
  read.csv() |>
  dplyr::mutate(
    animal_en = stringr::str_remove_all(animal_en, "s$"),
    iso3_code = tolower(iso3)
  ) %>%
  dplyr::select(iso3_code, animal_en, carcass_pct) %>%
  dplyr::filter(carcass_pct <= 100) %>%
  dplyr::mutate(
    carcass_pct = as.numeric(carcass_pct) / 100
  ) %>%
  tidyr::drop_na(carcass_pct) %>%
  assertr::verify((carcass_pct <= 1) & (carcass_pct > 0))

tapply(carcass_pct$carcass_pct, carcass_pct$animal_en, FUN = summary)


loginfo(paste(
  "Converting the FAO yields to live body weights using the",
  "FAO technical conversion factors"
))
livestock$yield <- livestock$yield %>%
  dplyr::mutate(
    animal_en = trimws(stringr::str_remove(item, "meat_"))
  ) %>%
  dplyr::left_join(carcass_pct, by = c("iso3_code", "animal_en")) %>%
  dplyr::group_by(animal_en) %>%
  dplyr::mutate(carcass_pct = case_when(
    is.na(carcass_pct) ~ mean(carcass_pct, na.rm = TRUE),
    TRUE ~ carcass_pct
  )) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(
    lbw_kg = yield_kg / carcass_pct
  ) %>%
  tidyr::separate(item, c("item", "animal"),
    sep = "_", extra = "merge", fill = "left"
  ) %>%
  dplyr::mutate(
    animal = trimws(animal),
    item = "stock"
  ) %>%
  dplyr::select(-head, -tonnes, -animal_en)


# Remove LBW KG Outliers --------------------------------------------------
# Checking with
# tapply(livestock$yield$lbw_kg, livestock$yield$animal, FUN = summary, na.rm = TRUE)
# Some cattle are said to have LBW of 1106
# Remove Malysia - Huge outlier due to low carcass pct
# Remove Niger - Appear to be consistently way too high
livestock$yield[(livestock$yield$iso3_code %in% c("mys", "ner")) &
  livestock$yield$animal == "cattle", ] <- NA



# Livestock Table ---------------------------------------------------------
# Create Livestock Table With Weights values and prices
#  - Use nested tibble data frames

livestock$value_of_production <- livestock$value_of_production %>%
  dplyr::select(-element_code, -year_code, -unit, -flag) %>%
  tidyr::spread(element, value) %>%
  tidyr::separate(item, c("item", "animal"),
    sep = "_", extra = "merge", fill = "left"
  ) %>%
  dplyr::mutate(
    animal = trimws(animal),
    item = tolower(item)
  )
# aggregate(livestock$value_of_production$gross_production_value_constant_2014_2016_thousand_us*1000,
# by = livestock$value_of_production['year'], FUN=sum, na.rm = TRUE)


livestock$production <- livestock$production %>%
  dplyr::filter(element %in% c("stocks", "producing_animals_slaughtered", "production")) %>%
  dplyr::mutate(
    value = case_when(
      stringr::str_detect(unit, "1000") ~ value * 1000,
      TRUE ~ value
    ),
    unit = case_when(
      stringr::str_detect(unit, "1000") ~ "head",
      TRUE ~ unit
    )
  ) %>%
  tidyr::separate(item, c("item", "animal"),
    sep = "_",
    extra = "merge", fill = "right"
  ) %>%
  dplyr::mutate(
    item = ifelse(element == "stocks", "stock", item)
  ) %>%
  dplyr::select(-element, -element_code, -year_code, -flag) %>%
  dplyr::mutate(
    animal = trimws(animal)
  ) %>%
  tidyr::spread(unit, value)

livestock$prices <- livestock$prices %>%
  dplyr::select(
    -element_code, -year_code, -unit,
    -flag, -months, -months_code, -unit
  ) %>%
  tidyr::separate(
    item,
    c("item", "animal"),
    sep = "_",
    extra = "merge",
    fill = "right"
  ) %>%
  dplyr::mutate(
    animal = trimws(animal)
  ) %>%
  tidyr::spread(element, value) %>%
  dplyr::mutate(
    item = case_when(
      stringr::str_detect(animal, "live_weight") ~ "stock",
      TRUE ~ item
    ),
    item = tolower(item)
  ) %>%
  dplyr::filter(animal != "meat_nes")


# Check the price per animal
tapply(livestock$prices$producer_price_usd_tonne,
  livestock$prices$animal,
  FUN = summary, na.rm = TRUE
)

# Stock Item Code is first
# Price Items second,
# Yield Items third
match_live_weight_items <- list(
  ass = c(1107, 1123, 1108),
  buffalo = c(946, 973, 947),
  camel = c(1126, 1138, 1127),
  cattle = c(866, 945, 867),
  chicken = c(1057, 1095, 1058),
  duck = c(1068, 1071, 1069),
  goat = c(1016, 1033, 1017),
  goose = c(1072, 1078, 1073),
  horse = c(1096, 1121, 1097),
  mule = c(1110, 1125, 1111),
  pig = c(1034, 1056, 1035),
  rabbit = c(1140, 1145, 1141),
  sheep = c(976, 1013, 977),
  turkey = c(1079, 1088, 1080)
)

# Match all tables to the stock codes
matches <- setNames(
  data.frame(t(as_tibble(match_live_weight_items))),
  c("stock_code", "price_code", "yield_code")
)



# Match Item and Animal ---------------------------------------------------
# Prices
recode_lvs <- function(var) {
  recode(
    var,
    and_guinea_fowls = "goose",
    goose_and_guinea_fowl = "goose",
    hen_in_shell = "chicken",
    and_hares = "rabbit",
    buffaloes = "buffalo",
    camels = "camel",
    cow = "cattle",
    goats = "goat",
    goose_and_guinea_fowl = "goose",
    horses = "horse",
    pigs = "pig"
  )
}


table(livestock$prices$item, livestock$prices$animal)
livestock$prices$animal <- stringr::str_remove_all(
  livestock$prices$animal,
  "live_weight_|whole_fresh_"
)

livestock$prices$animal <- recode_lvs(livestock$prices$animal)
table(livestock$prices$item, livestock$prices$animal)
# Check
setdiff(names(match_live_weight_items), livestock$prices$animal)

# Production

livestock$production$animal <- purrr::imap_chr(
  livestock$production$animal,
  ~ ifelse(is.na(.x), rownames(matches)[matches$stock_code == livestock$production$item_code[.y]], .x)
)

table(livestock$production$item, livestock$production$animal)
livestock$production$animal <- recode_lvs(livestock$production$animal)
setdiff(names(match_live_weight_items), unique(livestock$production$animal))

# Value of Production (None should be stock)
table(livestock$value_of_production$item, livestock$value_of_production$animal)
setdiff(names(match_live_weight_items), unique(livestock$value_of_production$animal))
livestock$value_of_production$animal <- recode_lvs(livestock$value_of_production$animal)
setdiff(names(match_live_weight_items), unique(livestock$value_of_production$animal))


# Yield (Should all be stock)
table(livestock$yield$item, livestock$yield$animal)

setdiff(names(match_live_weight_items), unique(livestock$yield$animal))
livestock$yield$animal <- recode_lvs(livestock$yield$animal)
table(livestock$yield$item, livestock$yield$animal)
setdiff(names(match_live_weight_items), unique(livestock$yield$animal))

# Create Livestock DF -----------------------------------------------------
# Match the Live Weight Price Item Codes to the stock items
livestock <- livestock[c("production", "yield", "value_of_production", "prices")]



livestock_df <- purrr::reduce(livestock, full_join,
  by = c("iso3_code", "faost_code", "area", "year", "item", "animal")
)


aggregate(livestock_df$gross_production_value_constant_2014_2016_thousand_us * 1000,
  by = livestock_df["year"],
  FUN = sum, na.rm = TRUE
)


# Live Weights ------------------------------------------------------------
# Impute Live Weights to get Values of Animal Stock
#
# If carcass % is outside the middle 80% set to the median
# with that amount removed
#################################################################
livestock_df <- livestock_df %>%
  dplyr::group_by(animal) %>%
  dplyr::mutate(
    lbw_kg = case_when(
      item == "stock" && is.na(lbw_kg) ~ median(lbw_kg, na.rm = TRUE),
      TRUE ~ lbw_kg
    )
  ) %>%
  dplyr::ungroup() %>%
  dplyr::select(-contains("_carcass_pct"), -contains("item_code"))


# Asset Values ------------------------------------------------------------
livestock_df <- livestock_df %>%
  mutate(
    tonnes = case_when(
      is.na(tonnes) ~ lbw_kg * head / 1000,
      TRUE ~ tonnes
    )
  ) %>%
  mutate(
    stock_value_lcu = ifelse(item == "stock",
      producer_price_lcu_tonne * tonnes, 0
    ),
    stock_value_slc = ifelse(item == "stock",
      producer_price_slc_tonne * tonnes, 0
    ),
    stock_value_usd = ifelse(item == "stock",
      producer_price_usd_tonne * tonnes, 0
    )
  )

# Check values
aggregate(livestock_df$stock_value_usd, livestock_df["year"], sum, na.rm = TRUE)


# Constant Dollars --------------------------------------------------------
exchange_rates <- arrow::read_parquet(
  get_gbads_file("Exchange_rate_E_All_Data.parquet",
    dir = here::here("data", "FAOSTAT")
  )
) %>%
  janitor::clean_names() %>%
  select(area_code, year, value)


# Get average 2014-2016 US dollar prices for each livestock
# type and product
mean_usd_prices_2014_2016 <- dplyr::filter(livestock_df, year %in% 2014:2016) %>%
  dplyr::ungroup() %>%
  dplyr::select(iso3_code, faost_code, item, animal, year, producer_price_slc_tonne) %>%
  dplyr::left_join(exchange_rates, by = c("faost_code" = "area_code", "year")) %>%
  dplyr::group_by(iso3_code, animal, item) %>%
  dplyr::summarise(
    mean_slc_price_per_tonne_2014_2016 = mean(producer_price_slc_tonne, na.rm = TRUE),
    mean_usd_conversion_2014_2016 = mean(value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  dplyr::mutate(
    producer_price_usd_per_tonne_2014_2016 = mean_slc_price_per_tonne_2014_2016 / mean_usd_conversion_2014_2016
  )



# Missing Prices ----------------------------------------------------------
stock_items <- mean_usd_prices_2014_2016$item == "stock"
aggregate(mean_usd_prices_2014_2016$producer_price_usd_per_tonne_2014_2016[stock_items],
  list(mean_usd_prices_2014_2016$animal[stock_items]), summary,
  na.rm = TRUE
)




# Append the average prices to the existing dataframe
livestock_df <- livestock_df %>%
  dplyr::left_join(mean_usd_prices_2014_2016,
    by = c(
      "iso3_code",
      "animal",
      "item"
    )
  ) %>%
  dplyr::mutate(
    stock_value_constant_2014_2016_usd = ifelse(item == "stock",
      producer_price_usd_per_tonne_2014_2016 * tonnes, 0
    )
  )


aggregate(livestock_df$gross_production_value_constant_2014_2016_thousand_us * 1000,
  by = livestock_df["year"],
  FUN = sum, na.rm = TRUE
)

loginfo(aggregate(livestock_df$stock_value_constant_2014_2016_usd, livestock_df["year"], sum, na.rm = TRUE))
loginfo(tapply(livestock_df$stock_value_constant_2014_2016_usd,
  livestock_df["animal"],
  FUN = summary
))



#  - Attach metadata  ------------------------------

# Turn into arrow table so schema and metadata can be attached

metadata_list <- list(
  iso3_code = "ISO 3166-1 alpha-3",
  faost_code = "FAOSTAT Area Code",
  area = "FAOSTAT Area Name",
  year = "Year in YYYY format",
  item_code = "FAOSTAT item code",
  item = "FAOSTAT production item name (lowercase)",
  animal = "english name for livestock type",
  head = "Number of animals",
  tonnes = "Metric Tonnes",
  gross_production_value_constant_2014_2016_thousand_i = "Gross production value of item in constant thousand 2014 2016 international dollars, for a certain item calculated to average 100 between 2014 and 2016",
  gross_production_value_constant_2014_2016_thousand_slc = "Gross production value of item in constant 2014 2016 in thousand standard local currency units, for a certain item calculated to average 100 between 2014 and 2016",
  gross_production_value_constant_2014_2016_thousand_us = "Gross production value of item in constant thousand 2014 2016 US dollars,  for a certain item calculated to average 100 between 2014 and 2016",
  gross_production_value_current_thousand_slc = "Gross production value of item in current thousand   standard local currency units, for a certain item calculated to average 100 between 2014 and 2016",
  gross_production_value_current_thousand_us = "Gross production value of item in current thousand US dollars",
  producer_price_index_2014_2016_100 = "An FAOSTAT Items producer price index, for a certain item calculated to average 100 between 2014 and 2016",
  producer_price_lcu_tonne = "Producer price of item in local currency per tonne",
  producer_price_slc_tonne = "Producer price of item in national currency per tonne",
  producer_price_usd_tonne = "Producer price of item in current USD per tonne",
  yield_kg = "Animal yield/carcass weight calculated from FAOSTAT data",
  carcass_pct = "FAO carcass % conversion factor",
  lbw_kg = "Adult live body weight equivalent in kg, calculated via yield_kg/(carcass_pct/100)",
  stock_value_lcu = "Value of animal stock in local currency units, calculated via producer_price_lcu_tonne * tonnes",
  stock_value_slc = "Value of animal stock in standard currency units, calculated via producer_price_slc_tonne * tonnes",
  stock_value_usd = "Value of animal stock in US dollars, calculated via producer_price_usd_tonne * tonnes",
  mean_slc_price_per_tonne_2014_2016 = "mean slc price per tonne averaged over 2014 to 2016",
  mean_usd_conversion_2014_2016 = "Mean conversion of slc to US dollars from  2014 to 2016 using the annual exchange rantes",
  producer_price_usd_per_tonne_2014_2016 = "Producer price per tonne in USD, calculated via mean_slc_price_per_tonne_2014_2016 / mean_usd_conversion_2014_2016",
  stock_value_constant_2014_2016_usd = "Value of animal stock in constant 2014 2016 US dollars, calculated via producer_price_usd_per_tonne_2014_2016 * tonnes",
  date = iso_date(),
  contributor = "Gabriel Dennis CSIRO, gabriel.dennis@csiro.au",
  format = "Arrow Table",
  language = "English",
  source = paste("[FAO.] Crops and livestock products.[Accessed 2022-01-28.] https://fenixservices.fao.org/faostat/static/bulkdownloads/Production_Crops_Livestock_E_All_Data_(Normalized).zip",
    "[FAO.] Value of Agricultural Production.[Accessed 2022-01-28.]https://fenixservices.fao.org/faostat/static/bulkdownloads/Value_of_Production_E_All_Data_(Normalized).zip",
    "[FAO.] Prices: Producer Prices.[Accessed 2022-01-28.] http://fenixservices.fao.org/faostat/static/bulkdownloads/Prices_E_All_Data_(Normalized).zip",
    sep = " -  - "
  ),
  frequency = "Yearly"
)

livestock_df <- livestock_df[, names(livestock_df) %in% names(metadata_list)]



livestock_table <- arrow::Table$create(livestock_df)



# Attach metadata
livestock_table$metadata <- metadata_list




##  - Write to file  ------------------------------#
loginfo("Writing to File")
arrow::write_parquet(
  livestock_table,
  here::here("data", "output", "faostat", "faostat_livestock_values.parquet")
)
