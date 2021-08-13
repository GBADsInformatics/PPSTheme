####################################
# Creator: Gabriel Dennis 
# GitHub: @denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210813
# 
# 
# This script contains code which reads in FASTOAT data from the 
# QCL table (Crops and livestock products) 
# currently located at http://www.fao.org/faostat/en/#data/QCL
# cleans the data, coding the countries to ISO3C regions 
# saves the output since to the file
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
  
  # Check the file was stored under the correct name
  if (!file.exists(tmp_file)) {
    errorCondition(paste0("File was stored with in different file name, "))
  }
  # Save to parquet file
  arrow::write_parquet(livestock_df,tmp_parquet)
}


## 2 - Data Cleaning pipeline
##  livestock_df has the columns
## area_code area item_code item element_code element year_code year unit value flag
livestock_df <- livestock_df %>% 
  select(
    area_code, item, element, year, unit, value
  ) %>% 
  filter(
    element == 'Stocks'
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

## 3 - Item categories which contain multiple animals
## Cattle and Buffaloes
## Sheep and Goats  
## 
## For these Items, for the moment we will only keep the double
## counted entry if the country does not report single entries 
## for both of the items. 
## 
## This can be seen in the commented lines below
## 
# livestock_df %>% 
#   filter(
#     str_detect(item, "Cattle|Buffaloes")
#   ) %>% 
#   pivot_wider(
#     names_from = item, values_from = head
#   ) %>% 
#   replace_na(
#     list(Buffaloes = 0)
#   ) %>% 
#   mutate(
#     diff = abs(Cattle + Buffaloes - `Cattle and Buffaloes`)
#   )  %>% 
#   summary()
# 
# livestock_df %>% 
#   filter(
#     str_detect(item, "Sheep|Goats")
#   ) %>% 
#   pivot_wider(
#     names_from = item, values_from = head
#   ) %>% 
#   replace_na(
#     list(Sheep = 0, Goats = 0)
#   ) %>% 
#   mutate(
#     diff = abs(Sheep + Goats - `Sheep and Goats`)
#   )  %>% 
#   summary()

# This can be achieved by keeping the double categories if
# one of the sub categories does not equal it. 

livestock_df <- livestock_df %>% 
  mutate(
    item = tolower(str_replace_all(item, ' ', '_'))
  ) %>% 
  pivot_wider(
    names_from = item, values_from = head
  ) 

# Add columns to code when to keep each item
# NA codes to FALSE
livestock_df$keep_sheep_goats<- purrr::map_lgl(1:nrow(livestock_df), 
                   function(i) {
                     livestock_df$sheep[i] == livestock_df$sheep_and_goats[i] ||
                     livestock_df$goats[i] == livestock_df$sheep_and_goats[i] 
                   })

livestock_df$keep_buffaloes_cattle <- purrr::map_lgl(1:nrow(livestock_df), 
                   function(i) {
                     livestock_df$buffaloes[i] == livestock_df$cattle_and_buffaloes[i] ||
                       livestock_df$cattle[i] == livestock_df$cattle_and_buffaloes[i] 
                   })

# Set index value to drop
livestock_df$sheep_and_goats[livestock_df$keep_sheep_goats != TRUE] <- NA
livestock_df$cattle_and_buffaloes[livestock_df$keep_buffaloes_cattle != TRUE] <- NA


# Drop values and tidy data
livestock_df <- livestock_df %>% 
  select(
    -keep_sheep_goats, 
    -keep_buffaloes_cattle
  ) %>% 
  pivot_longer(
    !c("year", "iso3c"),
    names_to = 'item', 
    values_to = 'head', 
    values_drop_na = TRUE
   )  
  
## 4 - Save to file
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

## 5 - Clean up
## Only remove the temporary zip file for now.
if (file.exists(tmp_file) && 
    file.exists(paste0(output_file, 'csv'))) {
  file.remove(tmp_file)
}






