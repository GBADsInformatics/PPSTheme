#############################################
# Creator: Gabriel Dennis 
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210813
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

# Temporary directory path and temporary file names
tmp_dir <- file.path('data', 'temp')
tmp_file <- file.path(tmp_dir,
                      'Value_of_Production_E_All_Data_(Normalized).zip')
tmp_parquet <- file.path(tmp_dir, paste0(format(Sys.Date(),'%Y%m%d'), 
                         '_Value_of_Production_E_All_Data.parquet'))


# Read in Data using FAOSTAT package
# store in data/temp and remove afterwards
if (file.exists(tmp_parquet)) {
  livestock_df <- arrow::read_parquet(tmp_parquet)
} else {
  # Get the bulk normalized zip
  livestock_df <- FAOSTAT::get_faostat_bulk(code = 'QV', tmp_dir)
  
  if (!file.exists(tmp_file)) {
    errorCondition(paste0("File was stored with in different file name, "))
    }
  
  # Save to parquet file
  arrow::write_parquet(livestock_df,tmp_parquet)
}

# Subset the data for year > 1991
# Subset the data for regex of item "meat|milk|eggs"
# Subset the data for USD -> Will get slightly different ratios 
# of meat and meat indigenous when allowing LCU and SLC
livestock_df <- livestock_df %>% 
  rename_with(tolower) %>% 
  rename_with(
    ~ str_replace_all(.x, " ", "_")
    ) %>%
  filter(
    year > 1991, 
    str_detect(item, "Meat|Milk|Eggs"), 
    !str_detect(item, 'Total'),
    element_code ==  '58'  # 1000 USD
    )  %>% 
  select(
    area_code, item, year, unit, value
    ) %>% 
  mutate(
    iso3c = countrycode::countrycode(area_code,'fao', 'iso3c')
    ) %>% 
  drop_na() %>% 
  separate(
    item, c('item', 'animal'), sep = ','
    ) %>% 
  filter(
    !str_detect(item, "Meat nes")
  ) %>% 
  mutate(animal = trimws(str_remove(animal, 'whole fresh'))) %>% 
  select(
    iso3c, animal, item, year, unit, value
  )

## 4 - Recode Meat and Meat Indigenous to Meat
## Only Geese, duck and rabbit have more indigenous entries

# Extract the meat records and non_meat records
meat_df <- filter(livestock_df, str_detect(item, "Meat"))
non_meat_df <- anti_join(livestock_df, meat_df)

meat_df <- meat_df %>% 
  group_by(iso3c, animal, year, unit) %>% 
  summarise(
    value = max(value)
  ) %>% 
  mutate(
    item = "Meat"
  ) %>% 
  ungroup() %>% 
  select(
    names(non_meat_df)
  )
  
# Bind rows
livestock_df <- bind_rows(meat_df, non_meat_df)

## 5 - Save to file

# Remove earlier versions of this file
output_dir <- file.path('data', 'output')
output_files <- list.files(output_dir)
remove_files <- str_detect(output_files, 
                           '_FAOSTAT_Livestock_ValueOfProduction_USD')
file.remove(file.path(output_dir, output_files[remove_files]))

output_file <- file.path('data', 'output', paste0(format(Sys.Date(),'%Y%m%d'), 
                              '_FAOSTAT_Livestock_ValueOfProduction_USD.'))

arrow::write_parquet(livestock_df,paste0(output_file, 'parquet') )
readr::write_csv(livestock_df, file = paste0(output_file, 'csv'))

## 6 - Clean up
if (file.exists(tmp_file) && 
    file.exists(paste0(output_file, 'csv'))) {
  file.remove(tmp_file)
}


