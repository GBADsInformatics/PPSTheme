####################################
# Creator: Gabriel Dennis 
# GitHub: @denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210825
# 
# 
# This script contains code which reads in FASTOAT data from the 
# QCL table (Crops and livestock products) 
# currently located at http://www.fao.org/faostat/en/#data/QCL
# cleans the data, coding the countries to ISO3C regions 
# saves the output animal stock values to the file
# data/output/{YYYYMMDD}_FAOSTAT_Livestock_Stocks.csv
####################################

## 0 - Load libraries and source files
library(dplyr)
library(tidyr)
library(stringr)
library(magrittr)
source('src/FAOSTAT_helper_functions.R')


## 1 - Read in the data

# Temporary directory path and temporary file names
tmp_dir <- file.path('data', 'temp')
tmp_file <- file.path(tmp_dir,
                      'Production_Crops_Livestock_E_All_Data_(Normalized).zip')
tmp_parquet <- file.path(tmp_dir, paste0(format(Sys.Date(),'%Y%m%d'), 
                                   '_Production_Crops_Livestock_E_All_Data.parquet'))

fao_code <- 'QCL'


# Read in Data using FAOSTAT package
# store in data/temp and remove afterwards
if (file.exists(tmp_parquet)) {
  livestock_df <- arrow::read_parquet(tmp_parquet)
} else {
  # Get the bulk normalized zip
  livestock_df <- FAOSTAT::get_faostat_bulk(code = fao_code, tmp_dir)
  
  # column names we will use 
  col_vars <- c('area_code', 'item', 'element', 'year', 'unit', 'value')
  if (length(setdiff(col_vars, names(livestock_df))) > 0) {
    stop(paste0('FAOSTAT raw data has incorrect column names: ',
                names(livestock_df)))
  }
  # Check the file was stored under the correct name
  if (!file.exists(tmp_file)) {
    stop(paste0("File was stored with incorrect  file name."))
  }
  # Save to parquet file
  arrow::write_parquet(livestock_df,tmp_parquet)
}


## 2 - Initial data cleaning pipeline ------------------------------#

livestock_df <- livestock_df %>% 
  select(
    area_code, item, element, year, unit, value
  ) %>% 
  filter(
    element == 'Stocks', item != 'Beehives'  # Drop Beehives as this won't be necessary
  ) %>% 
  mutate(
    iso3c = countrycode::countrycode(area_code, 'fao', 'iso3c')
  ) %>% 
  drop_na() %>% 
  mutate( # Convert all stocks to head
    head = if_else(str_detect(unit, "Head|No"), value, value * 1000)
  ) %>% 
  select(
    -unit, -value, -element, -area_code
  )  

if (nrow(livestock_df) == 0) {
  stop('Incorrect filtering operation')
}


livestock_df <- livestock_df %>% 
  mutate(
    item = tolower(
      str_replace_all(str_remove_all(item, ','), ' ', '_')
      )
  ) %>% 
  pivot_wider(
    names_from = item, values_from = head
  ) 

## 4 - Double Counting Categories ------------------------------#
## 
## Some categories contain entries from multiple livestock types
## Cattle and Buffaloes - cattle and buffaloes
## Sheep and Goats   - sheep and goats
## poultry, birds - All poultry birds including chicken and gees
## 
## These are included to make long term comparisons easier for countries 
## which do not report all animal types. 

### CATTLE AND BUFFALOES 
# # Check the only countries which report the multiple category
# 
# Cattle is only NA when cattle and buffaloes are NA
# all(is.na(livestock_df$cattle) == is.na(livestock_df$cattle_and_buffaloes))
# 
# # Buffaloes are always equal to cattle_and_buffaloes - cattle
# livestock_df %>%
#   select(iso3c, year, cattle, buffaloes, cattle_and_buffaloes) %>%
#   filter(!is.na(buffaloes)) %>%
#   mutate(
#     buffaloes_imp = (cattle_and_buffaloes - cattle) == buffaloes
#   ) %>%
#   count(buffaloes_imp)  # All True

## DECISION: DROP Cattle and Buffaloes 

### Sheep and Goats 

# > sum(is.na(livestock_df$sheep) != is.na(livestock_df$sheep_and_goats))
# [1] 598
# > sum((is.na(livestock_df$goats)  & is.na(livestock_df$goats)) != is.na(livestock_df$sheep_and_goats))
# [1] 289
# > sum((is.na(livestock_df$goats)  & is.na(livestock_df$sheep)) != is.na(livestock_df$sheep_and_goats))
# [1] 0

# No countries only report sheep and goats
#  - Check that it is always equal to the difference
# livestock_df %>%
#   select(iso3c, year, sheep, goats, sheep_and_goats) %>%
#   filter(!is.na(sheep)) %>%
#   mutate(
#     sheep_imp = if_else(is.na(goats), 
#                         sheep_and_goats == sheep, 
#                         sheep_and_goats  - goats == sheep),
#   ) %>%
#   count(sheep_imp) # All true
# 
# livestock_df %>%
#   select(iso3c, year, sheep, goats, sheep_and_goats) %>%
#   filter(!is.na(goats)) %>%
#   mutate(
#     goat_imp = if_else(is.na(sheep),
#                         sheep_and_goats == goats,
#                         sheep_and_goats  - sheep == goats),
#   ) %>%
#   count(goat_imp) # All true
## DECISION: DROP Sheep and Goats
### 

### Poultry Birds

# Check if it is the sum of Chickens, Turkeys, geese_and_guinea_fowls
# table(rowSums(select(livestock_df, 
#                      chickens, 
#                      geese_and_guinea_fowls,
#                      ducks,
#                      turkeys), na.rm = TRUE) == livestock_df$poultry_birds)
# FALSE  TRUE 
# 393 10196 

# Check where this is not the case
# livestock_df %>% 
#   select(iso3c, year, chickens, geese_and_guinea_fowls, ducks,  turkeys, poultry_birds) %>% 
#   rowwise() %>% 
#   mutate(
#     diff = poultry_birds - sum(c_across(chickens:turkeys),  na.rm = TRUE) ,
#     diff_pct = round((diff/poultry_birds) * 100)
#   ) %>% 
#   filter(diff_pct > 10) %>% 
#   count(iso3c)

# Only has a greater than 10 % difference in Hong Kong, Cyprus,Syria and Egypt
# Non of these differences occur after 1990

# DECISION: Drop Poultry Birds


# Drop values and tidy data
livestock_df <- livestock_df %>% 
  select(
    -cattle_and_buffaloes, -sheep_and_goats, -poultry_birds
  ) %>% 
  pivot_longer(
    !c("year", "iso3c"),
    names_to = 'item', 
    values_to = 'head', 
    values_drop_na = TRUE
   )  
  



## 5 - Save to file ------------------------------#

output_file <- file.path(
  'data', 'output',
  paste0(format(Sys.Date(),'%Y%m%d'), 
   '_FAOSTAT_Livestock_Stock_Numbers.')
  )

# Remove earlier versions of this file
output_dir <- file.path('data', 'output')
output_files <- list.files(output_dir)
remove_files <- str_detect(output_files, 
                           '_FAOSTAT_Livestock_Stock_Numbers')
file.remove(file.path(output_dir, output_files[remove_files]))


# Write to disk
arrow::write_parquet(livestock_df,paste0(output_file, 'parquet') )
readr::write_csv(livestock_df, file = paste0(output_file, 'csv'))

## 6 - Clean up
## Only remove the temporary zip file for now.
if (file.exists(tmp_file) && 
    file.exists(paste0(output_file, 'csv'))) {
  file.remove(tmp_file)
}






