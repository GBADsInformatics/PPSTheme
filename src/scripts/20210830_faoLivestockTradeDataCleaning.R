####################################
# Creator: Gabriel Dennis
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210830
#
# File Description: Reads in an cleans data from the
# FAOSTAT table TCL which contains import and export quantities and values
# for crops and livestock products.
#
# Currently there is too little data to do anything useful.
#
# Inputs: data/raw/20210830_FAOSTAT_TCL_Livestock_Crop_Trade.parquet
# Outputs: data/output/{data}_FAOSTAT_Livestock_Trade.csv/parquet
####################################


## 0 - Load Libraries ------------------------------#

library(FAOSTAT)
library(dplyr)
library(magrittr)
library(tidyr)
library(stringr)
library(countrycode)
source('src/FAOSTAT_helper_functions.R')


## 1 - Read in TCl table ------------------------------#

# temporary file
tmp_dir <- file.path('data', 'temp')
tmp_file <- file.path(tmp_dir, paste0(format(Sys.Date(), '%Y%m%d'), '_FAO_Livestock_Trade.parquet'))
if (!file.exists(tmp_file)) {

  tictoc::tic()
  trade_df <- arrow::read_parquet('data/raw/20210830_FAOSTAT_TCL_Livestock_Crop_Trade.parquet')
  tictoc::toc()



  ## 2 - Subset for livestock ------------------------------#

  # Livestock to subset for
  livestock <- c('animals_live_nes', 'animals_live_non-food',
                 'asses', ' buffalioes', 'camelids, other', 'camels',
                 'cattle', 'chickens', 'ducks', 'goats', 'horses', 'mules', 'pigs',
                 'rabbits_and_hares', 'rodents_other', 'sheep', 'turkeys')


  trade_df <- trade_df %>%
          mutate(
            item = tolower(str_replace_all(str_remove_all(item, ','), ' ', '_'))
          ) %>%
    filter(item %in% livestock)
} else {
  trade_df <- arrow::read_parquet(tmp_file)
}

# Filter for after 1990 and Filter out the unavailable data Flag:M
trade_df <- trade_df %>% filter(year > 1990, flag != 'M') %>%
  mutate(
    iso3c = countrycode::countrycode(area_code, 'fao', 'iso3c')
  ) %>%
  drop_na() %>% # Regions we won't need.
  select(iso3c, item, element, year, unit, value)

# Check for matching value and quantity for each entry
trade_df %>% group_by(iso3c, year, item) %>% count() %>% ungroup() %>% count(n, name = 'elements')
# A tibble: 4 x 2
# n elements
# <int>    <int>
# 1     1     4587
# 2     2    13158
# 3     3     1191
# 4     4     5559
## Not every entry has both import and export (removed via M flag filtering)


## 3 - Get Per head prices ------------------------------#

trade_df <- trade_df %>%
  mutate(
    value = if_else(str_detect(unit, '1000'), value*1000, value),
    element = tolower(str_replace_all(element, ' ', '_')),
    unit = case_when(
      unit == '1000 Head' ~ 'head',
      unit == 'Head' ~ 'head',
      unit == '1000 US$' ~ 'usd'
    )
  )  %>%
  unite(
    'element', c('element', 'unit'), sep = '_'
  ) %>%
  pivot_wider(
    names_from  = element,
    values_from = value
  ) %>%
  mutate(
    export_price_per_head_usd = case_when(
      !is.na(export_quantity_head) & export_quantity_head > 0 ~ export_value_usd/export_quantity_head
    )
  )

# Very limited data for a large number of countries and animals.
# Filter for export_price_per_head

exprice_df <- filter(trade_df, !is.na(export_price_per_head_usd)) %>%
  select(iso3c, year, item, export_price_per_head_usd) %>%
  spread(item, export_price_per_head_usd) %>%
  arrange(iso3c, year)


# Too little data to do anything usefull.

# Notes:
# China Pig Prices seem Realistic: 219 USD at 99kg per pig ~ https://www.pigprogress.net/World-of-Pigs1/Articles/2021/5/Chinas-pig-production-will-grow-19-in-2021-745100E/
#


























