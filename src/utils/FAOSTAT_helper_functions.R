####################################
# Creator: Gabriel Dennis
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20211021
#
# File Description: This script
# contains some helper functions to clean
# up FAOSTAT data
####################################
get_gbads_file <- function(str, dir = here::here("data", "raw", "FAOSTAT")) {
  files <- list.files(dir)
  file_match <- grep(str, files, value = TRUE, fixed = TRUE)
  return(file.path(dir, sort(file_match, decreasing = TRUE)[1]))
}



## 0 - Adds Country Codes to FAO Tables------------------------------#
add_country_codes <- function(df, code_col, name_col) {
  require(dplyr)
  require(magrittr)
  require(tidyselect)
  require(tidyr)


  code_folder <- here::here("data", "codes", "FAOSTAT")

  if (!dir.exists(code_folder)) {
    stop("Code Directory does not exist")
  }

  fao_country_codes <- readRDS(grep("FAOSTAT_Country_Codes.rds",
    list.files(code_folder, full.names = TRUE),
    value = TRUE
  ))

  fao_country_codes <- fao_country_codes %>%
    rename_with(~ tolower(gsub(" ", "_", .x))) %>%
    select(country_code, country, iso3_code) %>%
    drop_na(iso3_code) %>%
    distinct()

  df <- df %>%
    rename(country_code = {{ code_col }}, country = {{ name_col }})

  return(
    left_join(fao_country_codes, df, by = c("country_code", "country"))
  )
}


## 1 - Select by Item Codes ------------------------------#

select_fao_items <- function(df, code_col, which = c("live_weights", "stocks", "vop_items")) {


  code_folder <- here::here("data", "codes", "FAOSTAT")

  type <- match.arg(which, choices = c("live_weights", "stocks", "vop_items"))
  file <- switch( type, "live_weights" = "FAOSTAT_Meat_Live_Weight_Codes.rds",
                  "stocks" =  "FAOSTAT_Livestock_Codes.rds",
                  "vop_items" =   "FAOSTAT_Vop_Item_Codes.Rds")

  codes <-  readRDS(file.path(code_folder,file)) %>%
    rename_with(~ tolower(gsub(" ", "_", .x)))

  return(dplyr::filter(df, {{ code_col }} %in% codes$item_code))
}


select_fao_currency <- function(df, ...) {
  groupvars <- enquos(...)
  element_lvs <- c(
    "Producer Price (USD/tonne)",
    "Producer Price (SLC/tonne)",
    "Producer Price (LCU/tonne)",
    "Producer Price Index (2014-2016 = 100)"
  )
  df$element <- factor(df$element, levels = element_lvs)

  df %>%
    group_by(!!!groupvars) %>%
    arrange(element) %>%
    summarise(
      value = first(value),
      element = first(element),
      flag = first(flag), .groups = "drop"
     ) %>%
    filter(
      !(stringr::str_detect(element, 'Index')) # Remove Producer Price index for now
    )
}

convert_fao_to_current_usd <- function(df) {

  require(priceR)

  # Converts all prices to 2015 US dollars.
  annual_exchange_rates <- arrow::read_parquet(get_gbads_file('Exchange_rate_E_All_Data_(Normalized).parquet')) %>%
    rename_with(~tolower(gsub(' ', '_', .x))) %>%
    add_country_codes(area_code, area)

  inflation_rates <- data.frame(year = 1992:2020, inflation = priceR::adjust_for_inflation(
    rep(1, length(1992:2020)),
    1992:2020, 2020, country= 'US'))

  base_values <- df %>%
    filter(2014 <= year, year <= 2016) %>%
    group_by(iso3_code, item) %>%
    summarise(
      value_2015 = mean(year, na.rm = TRUE), .groups = 'drop'
    )


  df %>%
    left_join(annual_exchange_rates %>%
                select(country_code, country, iso3_code, year, value),
              by = c("country", "iso3_code", 'year')) %>%
    mutate( # Use FAO conversion
      value = case_when(
        stringr::str_detect(element, 'SLC') ~ value.x / value.y,
        TRUE ~ value.x
      ),
      flag_notes = case_when(stringr::str_detect(element, 'SLC') ~ 'Converted from FAO Exchange Rates',
      TRUE ~ 'FAO Calculation')
    ) %>%
    left_join(base_values, by = "year") %>%
    mutate(usd_ = value * inflation,
           element = 'Producer Price (USD/tonne) - Constant 2015 Values') %>%
    select(-value.x, -value.y)

}





convert_fao_unit <- function(df, unit_col, value_col, which) {
  which <- match.arg(which, choices = c("stocks"))
  switch(which,
    stocks = df %>% mutate(value = case_when(
      {{ unit_col }} == "1000 Head" ~ value * 1000,
      TRUE ~ value
    )) %>%
      select(-{{ unit_col }})
  )
}


# Function to add flag descriptions
add_fao_flag_descriptions <- function(df, flag_col) {
  flags <- c("A", "Fc", "M", "Im", "F", "", "*", "Ce", NA, 'X')
  flag_desc <- c(
    "Aggregate, may include official, semi-official, estimated or calculated data",
    "Calculated data", "Data not available", "FAO data based on imputation methodology",
    "FAO estimate", "Official data", "Unofficial figure", "Calculated data based on estimated data", "Official Data",
    'International Reliable Source'
  )
  flag_short_desc <- c(
    "Aggregate",
    "Calculated data", "Data not available", "FAO Imputation",
    "FAO estimate", "Official", "Unofficial", "Calculation based on Estimate", "Official", 'Reliable Source'
  )
  df$flag_description <- plyr::mapvalues(df[[flag_col]], from = flags, to = flag_desc)
  df$flag_short_description <- plyr::mapvalues(df[[flag_col]], from = flags, to = flag_short_desc)
  return(df)
}


# Load price data

get_fao_meat_liveweight_prices <- function() {
  price_str <- "20211108_FAO-Constant-2014-2016-prices.parquet"
  fao_live_wt_prices <- arrow::read_parquet(get_gbads_file(price_str, dir = here::here('data', 'temp'))) %>%
    add_country_codes(area_code, area) %>%
    select_fao_items(item_code,  'live_weights') %>%
    select(country, iso3_code, item, year, constant_usd) %>%
    separate(item, c(NA, 'item'), sep= ',', extra = 'merge') %>%
    mutate(item = trimws(item))
  return(fao_live_wt_prices)
}
get_fao_livestock_numbers <- function() {
  stocks_str <- "Production_Crops_Livestock_E_All_Data_(Normalized).parquet"
  fao_stocks <- arrow::read_parquet(get_gbads_file(stocks_str)) %>%
    filter(element == 'Stocks', year > 1991) %>%
    add_country_codes(area_code, area) %>%
    select_fao_items(item_code, 'stocks') %>%
    convert_fao_unit(unit, which = 'stocks') %>%
    select(country, iso3_code, item, element, year, value, flag) %>%
    add_fao_flag_descriptions('flag')
  return(fao_stocks)

}

