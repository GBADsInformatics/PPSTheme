####################################
# Creator: Gabriel Dennis 
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210816
# 
# File Description:  This script reads in the FAOSTAT
# currency conversion table PE, located at 
#  - http://www.fao.org/faostat/en/#data/PE
# which converts SLC (Standard Local Currency Units)
# to current USD. 
# 
# Outputs:
#   - data/output/{date}_FAOSTAT_USD_Exchange_Rates.parquet
####################################

## 0 - Libraries ------------------------------#
library(dplyr)
library(tidyr)
library(stringr)


## 1 - Import data from FAOSTAT ------------------------------#
# TODO: Migrate importing to FAOSTAT_helper_functions

# Temporary directory path and temporary file names
tmp_dir <- file.path('data', 'temp')
tmp_file <- file.path(tmp_dir,
                      'Exchange_rate_E_All_Data_(Normalized).zip')
tmp_parquet <- file.path(tmp_dir, paste0(format(Sys.Date(),'%Y%m%d'), 
                                         '_Exchange_rate_E_All_Data.parquet'))


# Read in Data using FAOSTAT package
# store in data/temp and remove afterwards
if (file.exists(tmp_parquet)) {
  exchange_df <- arrow::read_parquet(tmp_parquet)
} else {
  # Get the bulk normalized zip
  exchange_df <- FAOSTAT::get_faostat_bulk(code = 'PE', tmp_dir)
  
  if (!file.exists(tmp_file)) {
    errorCondition(paste0("File was stored with in different file name, "))
  }
  
  # Save to parquet file
  arrow::write_parquet(exchange_df,tmp_parquet)
}


## 3 - Code and subset the data ------------------------------#
# Code to ISO3
# Subset for year > 1990 

exchange_df <- exchange_df %>% 
  filter(
    year > 1990  # Otherwise the exchange rates are usually constant
  ) %>% 
  select(
    area_code, iso_currency_code, year, value
  ) %>% 
  mutate(
    iso3c = countrycode::countrycode(area_code, 
                                     "fao", 
                                     "iso3c")
  ) %>% 
  drop_na() %>% 
  select(
    iso3c, iso_currency_code, year, value
  )




## 4 - Save to file

# Remove earlier versions of this file
output_dir <- file.path('data', 'output')
output_files <- list.files(output_dir)
remove_files <- str_detect(output_files, 
                           'FAOSTAT_USD_Exchange_Rates')
file.remove(file.path(output_dir, output_files[remove_files]))

output_file <- file.path('data', 'output', paste0(format(Sys.Date(),'%Y%m%d'), 
                                                  'FAOSTAT_USD_Exchange_Rates.'))

arrow::write_parquet(exchange_df,paste0(output_file, 'parquet') )
readr::write_csv(exchange_df, file = paste0(output_file, 'csv'))

## 5 - Clean up
if (file.exists(tmp_file) && 
    file.exists(paste0(output_file, 'csv'))) {
  file.remove(tmp_file)
}












