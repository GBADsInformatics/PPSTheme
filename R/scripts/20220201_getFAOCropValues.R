################################################################
#
# Project: GBADS: Global Burden of Animal Disease
#
# Author: Gabriel Dennis 
# 
# Position: Research Technician, CSIRO
#
# Email: gabriel.dennis@csiro.au
#
# CSIRO ID: den173
#
# GitHub ID: denn173
#
# Date Created:  20220201  
# 
# Description:  Generates Crop values 
# parquet file for analysis. 
# 
# Inputs: /data/FAOSTAT/*_Production_Crops_Livestock_E_All_Data.parquet
#  
# Outputs: /data/output/FAOSTAT/*_FAOSTAT_Crop_Values.parquet
####################################


## 0 - Libraries  ------------------------------#
pks <- c('here', 'purrr', 'dplyr', 'tidyr',
         'arrow', 'janitor', 'stringr')
sapply(pks, require, character.only = TRUE)


## 1 - Source Files  ------------------------------#
source(here('src', 'utils', 'FAOSTAT_helper_functions.R'))


## 2 - Set Global Variables ------------------------------#
params <- list(
codes_directory =  here('data', 'codes', 'FAOSTAT'), 
years_to_use  =  1994:2019, 
file_names = list(
  value_of_production = "Value_of_Production_E_All_Data.parquet", 
  production = "Production_Crops_Livestock_E_All_Data.parquet", 
  prices = "Prices_E_All_Data.parquet")
)

## 2 - FAO Item Codes  ------------------------------#
#################################################################
# The Food groups don't match perfectly
#  - USE the CPC groupings given by
#  https://www.fao.org/fileadmin/templates/ess/classifications/Correspondence_CPCtoFCL.xlsx
#################################################################
food_groups <- tribble(
  ~group, ~code,
  "cereals", "011",
  "vegetables", "012",
  "fruits_nuts", "013",
  "oilseed_oil_fruits", "014",
  "roots_tubers", "015",
  "coffe_spice_crops", "016",
  "pulses", "017",
  "sugar_crops", "018"
)


#################################################################
# FAOSTAT Item Codes to Use for each category that will be used
#################################################################
code_rds_files <- grep("ds$", 
                       list.files(codes_directory, 
                                  full.names = TRUE),
                       value = TRUE)

# Name files
names(code_rds_files) <- basename(code_rds_files) %>%
  str_remove_all(".Rds|.rds") %>%
  str_remove_all("FAOSTAT_")

# Read in the item code data
faostat_item_codes <- purrr::map(
  code_rds_files,
  ~ readRDS(.x) %>%
    janitor::clean_names()
)

#################################################################
# Need to check further how to avoid double counting
#  - Keep as is for now as it seems that the separate codes 
#    remove the issues of double counting 
#################################################################
crop_groups <- faostat_item_codes$Item_Codes %>%
  filter(domain_code == "QCL") %>%
  select(item, item_code, cpc_code) %>%
  mutate(
    item_group = substr(cpc_code, start = 1, stop = 3)
  ) %>%
  filter(item_group %in% food_groups$code) %>%
  left_join(food_groups, by = c("item_group" = "code")) %>%
  select(item_code, group)


## 4 - Generate Crop Value Table  ------------------------------#

# Load the data 
data <- purrr::map(params$file_names,
                   ~arrow::read_parquet(get_gbads_file( .x, 
                                                        dir = here::here('data', 'FAOSTAT'))) %>% 
                     janitor::clean_names() %>% 
                     filter(year %in% params$years_to_use, 
                            item_code %in% unique(crop_groups$item_code)
                            ) %>% 
                     clean_countries() %>% 
                     sanitize_columns())




crops <- purrr::map(
  data,
  ~ filter(.x, item_code %in% unique(crop_groups$item_code)) %>% 
    select(-year_code) %>% 
    left_join(crop_groups) %>% 
    relocate(group, .after = item)
)

# Filter specific things
crops$production <- filter(crops$production, element == "production")
crops$prices <- filter(crops$prices, months_code == 7021)


# Spread each table
crops$value_of_production <- crops$value_of_production %>%
  select(-element_code,  -unit, -flag) %>%
  spread(element, value)

crops$production <- crops$production %>%
  select(-element_code, -flag, -element, -unit) %>%
  rename(tonnes = value)

crops$prices <- crops$prices %>%
  select(-element_code,-months_code, -months, -unit, -flag) %>%
  spread(element, value)

crop_df <- purrr::reduce(crops[c('production', 'prices', 'value_of_production')], 
                         full_join)

# Convert to a Arrow table 
crop_table <- arrow::Table$create(crop_df)


# Add initial metadata 
crop_table$metadata <- list(
  iso3_code = "ISO 3166-1 alpha-3", 
  faost_code = "FAOSTAT Area Code", 
  area = "FAOSTAT Area Name", 
  year = "Year in YYYY format", 
  tonnes = "Metric Tonnes", 
  producer_price_index_2014_2016_100 =  "An FAOSTAT Items producer price index, for a certain item calculated to average 100 between 2014 and 2016", 
  producer_price_lcu_tonne = 'Producer price of item in local currency per tonne', 
  producer_price_slc_tonne = 'Producer price of item in national currency per tonne', 
  producer_price_usd_tonne = 'Producer price of item in current USD per tonne', 
  gross_production_value_constant_2014_2016_thousand_i = 'Gross production value of item in constant thousand 2014 2016 international dollars, for a certain item calculated to average 100 between 2014 and 2016', 
  gross_production_value_constant_2014_2016_thousand_slc = 'Gross production value of item in constant 2014 2016 in thousand standard local currency units, for a certain item calculated to average 100 between 2014 and 2016', 
  gross_production_value_constant_2014_2016_thousand_us = 'Gross production value of item in constant thousand 2014 2016 US dollars,  for a certain item calculated to average 100 between 2014 and 2016',  
  gross_production_value_current_thousand_slc = 'Gross production value of item in current thousand   standard local currency units, for a certain item calculated to average 100 between 2014 and 2016', 
  gross_production_value_current_thousand_us = 'Gross production value of item in current thousand US dollars' , 
  date = iso_date(), 
  contributor = 'Gabriel Dennis CSIRO, gabriel.dennis@csiro.au', 
  format = 'Arrow Table', 
  language = 'English', 
  source = '[FAO.] [Database Title.] [Dataset Title.] [Latest update: Day/month/year.] [(Accessed [Day/month/year).] [URL or URI]'
)


## 5 - Write to file ------------------------------#

arrow::write_parquet(crop_table,
                     file_name("FAOSTAT",
                               tags = c("Crop", "Values")))





