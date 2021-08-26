####################################
# Creator: Gabriel Dennis 
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210825
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


## 1 - Variables for API Query  ------------------------------#


database_id <- "IFS" # International Financial Statistics
data <- imf_data(
    database_id,
    'EDNA_USD_XDC_RATE', # Annual exchange rates to USD  - Period average
    country = "all",
    start = 1990,
    end = current_year(),
    freq = "A",
    return_raw = FALSE,
    print_url = FALSE,
    times = 3
)

data <- data %>% 
  mutate(
    iso3c = countrycode(iso2c,'iso2c', 'iso3c')
  ) %>% 
  drop_na() %>% 
  rename(
    usd_exchange = EDNA_USD_XDC_RATE
  ) %>% 
  select(
    iso3c, year, usd_exchange
  )


## 2 - Save to File  ------------------------------#

output_file <- file.path('data', 'output', 
                         paste0(format(Sys.Date(),'%Y%m%d'), 
                         '_IFS_USD_Currency_exchange_data.'))

arrow::write_parquet(data ,paste0(output_file, 'parquet') )
readr::write_csv(data, file = paste0(output_file, 'csv'))
