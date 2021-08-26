####################################
# Creator: Gabriel Dennis 
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210806
# 
# File Description: This produces a table containing 
# estimations of Scenario AS2 - 
# The the value of animal stock for all FAO countries 
# after 1991. 
# This is done so that producer prices are available. 
# 
# Inputs tables: 
#     - data/output/{date}_FAOSTAT_Livestock_Stock_Numbers.parquet
#     - data/output/{date}_FAOSTAT_Annual_Meat_Liveweight_Prices_USD_LCU_SLC.parquet
#     - data/output/FAOSTAT_liveweight_conversion_factors.csv
#     - data/output/{date}_IFS_USD_Currency_exchange_data.parquet
#     
# Output tables:
#     - data/output/{date}_Scenario_AS2_Value_Of_Animal_Stock.parquet
####################################

## 0 - Load Libraries ------------------------------#

library(dplyr)
library(tidyr)
library(stringr)
library(magrittr)


## 1 - Import input tables ------------------------------#
data_file_path <- function(data_file, dir= NA) {
  if (is.na(dir)) {
    output_data_folder <- file.path('data', 'output')
  } else{
    output_data_folder <- file.path('data',dir)
  }
  
  output_data_files <- list.files(output_data_folder)
  return(
    file.path(output_data_folder, 
    output_data_files[str_detect(output_data_files,data_file)])
  )
}

print_values <- function(vals) {
  cat(sort(unique(vals)), sep = '\n')
}

# FAOSTAT animal stock values per country
animal_stock_df <- arrow::read_parquet(
  data_file_path("FAOSTAT_Livestock_Stock_Numbers.parquet")
  ) %>% 
  filter(
    year > 1990
  )


# FAOSTAT liveweight meat prices per country
meat_prices_df <-  arrow::read_parquet(
  data_file_path("FAOSTAT_Annual_Meat_Liveweight_Prices_USD_LCU_SLC.parquet")
  )


# FAOSTAT technical conversion factors for liveweights (imputed)
fao_conversion_df <-  arrow::read_parquet(
  data_file_path("FAOSTAT_liveweight_conversion_factors_IMPUTED.parquet"), 
  col_select = c("iso3", "animal", "value")
  ) %>% 
  rename(iso3c = iso3, liveweight = value)

# FAOSTAT USD exchange rates to convert currencies away from LCU
# ### FAOSTAT NUMBERS ARE WRONG
exchange_df <- arrow::read_parquet(
  data_file_path("IFS_USD_Currency_exchange_data.parquet")
) %>% 
  mutate(
    year = as.numeric(year)
  )


## 2 - Convert prices to current USD ------------------------#
# There appears to only be a single SLC recorded for every iso3c
# which does not have a USD/tonne entry. 

meat_prices_df <- meat_prices_df %>% 
  left_join(
   exchange_df
  ) %>%
  mutate(
    value = if_else(
      str_detect(unit, 'slc'), value*usd_exchange, value
    ),
    unit = "usd/tonne"
  ) %>% 
  select(
    -usd_exchange, 
  ) %>% 
  drop_na()

# Currently only don't have exchange rates for CUBA

## 3 - Convert prices to USD per animal ------------------------------#

# Read in mappings between the fao_stock, fao_prices, fao_tcf, fao_lu
cat_mappings <- readr::read_csv(
  data_file_path('FAOSTAT_category_mappings.csv', ''), 
  col_select = c('fao_stock', 'fao_prices', 'fao_tcf', 'fao_lu'), 
  show_col_types = FALSE
)


# # USA Cattle average weight
# us_cattle_weight <- fao_conversion_df %>%  filter(iso3c == 'USA', animal == 'cattle') %>% select(live_weight)
# 
# # Get the LU values
# lu_df <- readr::read_csv(data_file_path('_FAO_LU_values_NA_cow.csv', '')) %>% 
#   rename_with(tolower) %>% 
#   gather(animal, value, -region) %>% 
#   filter(value != -99) %>% 
#   mutate(
#     value = value * us_cattle_weight[[1]]
#   )
# 
# 

meat_prices_df <- meat_prices_df %>% 
    left_join(select(cat_mappings, fao_prices, fao_tcf) %>% 
                rename(animal = fao_prices), by = c('animal')
    ) %>% 
   select(-animal) %>% 
  rename(animal = fao_tcf) %>% 
    left_join(fao_conversion_df, by = c('iso3c', 'animal')) %>%
      mutate(
        usd_price_per_head = value * liveweight/1000
      ) 



#############################################
# Important currently not imputing missing categories 
# such as 
#############################################


# Add categories and FAO conversion factors to stock values
as2  <- animal_stock_df %>% 
  left_join(select(cat_mappings, fao_stock, fao_tcf) %>% 
              rename(item = fao_stock)
  ) %>%  
  select(-item) %>% 
  rename(animal = fao_tcf) %>% 
  right_join(meat_prices_df, by = c("iso3c", 'year', 'animal')) %>% 
  drop_na() %>% 
  select(-unit, -value) %>% 
  mutate(
    as2_usd = usd_price_per_head * head
  )
  
## POTENTIAL ISSUE - TCFS NEED TO BE UPDATED
##  BRAZILLIAN CATTLE MAY HAVE GROWN IN SIZE
##  
# > as2[as2$as2_usd == max(as2$as2_usd), ]
# # A tibble: 1 x 7
# year iso3c      head animal liveweight usd_price_per_head       as2_usd
# <dbl> <chr>     <dbl> <chr>       <dbl>              <dbl>         <dbl>
#   1  2011 BRA   212815311 cattle        382              1408. 299687542464.
# 
# 
# 

## 4 - Write to file and delete older versions ------------------------------#

output_file <- file.path(
  'data', 'output',
  paste0(format(Sys.Date(),'%Y%m%d'), 
         '_Scenario_AS2_Value_Of_Animal_Stock.')
)

# Remove earlier versions of this file
output_dir <- file.path('data', 'output')
output_files <- list.files(output_dir)
remove_files <- str_detect(output_files, 
                           '_Scenario_AS2_Value_Of_Animal_Stock.')
file.remove(file.path(output_dir, output_files[remove_files]))


# Write to disk
arrow::write_parquet(as2 ,paste0(output_file, 'parquet'))
readr::write_csv(as2 , file = paste0(output_file, 'csv'))














