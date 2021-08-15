####################################
# Creator: Gabriel Dennis 
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210813
# 
# File Description: This script will read in the producer prices 
# from the FAOSTAT table PP (http://www.fao.org/faostat/en/#data/PP)
# and subset them for annual prices from a preferred currency
# and filter them for liveweight meat prices. 
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
                      'Prices_E_All_Data_(Normalized).zip')
tmp_parquet <- file.path(tmp_dir, paste0(format(Sys.Date(),'%Y%m%d'), 
                                         '_Prices_E_All_Data_.parquet'))

fao_code <- 'PP'

# Read in Data using FAOSTAT package
# store in data/temp and remove afterwards
if (file.exists(tmp_parquet)) {
  price_df <- arrow::read_parquet(tmp_parquet)
} else {
  # Get the bulk normalized zip
  price_df <- FAOSTAT::get_faostat_bulk(code = fao_code, tmp_dir)
  
  # Check the file was stored under the correct name
  if (!file.exists(tmp_file)) {
    errorCondition(paste0("File was stored with in different file name, "))
  }
  # Save to parquet file
  arrow::write_parquet(price_df,tmp_parquet)
}

price_df <- price_df %>% # Filter for annual values
  filter(
    months == "Annual value"
  ) %>% 
  mutate(
    iso3c  = countrycode::countrycode(area_code,"fao", "iso3c", warn = FALSE), 
    element = trimws(tolower(str_remove_all(element, "Producer Price|[()]"))), 
    item = tolower(item)
  ) %>% 
  drop_na() %>% 
  select(
    iso3c, item, element, year, unit, value
  )  %>% 
  filter(
    str_detect(item, "meat live weight"),
    !(item %in% c('meat nes', 'meat, total')),
      !str_detect(element, "index")
  ) %>%     # Extract the animal from the liveweight item
  separate(
    item, c("item", "animal"), sep = ', '
  ) %>% 
  select(
    -item, -unit
  ) 
# Change element to a factor
price_df$element <- factor(test_df$element,
                          levels = c('lcu/tonne','slc/tonne','usd/tonne'), 
                          ordered = TRUE)

price_df <- price_df%>% 
  group_by(iso3c, animal,year) %>% 
  arrange(year) %>% 
  summarise(
    unit = last(element), 
    value = last(value)
  ) 

 #%>% 
  # pivot_wider(
  #   names_from = element, 
  #   values_from = value
  # )  %>% 
  #  View()
  # 
































