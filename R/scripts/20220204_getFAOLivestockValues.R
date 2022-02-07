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
# Date Created:  20220204
#
# Description:  Computes the total economic value
# for Livestock between 1994 and present from FAOSTAT data
#
####################################


## 0 - Libraries ------------------------------#
library(magrittr)
library(tidyr)
library(stringr)

## 1 - Source ------------------------------#
source(here::here("R", "utils", "FAOSTAT_helper_functions.R"))



## 2 - Params to use throughout ------------------------------#
params <- list(
  file_paths = list(
    value_of_production = "Value_of_Production_E_All_Data.parquet",
    production = "Production_Crops_Livestock_E_All_Data.parquet",
    prices = "Prices_E_All_Data.parquet"
  ),
  fao_codes_dir = here::here("data", "codes", "FAOSTAT"),
  use_years = 1994:2019,
  data_dir = here::here("data", "FAOSTAT"),
  conversion_factors = readr::read_csv(here::here("data", "FAOSTAT", "FAOSTAT_LiveWeight_Conversion_Factors.csv"))
)


## 3 - Load in and clean data ------------------------------#

# Load the data
data <- purrr::map(
  params$file_paths,
  ~ arrow::read_parquet(get_gbads_file(.x,
    dir = params$data_dir
  )) %>%
    janitor::clean_names() %>%
    dplyr::filter(year %in% params$use_years) %>%
    clean_countries() %>%
    sanitize_columns()
)


#################################################################
# FAOSTAT Item Codes to Use for each category that will be used
#################################################################
code_rds_files <- grep("ds$", list.files(params$fao_codes_dir, full.names = TRUE), value = TRUE)

# Name files
names(code_rds_files) <- basename(code_rds_files) %>%
  stringr::str_remove_all(".Rds|.rds") %>%
  stringr::str_remove_all("FAOSTAT_")

# Read in the item code data
faostat_item_codes <- purrr::map(
  code_rds_files,
  ~ readRDS(.x) %>%
    janitor::clean_names()
)



# - Uniqe Livestock Codes that will be used
livestock_codes <- unique(
  c(
    faostat_item_codes$Livestock_Codes$item_code,
    faostat_item_codes$`Vop_Items_Non-Indigenous_Codes`$item_code,
    faostat_item_codes$Meat_Live_Weight_Codes$item_code,
    faostat_item_codes$Livestock_Meat_Item_Codes$item_code
  )
)



# Extract the Livestock Data  and match countries
livestock <- purrr::map(
  data,
  ~ filter(.x, item_code %in% livestock_codes)
)
livestock$prices <- filter(livestock$prices, months_code == 7021)



#################################################################
# Compute Animal Yield
#
# This is in dressing percentage and will need to be converted to Live Weight Equivalent
# This is different across countries and animals in how it is reported,
# however, we will assume that this is the true carcass yield for all animals.
#################################################################
livestock$yield <- livestock$production %>%
  filter(
    element %in% c("producing_animals_slaughtered", "production"),
    item_code %in% unique(faostat_item_codes$Livestock_Meat_Item_Codes$item_code)
  ) %>%
  mutate(
    value = case_when(
      stringr::str_detect(unit, "1000") ~ value * 1000,
      TRUE ~ value
    ),
    unit = case_when(
      stringr::str_detect(unit, "1000") ~ "head",
      TRUE ~ unit
    )
  ) %>%
  select(-element, -element_code, -flag, -year_code) %>%
  tidyr::spread(unit, value) %>%
  mutate(
    yield_kg = round(tonnes * 1000 / head, 1)
  ) %>%
  drop_na(yield_kg)


#################################################################
# Use Yield to compute Live Body Weights
#
# Will Impute later - Based on Regional Aggregations
#################################################################
carcass_pct <- params$conversion_factors %>%
  mutate(
    animal_en = stringr::str_remove_all(animal_en, "s$"),
    iso3 = tolower(iso3)
  ) %>%
  select(iso3, animal_en, carcass_pct)


livestock$yield <- livestock$yield %>%
  mutate(
    animal_en = trimws(stringr::str_remove(item, "meat_"))
  ) %>%
  left_join(carcass_pct, by = c("iso3_code" = "iso3", "animal_en")) %>%
  group_by(animal_en) %>%
  mutate(carcass_pct = case_when(
    is.na(carcass_pct) ~ mean(carcass_pct, na.rm = TRUE),
    TRUE ~ carcass_pct
  )) %>%
  ungroup() %>%
  mutate(
    lbw_kg = yield_kg * 100 / carcass_pct
  ) %>%
  separate(item, c("item", "animal"), sep = ",", extra = "merge", fill = "left") %>%
  mutate(
    animal = trimws(animal),
    item = "stock"
  ) %>%
  select(-head, -tonnes, -animal_en)



#################################################################
# Create Livestock Table With Weights values and prices
#  - Use nested tibble data frames
#################################################################

livestock$value_of_production <- livestock$value_of_production %>%
  select(-element_code, -year_code, -unit, -flag) %>%
  spread(element, value) %>%
  separate(item, c("item", "animal"), sep = "_", extra = "merge", fill = "left") %>%
  mutate(
    animal = trimws(animal),
    item = tolower(item)
  )

livestock$production <- livestock$production %>%
  filter(element %in% c("stocks", "producing_animals_slaughtered", "production")) %>%
  mutate(
    value = case_when(
      stringr::str_detect(unit, "1000") ~ value * 1000,
      TRUE ~ value
    ),
    unit = case_when(
      stringr::str_detect(unit, "1000") ~ "head",
      TRUE ~ unit
    )
  ) %>%
  select(-element, -element_code, -year_code, -flag) %>%
  mutate(
    item = tolower(item)
  ) %>%
  separate(item, c("item", "animal"), sep = "_", extra = "merge", fill = "left") %>%
  mutate(
    animal = trimws(animal)
  ) %>%
  spread(unit, value) %>%
  replace_na(list(item = "stock"))

livestock$prices <- livestock$prices %>%
  select(-element_code, -year_code, -unit, -flag, -months, -months_code, -unit) %>%
  separate(item, c("item", "animal"), sep = "_", extra = "merge", fill = "left") %>%
  mutate(
    animal = trimws(animal)
  ) %>%
  spread(element, value) %>%
  mutate(
    item = case_when(
      str_detect(item, "live_weight") ~ "stock",
      TRUE ~ item
    ),
    item = tolower(item)
  ) %>%
  filter(animal != "meat_nes")


# Stock Item Code is first
# Price Items second,
# Yield Items third
match_live_weight_items <- list(
  cattle = c(866, 945, 867),
  buffalo = c(946, 973, 947),
  sheep = c(976, 1013, 977),
  goat = c(1016, 1033, 1017),
  pig = c(1034, 1056, 1035),
  chicken = c(1057, 1095, 1058),
  duck = c(1068, 1071, 1069),
  goose = c(1072, 1078, 1073),
  turkey = c(1079, 1088, 1080),
  horse = c(1096, 1121, 1097),
  ass = c(1107, 1123, 1108),
  mule = c(1110, 1125, 1111),
  camel = c(1126, 1138, 1127),
  rabbit = c(1140, 1145, 1141)
)
matches <- setNames(data.frame(t(as_tibble(match_live_weight_items))), c("stock_code", "price_code", "yield_code"))

# Switch Stock item codes and names
stock_id <- livestock$prices$item == "stock"
livestock$prices$item_code[stock_id] <- plyr::mapvalues(livestock$prices$item_code[stock_id],
  from = matches$price_code,
  to = matches$stock_code
)

# Match stock animal
# stock_id <- livestock$fao_production$item == 'stock'
livestock$production$animal <- plyr::mapvalues(livestock$production$animal,
  from = c(
    "cattle", "buffaloes", "sheep", "goats", "pigs", "chickens", "ducks",
    "goose and guinea_fowl", "turkeys", "horses", "asses", "mules", "camels", "rabbits and hares"
  ),
  to = rownames(matches)
)
livestock$value_of_production$animal <- plyr::mapvalues(livestock$value_of_production$animal,
  from = c(
    "cattle", "buffaloes", "sheep", "goats", "pigs", "chickens", "ducks",
    "goose and guinea_fowl", "turkeys", "horses", "asses", "mules", "camels", "rabbits and hares"
  ),
  to = rownames(matches)
)



livestock$yield$item_code <- plyr::mapvalues(livestock$yield$item_code,
  from = matches$yield_code,
  to = matches$stock_code
)

livestock$yield$animal <- plyr::mapvalues(livestock$yield$animal,
  from = c(
    "cattle", "buffaloes", "sheep", "goats", "pigs", "chickens", "ducks",
    "goose and guinea_fowl", "turkeys", "horses", "asses", "mules", "camels", "rabbits and hares"
  ),
  to = rownames(matches)
)


#################################################################
# Match the Live Weight Price Item Codes to the stock items
#################################################################
livestock_df <- purrr::reduce(livestock, full_join)
livestock_df$animal <- gsub("whole_fresh", "", livestock_df$animal)
livestock_df$animal <- gsub("edible,", "", livestock_df$animal)
livestock_df$animal <- gsub("edible", "", livestock_df$animal)
livestock_df$animal <- gsub(",$", "", livestock_df$animal)
livestock_df$animal <- trimws(livestock_df$animal)
livestock_df$animal <- plyr::mapvalues(livestock_df$animal,
  from = c(
    "cattle", "buffaloes", "sheep", "goats", "pigs", "chickens", "ducks",
    "goose and guinea_fowl", "turkeys", "horses", "asses", "mules", "camels", "rabbits and hares"
  ),
  to = rownames(matches)
)

livestock_df$animal <- plyr::mapvalues(livestock_df$animal,
  from = c("cow", "geese", "eggs_hen_in_shell"),
  to = c("cattle", "goose", "chicken")
)




#################################################################
# Impute Live Weights to get Values of Animal Stock
#
# If carcass % is outside the middle 80% set to the median
# with that amount removed
#################################################################
livestock_df <- livestock_df %>%
  group_by(animal) %>%
  mutate(
    q10_carcass_pct = quantile(carcass_pct, 0.1, na.rm = TRUE),
    q90_carcass_pct = quantile(carcass_pct, 0.9, na.rm = TRUE)
  ) %>% # TODO: Remove around 80 percentiles
  mutate(
    lbw_kg = case_when(
      item == "stock" && is.na(lbw_kg) ~ median(lbw_kg, na.rm = TRUE),
      TRUE ~ lbw_kg
    )
  ) %>%
  ungroup() %>%
  select(-contains("_carcass_pct"))


#################################################################
# Compute Livestock Stock Values
#################################################################

livestock_df <- livestock_df %>%
  mutate(
    tonnes = case_when(
      is.na(tonnes) ~ lbw_kg * head / 1000,
      TRUE ~ tonnes
    ),
    stock_value_lcu = ifelse(item == "stock", producer_price_lcu_tonne * tonnes, 0),
    stock_value_slc = ifelse(item == "stock", producer_price_slc_tonne * tonnes, 0),
    stock_value_usd = ifelse(item == "stock", producer_price_usd_tonne * tonnes, 0)
  )

# Get in Constant Dollars
exchange_rates <- arrow::read_parquet(get_gbads_file("Exchange_rate_E_All_Data.parquet", dir = here::here("data", "FAOSTAT"))) %>%
  janitor::clean_names() %>%
  select(area_code, year, value)

mean_usd_prices_2014_2016 <- filter(livestock_df, year %in% 2014:2016) %>%
  ungroup() %>%
  select(iso3_code, faost_code, item_code, year, producer_price_slc_tonne) %>%
  left_join(exchange_rates, by = c("faost_code" = "area_code", "year")) %>%
  group_by(iso3_code, item_code) %>%
  summarise(
    mean_slc_price_per_tonne_2014_2016 = mean(producer_price_slc_tonne, na.rm = TRUE),
    mean_usd_conversion_2014_2016 = mean(value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    producer_price_usd_per_tonne_2014_2016 = mean_slc_price_per_tonne_2014_2016 / mean_usd_conversion_2014_2016
  )

livestock_df <- livestock_df %>%
  left_join(mean_usd_prices_2014_2016) %>%
  mutate(
    stock_value_constant_2014_2016_usd = ifelse(item == "stock", producer_price_usd_per_tonne_2014_2016 * tonnes, 0)
  )



##  - Attach metadata  ------------------------------#
livestock_table <- arrow::Table$create(livestock_df %>%
  relocate(head, tonnes, .before = contains("gross")) %>%
  relocate(year, .before = item_code))


livestock_table$metadata <- list(
  iso3_code = "ISO 3166-1 alpha-3",
  faost_code = "FAOSTAT Area Code",
  area = "FAOSTAT Area Name",
  year = "Year in YYYY format",
  item_code = "FAOSTAT item code",
  item = "FAOSTAT production item name (lowercase)",
  animal = "english name for livestock type",
  head = "Number of animals",
  tonnes = "Metric Tonnes",
  gross_production_value_constant_2014_2016_thousand_i = "Gross production value of item in constant thousand 2014 2016 international dollars, for a certain item calculated to average 100 between 2014 and 2016",
  gross_production_value_constant_2014_2016_thousand_slc = "Gross production value of item in constant 2014 2016 in thousand standard local currency units, for a certain item calculated to average 100 between 2014 and 2016",
  gross_production_value_constant_2014_2016_thousand_us = "Gross production value of item in constant thousand 2014 2016 US dollars,  for a certain item calculated to average 100 between 2014 and 2016",
  gross_production_value_current_thousand_slc = "Gross production value of item in current thousand   standard local currency units, for a certain item calculated to average 100 between 2014 and 2016",
  gross_production_value_current_thousand_us = "Gross production value of item in current thousand US dollars",
  producer_price_index_2014_2016_100 = "An FAOSTAT Items producer price index, for a certain item calculated to average 100 between 2014 and 2016",
  producer_price_lcu_tonne = "Producer price of item in local currency per tonne",
  producer_price_slc_tonne = "Producer price of item in national currency per tonne",
  producer_price_usd_tonne = "Producer price of item in current USD per tonne",
  yield_kg = "Animal yield/carcass weight calculated from FAOSTAT data",
  carcass_pct = "FAO carcass % conversion factor",
  lbw_kg = "Adult live body weight equivalent in kg, calculated via yield_kg/(carcass_pct/100)",
  stock_value_lcu = "Value of animal stock in local currency units, calculated via producer_price_lcu_tonne * tonnes",
  stock_value_slc = "Value of animal stock in standard currency units, calculated via producer_price_slc_tonne * tonnes",
  stock_value_usd = "Value of animal stock in US dollars, calculated via producer_price_usd_tonne * tonnes",
  mean_slc_price_per_tonne_2014_2016 = "mean slc price per tonne averaged over 2014 to 2016",
  mean_usd_conversion_2014_2016 = "Mean conversion of slc to US dollars from  2014 to 2016 using the annual exchange rantes",
  producer_price_usd_per_tonne_2014_2016 = "Producer price per tonne in USD, calculated via mean_slc_price_per_tonne_2014_2016 / mean_usd_conversion_2014_2016",
  stock_value_constant_2014_2016_usd = "Value of animal stock in constant 2014 2016 US dollars, calculated via producer_price_usd_per_tonne_2014_2016 * tonnes",
  date = iso_date(),
  contributor = "Gabriel Dennis CSIRO, gabriel.dennis@csiro.au",
  format = "Arrow Table",
  language = "English",
  source = paste("[FAO.] Crops and livestock products.[Accessed 2022-01-28.] https://fenixservices.fao.org/faostat/static/bulkdownloads/Production_Crops_Livestock_E_All_Data_(Normalized).zip",
    "[FAO.] Value of Agricultural Production.[Accessed 2022-01-28.]https://fenixservices.fao.org/faostat/static/bulkdownloads/Value_of_Production_E_All_Data_(Normalized).zip",
    "[FAO.] Prices: Producer Prices.[Accessed 2022-01-28.] http://fenixservices.fao.org/faostat/static/bulkdownloads/Prices_E_All_Data_(Normalized).zip",
    sep = " -  - "
  )
)




##  - Write to file  ------------------------------#
arrow::write_parquet(
  livestock_table,
  file_name("FAOSTAT", c("Livestock", "Values"))
)
