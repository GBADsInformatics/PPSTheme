####################################
# Creator: Gabriel Dennis
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited:
#
# File Description: This script reads in and cleans data from the World bank
# API on GDP in current USD and SLC to USD conversion rates for all countries
# from 1990 till present
#
#
# Outputs: data/output/{date}_World_Bank_USD_GDP_Exchange_data.parquet'
####################################


## 0 - Import Libraries ------------------------------#

library(wbstats)
library(dplyr)
library(stringr)

## 1 - Import Data ------------------------------#


# World bank indicators
wb_indicators <- wb_indicators(lang = 'en')

# World Development Indicators (World Bank)

gdp_usd <- 'NY.GDP.MKTP.CD'

# "World Bank staff calculations based on Datastream and IMF International Finance Statistics data."
#  Hopefully better than the current IFS data
usd_exch <- 'DPANUSLCU'


wb_data <- wb_data(country = 'all',
              indicator = c(gdp_usd, usd_exch),
              mrv = 30,
              return_wide = TRUE,
              freq = 'Y')


## 2 - Filter for countries not regions ------------------------------#

wb_data <- wb_data %>%
  filter(
    iso3c %in% countrycode::codelist$iso3c
  ) %>%
  rename(
    year = date, gdp_usd = NY.GDP.MKTP.CD, usd_exch = DPANUSLCU
  ) %>%
  select(iso3c, year, gdp_usd, usd_exch)


## 3 - Save to file ------------------------------#
output_dir <- file.path('data', 'output')
output_file <- file.path(output_dir,
                         paste0(format(Sys.Date(), '%Y%m%d'),
                                '_World_Bank_USD_GDP_Exchange_data.parquet'))
file.remove(
  list.files(output_dir)[
    str_detect(list.files(output_dir), 'World_Bank_USD_GDP_Exchange_data')
    ]
)

arrow::write_parquet(wb_data, output_file)