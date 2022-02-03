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


