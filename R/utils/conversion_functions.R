####################################
# Creator: Gabriel Dennis
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210913
#
# File Description:  This file contains functions
# related to accesing data for conversions between
# livestock types, as well as different currencies in calculations of
# both AS2 and O1 data
####################################
require(dplyr)
require(tidyr)
require(magrittr)
require(FAOSTAT)


#-------------------------------------------------------------------------------
# FAO LUs
# get_fao_livestock_weight_conversions <- function(force = FALSE, base = 600) {
#
#   # Downloadst FAO LUS and converts to KG using a base of
#   # A North American Diary Cow Weights 600 KG
#   file_path <- here::here("data", "raw", "FAOSTAT", "LSU_Coeffs_by_Country.csv")
#   if (force | !file.exists(file_path)) {
#     data <- readr::read_csv("http://fenixservices.fao.org/faostat/static/documents/EK/LSU_Coeffs_by_Country.csv")
#     readr::write_csv(data, file_path)
#   } else {
#     data <- readr::read_csv(file_path)
#   }
#
#   data <- data %>%
#     rename_with(~ tolower(gsub(" ", "_", .))) %>%
#     mutate(
#       iso3 = case_when(
#         areacode == 41 ~ "CHN",
#         TRUE ~ countrycode::countrycode(areacode, "fao", "iso3c")
#       ),
#       item = tolower(itemname),
#       value = base * value
#     ) %>%
#     select(iso3, item, value) %>%
#     drop_na(iso3)
# }
#

# Get FAO tcfs

get_fao_livestock_tcfs <- function() {
  # Read in the FAO tcfs and merge them
  # with the FAO lus when missing for a particular country
  data_folder <- here::here("data", "output", "archived")
  data_file <- file.path(
    data_folder,
    grep("liveweight_conversion_factors_IMPUTED.parquet$",
      list.files(data_folder),
      value = TRUE
    )
  )

  tcfs <- arrow::read_parquet(data_file) %>%
    rename(item = animal)
}


#-------------------------------------------------------------------------------

# ------------------------------------------------------------------------------


convert_stocks_to_tcf_categories <- function(stocks, tcfs) {
  stock_items <- c(
    "Asses",
    "Beehives",
    "Buffaloes",
    "Camelids, other",
    "Camels",
    "Cattle",
    "Chickens",
    "Ducks",
    "Geese and guinea fowls",
    "Goats",
    "Horses",
    "Mules",
    "Pigs",
    "Rabbits and hares",
    "Rodents, other",
    "Sheep",
    "Turkeys"
  )

  tcf_items <- c(
    "asses",
    NA,
    "buffaloes",
    "camels",
    "camels",
    "cattle",
    "chickens",
    "ducks",
    "geese",
    "goats",
    "horses",
    "mules",
    "pigs",
    "rabbits",
    "rabbits",
    "sheep",
    "turkeys"
  )


  stocks$item <- plyr::mapvalues(stocks$item, stock_items, tcf_items)
  stocks %>%
    drop_na(item) %>%
    rename(iso3 = iso3_code) %>%
    group_by(iso3, year, item) %>%
    summarise(stock = sum(value, na.rm = TRUE), .groups = "drop") %>%
    select(iso3, year, item, stock) %>%
    left_join(tcfs, by = c("iso3", "item")) %>%
    drop_na(value) %>%
    dplyr::rename(weight = value)
}

convert_to_head_price_using_tcf <- function(prices) {
  price_items <- c(
    "ass",
    "buffalo",
    "camel",
    "camelids, other",
    "cattle",
    "chicken",
    "duck",
    "goat",
    "goose",
    "horse",
    "mule",
    "pig",
    "poultry, other",
    "rabbit",
    "sheep",
    "turkey"
  )

  tcf_items <- c(
    "asses",
    "buffaloes",
    "camels",
    NA,
    "cattle",
    "chickens",
    "ducks",
    "goats",
    "geese",
    "horses",
    "mules",
    "pigs",
    NA,
    "rabbits",
    "sheep",
    "turkeys"
  )


  prices$item <- plyr::mapvalues(prices$item, price_items, tcf_items)
  return(prices)
}


# convert_stocks_to_lu_categories <- function(stocks, lu) {
#   stocks %>%
#     mutate(
#       item = case_when(
#         item == "Cattle" ~ "cattle",
#         item == "Sheep" ~ "sheep",
#         item == "Pigs" ~ "pigs",
#         item == "Chickens" ~ "chickens",
#         item == "Rabbits and hares" ~ "chickens",
#         item == "Turkeys" ~ "chickens",
#         item == "Goats" ~ "goats",
#         item == "Ducks" ~ "chickens",
#         item == "Geese and guinea fowls" ~ "chickens",
#         item == "Horses" ~ "horses",
#         item == "Buffaloes" ~ "buffaloes",
#         item == "Asses" ~ "asses",
#         item == "Mules" ~ "mules",
#         item == "Camels" ~ "camels",
#         item == "Camelids, other" ~ "goats"
#       )
#     ) %>%
#     drop_na(item) %>%
#     group_by(iso3, year, item) %>%
#     summarise(stock = sum(value, na.rm = TRUE), .groups = "drop") %>%
#     select(iso3, year, item, stock) %>%
#     left_join(lu, by = c("iso3", "item")) %>%
#     dplyr::rename(weight = value)
# }

# Convert to FAOSTAT conversion factors categories


# ------------------------------------------------------------------------------
# FAO Meat Prices

# get_fao_meat_liveweight_prices <- function(force = FALSE) {
#
#
#
#   if (force) {
#     data <- FAOSTAT::get_faostat_bulk("PP", "data/raw/FAOSTAT")
#   } else {
#     data <- readr::read_csv("./data/raw/FAOSTAT/Prices_E_All_Data_(Normalized).zip")
#   }
#
#
#   item_codes <- c(
#     945, 973, 1013, 1033, 1056,
#     1071, 1078, 1085,
#     1088, 1095, 1121, 1123, 1125,
#     1138, 1145, 1155, 1162
#   )
#
#
#
#   data <- data %>%
#     rename_with(~ tolower(gsub(" ", "_", .))) %>%
#     filter(
#       months_code == 7021,
#       item_code %in% item_codes,
#       element_code %in% 5530:5532
#     ) %>%
#     select(area_code, year, item_code, item, unit, value) %>%
#     mutate(
#       unit = factor(unit, levels = c("USD", "SLC", "LCU"))
#     ) %>%
#     group_by(
#       area_code, year, item_code, item,
#     ) %>%
#     arrange(unit) %>%
#     summarise(
#       unit = first(unit),
#       value = first(value),
#       .groups = "drop"
#     ) %>%
#     mutate(
#       iso3 = countrycode::countrycode(area_code, "fao", "iso3c", warn = FALSE)
#     ) %>%
#     drop_na(iso3) %>%
#     separate(item, c("drop", "item"), sep = ",") %>%
#     mutate(item = trimws(item)) %>%
#     select(iso3, year, item, unit, value) %>%
#     filter(unit == "USD") # TODO: DROP LATER
#   return(data)
#   # > filter(data, unit != 'USD') %>%  count(iso3)
#   # # A tibble: 7 x 2
#   # iso3      n
#   # <chr> <int>
#   #   1 AFG      26
#   # 2 CHN       8
#   # 3 CUB     110
#   # 4 IRQ      24
#   # 5 MMR     128
#   # 6 SYR      58
#   # 7 ZWE      55
# }
