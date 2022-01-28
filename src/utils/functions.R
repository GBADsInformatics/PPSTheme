####################################
# Creator: Gabriel Dennis
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20213108
#
# File Description: This file the helper
# functions which are used in the targets pipeline
####################################

require(FAOSTAT)

source(here::here('src','utils',  'FAOSTAT_helper_functions.R'))
## 0 - function to read in fao data ------------------------------#


#' get_fao_vop_data
#'
#' Imports data from a FAOSTAT table. Currently data is input via bulk download.
#'
#' @param code the FAOSTAT table code to access
#'
#' @return a data frame with columns
#'  area_code::dbl, item_code::dbl, item::char, element::char, element_code::dbl,
#'  year::dbl, unit::char, value::dbl, flag::char
get_fao_data <- function(code) {
  require(magrittr)
  require(dplyr)
  require(stringr)
  require(FAOSTAT)
  require(lubridate)

 # tmp_dir <- tempdir()
  # Change to using Curl
  #data <- get_faostat_bulk(code, tmp_dir) %>%
  #  rename_with(function(x) tolower(str_replace_all(x, "//s", "_")))

  data <- arrow::read_parquet(here::here('data', 'temp', '20210111_Value_of_Production_E_All_Data_(Normalized).parquet')) %>%
    rename_with(~tolower(str_replace_all(.x, " ", "_")))

  column_names <- c(
    "area_code","area",  "item_code", "item",
    "element", "element_code", "year",
    "unit", "value", "flag"
  )

  if (length(setdiff(column_names, names(data))) > 0) {
    stop(paste0("Table: has incorrect column names : ", names(data)))
  }

  data %>%
    select(one_of(column_names)) %>%
    mutate_at(c("area_code", "item_code", "element_code", "value"), as.numeric) %>%
    mutate_at(c("unit", "flag"), as.character) %>%
    mutate_at(c("year"), ~ isoyear(as.Date(as.character(.x), format = "%Y")))
}


## 2 - functions to clean fao data  ------------------------------#


#  clean_fao_VOP_animal_outputs
#'
#' Cleans the FAO QV Value of Agricultural Production table,
#' this is done by extracting all items which contain "meat|milk|egg"
#' and filtering out items which contain 'total', 'meat nes'
#'
#'
#' @param data data.frame with columns
#' area_code, item_code, item, element, element_code, year, unit, value, flag
#'
#' @param start_year year to filter data afterwards, defaults to 1991
#'
#' @return data.frame with columns iso3c, livestock, livestock_item,
#'                                 year, value_usd, value_tonne
clean_fao_VOP_animal_outputs <- function(data, start_year = 1991) {
  require(magrittr)
  require(dplyr)
  require(stringr)
  library(tidyr)
  require(countrycode)
  require(FAOSTAT)

  # regex patterns
  # TODO: Change to capturing CPC codes
  filter_in <- regex("meat|milk|eggs",
    ignore_case = TRUE
  )
  filter_out <- regex("meat nes|total", ignore_case = TRUE)
  rm_str <- regex("whole fresh", ignore_case = TRUE)

  # Element to filter for
  # Gross Production Value (current thousand SLC)      56
  # Gross Production Value (current thousand US$)      57
  #element_filter <- c(56, 57)
  element_filter <- c(58)

  # Items to filter for
  # meat, non indigenous - Values
  # "Meat, cattle"                "Meat, buffalo"               "Meat, sheep"
  # "Meat, goat"                  "Meat, pig"                   "Meat, chicken"
  # "Meat, duck"                  "Meat, goose and guinea fowl" "Meat, turkey"
  # "Meat, bird nes"              "Meat, horse"                 "Meat, ass"
  # "Meat, mule"                  "Meat, camel"                 "Meat, rabbit"
  # "Meat, other rodents"         "Meat, other camelids"        "Meat, game"
  meat_codes <- c(
    867, 947, 977, 1017, 1035, 1058, 1069, 1073, 1080, 1089,
    1097, 1108, 1111, 1127, 1141, 1151, 1158, 1163
  )




  # "Milk, whole fresh cow"     "Milk, whole fresh buffalo"
  # "Milk, whole fresh sheep"   "Milk, whole fresh goat"
  #  "Milk, whole fresh camel"
  milk_codes <- c(82, 951, 982, 1020, 1130)

  # "Eggs, hen, in shell"        "Eggs, other bird, in shell"
  egg_codes <- c(1062, 1091)

  # Filter and code data
  data <- data %>%
    filter( # Filter for year and product and element
      year > start_year,
      str_detect(item, filter_in),
      !str_detect(item, filter_out),
      element_code %in% element_filter,
      item_code %in% c(meat_codes, milk_codes, egg_codes)
    ) %>%
    add_country_codes(area_code,area) %>%
    #filter(!is.na(ISO3_CODE)) %>%
    # Remove missing regions (just aggregates)
    rename_with(~tolower(.x)) %>%
    select(iso3_code, year, item, element, value)



  # Split item into livestock, livestock_item
  data <- data %>%
    separate(item, c("livestock_item", "livestock"), sep = ",") %>%
    mutate_at(vars(livestock), ~ trimws(str_remove_all(.x, rm_str))) %>%
    mutate_at(vars(livestock_item), ~ tolower(gsub("\\s", "_", .x)))
}



#' Cleans the FAO global production data set
#' and places it in the same format as the vop table
#'
#' @return data.frame with columns
clean_global_aquaculture_data_values <- function() {
  # TODO:FIX THIS
  ## 0 - Load the Libraries
  library(dplyr)
  library(magrittr)
  library(tidyr)
  library(stringr)



  ## 1 - Import the data
  data_folder <- file.path(
    "data", "raw", "20210716_FAO_Global_Aquaculture_Production" # Change to latest file
  )

  # Files to use
  data_file <- "AQUACULTURE_QUANTITY.csv"
  iso3codes_file <- "CL_FI_COUNTRY_GROUPS.csv"
  CPC_Group_En_file <- "CL_FI_SPECIES_GROUPS.csv"

  # Production data
  aqua_production_df <- readr::read_csv(
    file.path(data_folder, data_file),
    col_select = c("COUNTRY.UN_CODE", "SPECIES.ALPHA_3_CODE", "PERIOD", "VALUE"),
    col_types = "icdd"
  ) %>%
    rename_with(
      tolower
    ) %>%
    rename(
      un_code = country.un_code,
      alpha_3_code = species.alpha_3_code,
      year = period
    )

  # iso3 codes
  iso3codes_df <- readr::read_csv(
    file.path(data_folder, iso3codes_file),
    col_select = c("UN_Code", "ISO3_Code"),
    col_types = "ii"
  ) %>%
    rename_with(
      tolower
    )

  # CPC_Group_Encodes
  groups_df <- readr::read_csv(
    file.path(data_folder, CPC_Group_En_file),
    col_select = c("3A_Code", "CPC_Group_En"),
    col_types = "cc"
  ) %>%
    rename(
      alpha_3_code = `3A_Code`,
      group = CPC_Group_En
    ) %>%
    separate(
      group, c("grouping", "misc"),
      sep = " ", remove = FALSE
    ) %>%
    mutate(
      group = tolower(if_else(!str_detect(grouping, "Other"),
        str_remove_all(grouping, ","), group
      ))
    ) %>%
    select(-grouping, -misc)



  ##  2 - Code the data to ISO3C and CPC_Group_En
  aqua_production_df <- aqua_production_df %>%
    left_join(iso3codes_df, by = "un_code") %>%
    left_join(groups_df, by = "alpha_3_code") %>%
    mutate(unit = "tonnes") %>%
    select(iso3_code, group, year, unit, value) %>%
    group_by(iso3_code, group, year, unit) %>%
    summarise(
      live_weight = sum(value, na.rm = TRUE) ,
      .groups = "drop"
    ) %>%
    filter(live_weight > 0)

  return(select(aqua_production_df, iso3_code, year, group, live_weight))
}

clean_global_aquaculture_data <- function() {
  # TODO:FIX THIS
  ## 0 - Load the Libraries
  library(dplyr)
  library(magrittr)
  library(tidyr)
  library(stringr)



  ## 1 - Import the data
  data_folder <- file.path(
    "data", "raw", "20210716_FAO_Global_Aquaculture_Production" # Change to latest file
  )

  # Files to use
  data_file <- "AQUACULTURE_VALUE.csv"
  iso3codes_file <- "CL_FI_COUNTRY_GROUPS.csv"
  CPC_Group_En_file <- "CL_FI_SPECIES_GROUPS.csv"

  # Production data
  aqua_production_df <- readr::read_csv(
    file.path(data_folder, data_file),
    col_select = c("COUNTRY.UN_CODE", "SPECIES.ALPHA_3_CODE", "PERIOD", "VALUE"),
    col_types = "icdd"
  ) %>%
    rename_with(
      tolower
    ) %>%
    rename(
      un_code = country.un_code,
      alpha_3_code = species.alpha_3_code,
      year = period
    )

  # iso3 codes
  iso3codes_df <- readr::read_csv(
    file.path(data_folder, iso3codes_file),
    col_select = c("UN_Code", "ISO3_Code"),
    col_types = "ii"
  ) %>%
    rename_with(
      tolower
    )

  # CPC_Group_Encodes
  groups_df <- readr::read_csv(
    file.path(data_folder, CPC_Group_En_file),
    col_select = c("3A_Code", "CPC_Group_En"),
    col_types = "cc"
  ) %>%

# Inputs:
   rename(
      alpha_3_code = `3A_Code`,
      group = CPC_Group_En
    ) %>%
    separate(
      group, c("grouping", "misc"),
      sep = " ", remove = FALSE
    ) %>%
    mutate(
      group = tolower(if_else(!str_detect(grouping, "Other"),
                              str_remove_all(grouping, ","), group
      ))
    ) %>%
    select(-grouping, -misc)


  ##  2 - Code the data to ISO3C and CPC_Group_En
  aqua_production_df <- aqua_production_df %>%
    left_join(iso3codes_df, by = "un_code") %>%
    left_join(groups_df, by = "alpha_3_code") %>%
    mutate(unit = "1000_usd") %>%
    select(iso3_code, group, year, unit, value) %>%
    group_by(iso3_code, group, year, unit) %>%
    summarise(
      value_usd = sum(value, na.rm = TRUE) * 1000,
      .groups = "drop"
    ) %>%
    filter(value_usd > 0)

  return(select(aqua_production_df, iso3_code, year, group, value_usd))
}
## 3 - Conversion Functions  ------------------------------#


#' Converts Vop data in SLC to current USD.
#'
#' @param data a data frame with a iso3, year,  values, and element column
#' @param values name of values column
#' @param element name of element column
#' @param multipler multiplier to convert to usd default to 1000
#'
#' @return data frame with element = current_usd
convert_to_current_usd <- function(data, multiplier = 1000) {
  check_vars <- c("iso3_code", "year", "element", "value")
  if (!all(check_vars %in% names(data))) {
    stop("Incorrect column names to convert to USD")
  }
  require(stringr, quietly = TRUE)
  require(wbstats, quietly = TRUE)
  require(dplyr, quietly = TRUE)

  # "World Bank staff calculations based on Datastream
  #  and IMF International Finance Statistics data."
  #  Hopefully better than the current IFS data
  usd_exch <- "DPANUSLCU"

  # Currency filter
  currency_filter <- str_detect(
    data$element,
    regex("slc", ignore_case = TRUE)
  )


  slc_data <- data %>%
    filter(currency_filter)

  wb_data <- wb_data(
    country = unique(slc_data$iso3_code),
    indicator = usd_exch,
    start_date = min(slc_data$year),
    end_date = max(slc_data$year),
    return_wide = TRUE,
    freq = "Y"
  ) %>%
    rename(
      iso3_code = iso3c, year = date, usd_exch = DPANUSLCU
    ) %>%
    select(iso3_code, year, usd_exch)

  # Join
  slc_data <- slc_data %>%
    left_join(wb_data, by = c("iso3_code", "year")) %>%
    filter(!is.na(usd_exch)) %>%
    mutate(
      value_usd = value * multiplier / usd_exch
    ) %>%
    select(iso3_code, year, livestock, livestock_item, value_usd)

  data <- mutate(data, value_usd = value * multiplier) # Remove countries with weird values at the moment
  return(bind_rows(data[!currency_filter, names(slc_data)], slc_data))
}




## 3 - Calculation Functions  ------------------------------#

calculate_O1 <- function(vop, aqua) {
  aqua <- rename(aqua, item = group)
  vop <- vop %>%
    unite(item, c("livestock", "livestock_item"), sep = "_")

  return(bind_rows(aqua, vop) %>% rename(usd_value = value_usd, iso3 = iso3_code))
}



calculate_as2 <- function(stocks, prices, prop = 0.8) {

  # Get the proportion of Biomass missing
  # Have to have over 80% to include this country in the final output


  biomass_prop <- right_join(prices, stocks,
    by = c("iso3", "year", "item")
  ) %>%
    mutate(
      has_price = if_else(is.na(price), 0, 1),
      price_weight = weight * stock * has_price,
      total_weight = weight * stock
    ) %>%
    group_by(iso3, year) %>%
    drop_na(stock) %>%
    summarise(
      bio_mass_prop = sum(price_weight, na.rm = TRUE) / sum(total_weight, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(
      bio_mass_prop >= prop
    ) %>%
    unite(id, c("iso3", "year"), sep = "_")


  left_join(prices, stocks, by = c("iso3", "year", "item")) %>%
    unite(id, c("iso3", "year"), sep = "_", remove = FALSE) %>%
    filter(id %in% biomass_prop$id) %>%
    select(-id) %>%
    mutate(usd_value = stock * price) %>%
    select(iso3, year, item, usd_value)
}

calculate_tev <- function(O1, AS2) {
  # Calculate the total economic value
  # Only done for countries which have both O1 values and AS2 values
  O1 <- tidyr::unite(O1, id, c("iso3", "year"), sep = "_", remove = FALSE)
  AS2 <- tidyr::unite(AS2, id, c("iso3", "year"), sep = "_", remove = FALSE)
  id_val <- intersect(O1$id, AS2$id)

  bind_rows(
    O1 %>% filter(id %in% id_val),
    AS2 %>% filter(id %in% id_val)
  ) %>%
    group_by(iso3, year) %>%
    summarise(value = sum(usd_value)) %>%
    drop_na()
}

calculate_tev_sector <- function(O1, AS2) {
  # Calculate the function values by sector
  require(stringr)

  O1 <- tidyr::unite(O1, id, c("iso3", "year"), sep = "_", remove = FALSE)
  AS2 <- tidyr::unite(AS2, id, c("iso3", "year"), sep = "_", remove = FALSE)
  id_val <- intersect(O1$id, AS2$id)

  bind_rows(
    O1 %>% filter(id %in% id_val),
    AS2 %>% filter(id %in% id_val)
  ) %>%
    mutate(
      item = case_when(
        str_detect(item, "cattle|cow") ~ "cattle",
        str_detect(item, "chicken|hen") ~ "chicken",
        str_detect(item, "sheep") ~ "sheep",
        str_detect(item, "pig") ~ "pig"
      )
    ) %>%
    drop_na(item) %>%
    group_by(iso3, year, item) %>%
    summarise(
      value_usd = sum(usd_value),
      .groups = "drop"
    )
}

#---------------------------------------
# Save
save_files <- function(O1, AS2, TEV, TEV_sector) {
  readr::write_csv(O1, "data/O1_Direct_Value_of_Animal_Outputs.csv")
  #dataspice::prep_attributes("data/O1_Direct_Value_of_Animal_Outputs.csv")
  readr::write_csv(AS2, "data/AS2_Value_of_Animal_Stock.csv")
  #dataspice::prep_attributes("data/AS2_Value_of_Animal_Stock.csv")
  readr::write_csv(TEV, "data/Total_Economic_Value_AS2-O1.csv")
  #dataspice::prep_attributes("data/Total_Economic_Value_AS2-O1.csv")
  readr::write_csv(TEV_sector, "data/Total_Economic_Value_AS2-O1_sectors.csv")
  #dataspice::prep_attributes("data/Total_Economic_Value_AS2-O1_sectors.csv")
}
