####################################
# Creator: Gabriel Dennis 
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210827
# 
# File Description:  This script calculates Scenario O1
# the value of direct livestock and Aquaculture outputs in USD. 
# 
# This is done using the tables 
#  - data/output/{date}_FAOSTAT_Livestock_ValueOfProduction_USD
#  - data/outout/{date}_FAO_Fisheries_Global_Aquaculture_Production_Values
#  
# The output of this script is the table
#  - data/output/{date}_Scenario_O1_Value_Of_Direct_Outputs
####################################

## 0 - Libraries
library(dplyr)
library(tidyr)
library(magrittr)
library(stringr)



## 1 - Import tables

# Locations of folders
data_folder <- file.path('data', 'output')
data_file_list <- list.files(data_folder)

# Get the latest file written to disk
livestock_data <- sort(data_file_list[str_detect(data_file_list, 
                      "FAOSTAT_Livestock_ValueOfProduction_USD.parquet")],
                       decreasing = FALSE)[[1]]
aquaculture_data <- sort(data_file_list[str_detect(data_file_list, 
                      "FAO_Fisheries_Global_Aquaculture_Production_Values.parquet")],
                         decreasing = FALSE)[[1]]

# Import the data
livestock_df <- arrow::read_parquet(file.path(data_folder, livestock_data)) %>% 
  mutate(unit = "1000_usd")

aqua_df <- arrow::read_parquet(file.path(data_folder,aquaculture_data )) %>% 
  filter(year >= min(livestock_df$year)) %>% 
  rename(item = group)



## 2 - Match and bind the two tables
o1 <- livestock_df %>% 
  unite(item, c("animal", "item"), sep = "_",  remove = TRUE) %>% 
  bind_rows(aqua_df) %>% 
  mutate(item = str_remove_all(str_replace_all(item , '\\s', '_'), ','))




## 3 - Write to file
# Remove earlier versions of this file
output_dir <- file.path('data', 'output')
output_files <- list.files(output_dir)
remove_files <- str_detect(output_files, 
                           '_Scenario_O1_Value_Of_Direct_Outputs')
file.remove(file.path(output_dir, output_files[remove_files]))

output_file <- file.path('data', 'output', paste0(format(Sys.Date(),'%Y%m%d'), 
                  '_Scenario_O1_Value_Of_Direct_Outputs.parquet'))

arrow::write_parquet(o1,output_file)


rm(list = ls())


