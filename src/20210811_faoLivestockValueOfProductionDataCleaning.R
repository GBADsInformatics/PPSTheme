#############################################
# Creator: Gabriel Dennis 
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210811
# 
# This program contains code which reads in FASTOAT data from the 
# QV table (Value of Agricultural Production) 
# currently located at http://www.fao.org/faostat/en/#data/QV
# cleans the data, coding the countries to ISO3C regions 
# subsets for current USD  and saves the output since 1991 to the file
# data/output/{YYYYMMDD}_FAOSTAT_Livestock_ValueOfProduction_USD.csv
############################################


## 0 - Load libraries and source files
library(dplyr)
library(tidyr)
library(stringr)
library(magrittr)
source('src/FAOSTAT_helper_functions.R')

## 1 - Subset data and select columns

tmp_dir <- file.path('data', 'temp')
tmp_file <- file.path(tmp_dir,
                      'Value_of_Production_E_All_Data_(Normalized).zip')

# Read in Data using FAOSTAT package
# store in data/temp and remove afterwards
if (file.exists(tmp_file)) {
  livestock_df <- readr::read_csv(tmp_file, 
                                  col_select = c("Area Code", "Item",
                                                 "Element Code", "Year", 
                                                  "Unit", "Value"))
} else {
  livestock_df <- FAOSTAT::get_faostat_bulk(code = 'QV', tmp_dir)
}

# Subset the data for year > 1991
# Subset the data for regex of item "meat|milk|eggs"
livestock_df <- livestock_df %>% 
  rename_with(tolower) %>% 
  rename_with(~ str_replace_all(.x, " ", "_")) %>%
  filter(year > 1991, 
         str_detect(item, "Meat|Milk|Eggs"), 
         element_code ==  '58')  %>% 
  select(area_code, item, year, unit, value) 

## 3 - Code Data for ISO3C regions and drop unmatched regions
livestock_df$iso3c <- countrycode::countrycode(livestock_df$area_code,
                                               'fao', 'iso3c')
livestock_df <- drop_na(livestock_df)


## 4 - Split item into animal, item

# Todo this - remove whole fresh, total from item
livestock_df <- livestock_df %>% 
  separate(
    item, c('item', 'animal'), sep = ',') %>% 
  filter(!str_detect(animal, 'Total')) %>% 
  mutate(animal = trimws(str_remove(animal, 'whole fresh'))) 

## 4 - Save to file
output_file <- file.path('data', 'output', paste0(format(Sys.Date(),'%Y%m%d'), 
                              '_FAOSTAT_Livestock_ValueOfProduction_USD.'))

arrow::write_parquet(livestock_df,paste0(output_file, 'parquet') )
readr::write_csv(livestock_df, file = paste0(output_file, 'csv'))

## 5 - Clean up
if (file.exists(tmp_file) && 
    file.exists(paste0(output_file, 'csv'))) {
  file.remove(tmp_file)
}


