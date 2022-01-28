####################################
# Creator: Gabriel Dennis
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210913
#
# File Description: This file includes a series of functions
# to load data either from a local source, or from an external API
#
####################################


####################################
# World Bank Population data


# TODO: ADD tests
get_world_bank_population_data <- function(force=FALSE, total=TRUE) {
  #' get_world_bank_population
  #'
  #' @param force whether to force external download
  #' @param total whether to download the total population or rual %
  #'
  #' @return a data frame with columns" iso3c","indicatorID", "indicator", "date","value"
  #' @example
  #' > get_world_bank_population_data(force = TRUE)
  date <- format(Sys.Date(), "%Y%m%d")
  data_type  <- ifelse(total, 'Population', 'Rural-Population')
  indicator <- ifelse(total, 'SP.POP.TOTL', 'SP.RUR.TOTL.ZS')
  data_location <- glue::glue(
    file.path('data', 'raw', 'world-bank',
              '{date}_World-Bank_{data_type}.parquet'))

  if (!force & file.exists(data_location)) {
    return(arrow::read_parquet(data_location))
  }

  pop_data <- wbstats::wb_data(indicator,
                 country = 'countries_only',
                 mrv=30,
                 lang = 'EN')

  assertthat::are_equal(names(pop_data) ,
                        c("iso2c","iso3c","country","date" , indicator, "unit" ,
                          "obs_status", "footnote", "last_updated" ))


  pop_data <- pop_data[, c("iso3c","obs_status", "date",indicator, 'unit')]

  arrow::write_parquet(pop_data, data_location)
  return(pop_data)

}


###############################################################################
# Get FAO livestock stocks
# get_fao_livestock_numbers <- function(force = FALSE) {
#    require(tidyverse, quietly = TRUE, warn.conflicts = FALSE)
#   if (force) {
#     data <- FAOSTAT::get_faostat_bulk('QCL', 'data/raw/FAOSTAT')
#     arrow::write_parquet(data, here::here('data', 'raw', 'FAOSTAT', 'Production_Crops_Livestock_E_All_Data_(Normalized).parquet'))
#   } else{
#     data <- arrow::read_parquet( here::here('data', 'raw', 'FAOSTAT', 'Production_Crops_Livestock_E_All_Data_(Normalized).parquet'))
#   }
#
#
#  data  <-  data %>%
#     select(area_code, item_code, item, element_code, element, year, unit, value) %>%
#     filter(
#       year > 1990,
#       element_code %in% c(5111, 5112, 5114),
#       !(item_code %in% c(1746, 1749, 2029))) %>%
#     mutate(
#       value = case_when(
#         element_code == 5111 ~ value,
#         element_code == 5112 ~ value * 1000,
#         element_code == 5114 ~ value,
#       )
#     ) %>%
#    mutate(
#      iso3 = countrycode::countrycode(area_code, 'fao', 'iso3c')
#    ) %>%
#    drop_na(iso3) %>%
#    select(
#      iso3, item, year, value
#    )
#
# }
#
#
