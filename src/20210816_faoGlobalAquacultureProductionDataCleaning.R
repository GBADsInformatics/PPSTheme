####################################
# Creator: Gabriel Dennis 
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210827
# 
# File Description:  This script reads in the data from FAO Fisheries  Global
# Aquaculture Production Database - Downloaded on the 20210716
# This database contains values in 1000 Current USD on the production
# value of aquaculture. 
# 
# This script codes each country in the database from a UN code to an iso3c
# and codes each species to CPC_Group_En code groupings using 
# CL_FI_SPECIES_GROUPS.csv
# The un to iso3c coding is available in 
# the csv CL_FI_COUNTRY_GROUPS.csv
####################################


## 0 - Load the Libraries
library(dplyr)
library(magrittr)
library(tidyr)
library(stringr)



## 1 - Import the data
data_folder <- file.path(
  'data', 'raw', '20210716_FAO_Global_Aquaculture_Production'  # Change to latest file
)

# Files to use
data_file <- 'AQUACULTURE_VALUE.csv'
iso3codes_file <- 'CL_FI_COUNTRY_GROUPS.csv'
CPC_Group_En_file <- 'CL_FI_SPECIES_GROUPS.csv'

# Production data
aqua_production_df <- readr::read_csv(
  file.path(data_folder, data_file), 
  col_select = c("COUNTRY.UN_CODE", "SPECIES.ALPHA_3_CODE", "PERIOD", "VALUE"), 
  col_types = "icdd"
) %>% 
  rename_with(
    tolower
) %>% 
  rename(un_code = country.un_code, 
         alpha_3_code = species.alpha_3_code, 
         year = period)

# iso3 codes
iso3codes_df <- readr::read_csv(
  file.path(data_folder, iso3codes_file), 
  col_select = c("UN_Code", "ISO3_Code"), 
  col_types = "ii"
)  %>% 
  rename_with(
    tolower
  ) %>% 
  rename(
    iso3c = iso3_code
  )


# CPC_Group_Encodes
groups_df <- readr::read_csv(
  file.path(data_folder, CPC_Group_En_file),
  col_select = c("3A_Code", "CPC_Group_En"),
  col_types = "cc"
)  %>%  rename(alpha_3_code = `3A_Code`, 
         group = CPC_Group_En) %>% 
 separate(
   group, c('grouping', 'misc'), sep = ' ', remove = FALSE
 ) %>% 
  mutate(
    group = tolower(if_else(!str_detect(grouping, 'Other'), str_remove_all(grouping, ','), group))
  ) %>% 
  select(-grouping, -misc)



##  2 - Code the data to ISO3C and CPC_Group_En
aqua_production_df <- aqua_production_df %>% 
  left_join(iso3codes_df, by = "un_code") %>% 
  left_join(groups_df, by = "alpha_3_code") %>% 
  mutate(unit = "1000_usd") %>% 
  select(iso3c, group, year, unit, value) %>% 
  group_by(iso3c, group, year, unit) %>% 
  summarise(value = sum(value, na.rm = TRUE)) %>% 
  filter(value > 0) %>% 
  ungroup()




## 3 - Write to file
output_file <- file.path(
  'data', 'output',
  paste0(format(Sys.Date(),'%Y%m%d'), 
         '_FAO_Fisheries_Global_Aquaculture_Production_Values.')
)

# Remove earlier versions of this file
output_dir <- file.path('data', 'output')
output_files <- list.files(output_dir)
remove_files <- str_detect(output_files, 
                           '_FAO_Fisheries_Global_Aquaculture_Production_Values')
file.remove(file.path(output_dir, output_files[remove_files]))


# Write to disk
arrow::write_parquet(aqua_production_df,paste0(output_file, 'parquet'))
readr::write_csv(aqua_production_df, file = paste0(output_file, 'csv'))



rm(list = ls())




















