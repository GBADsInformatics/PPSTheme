####################################
# Creator: Gabriel Dennis
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210830
#
# File Description: This script
# imports currency exchange data from the IMF
# and exports it to the files
#
# data/output/{date}_IFS_USD_Currency_exchange_data.parquet
# data/output/{date}_IFS_USD_Currency_exchange_data.csv
#
####################################


## 0 - Load Libraries  ------------------------------#
library(imfr)
library(countrycode)
library(tidyr)
library(dplyr)


## 1 - Variables Exchange Rate  API Query  ------------------------------#
# NGDP_XDC: Gross Domestic Product, Nominal, Domestic Currency
# Units are Millions Local Domestic Currency

# 'EDNA_USD_XDC_RATE': Annual exchange rates to USD  - Period average

# Exchange rates
database_id <- "IFS" # International Financial Statistics
exch <- imf_data(
    database_id,
    c('EDNA_USD_XDC_RATE', 'NGDP_XDC'),
    country = "all",
    start = 1990,
    end = current_year(),
    freq = "A",
    return_raw = FALSE,
    print_url = FALSE,
    times = 3
)

# There are some crazy numbers in these official statistics
# filter(exch, exch$EDNA_USD_XDC_RATE  ==  max(exch$EDNA_USD_XDC_RATE, na.rm = TRUE))
# iso2c year EDNA_USD_XDC_RATE      NGDP_XDC
# 1    CD 1990         417580414 0.00009926913


exch <- exch %>%
  mutate(
    iso3c = countrycode(iso2c,'iso2c', 'iso3c')
  ) %>%
  rename(
    usd_exchange = EDNA_USD_XDC_RATE
  ) %>%
  mutate(
    gdp_million_usd = usd_exchange*NGDP_XDC
  )  %>%
  select(
    iso3c, year, usd_exchange, gdp_million_usd
  )


## 2 - Save to File  ------------------------------#

# Remove any older versions of the file

output_files <- file.path('data', 'output')
file.remove(
  output_files[stringr::str_detect(output_files,
                                   '_IFS_USD_Currency_exchange_data|_IFS_USD_GDP_data')]
)


output_file_ex <- file.path('data', 'output',
                         paste0(format(Sys.Date(),'%Y%m%d'),
                         '_IFS_USD_Currency_exchange_data.'))

output_file_gdp <- file.path('data', 'output',
                            paste0(format(Sys.Date(),'%Y%m%d'),
                                   '_IFS_USD_GDP_data.'))
# Write to disk
arrow::write_parquet(select(exch, -gdp_million_usd) , paste0(output_file_ex, 'parquet') )
readr::write_csv(select(exch, -gdp_million_usd),  file = paste0(output_file_ex, 'csv'))

arrow::write_parquet(select(exch, -usd_exchange) , paste0(output_file_gdp, 'parquet') )
readr::write_csv(select(exch, -usd_exchange),  file = paste0(output_file_gdp, 'csv'))


#rm(list = ls())




















