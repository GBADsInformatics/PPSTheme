################################################################################
# Project: GBADS
#
# Author: Gabriel Dennis
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20211202
#
# File Description: This script attempts to convert
# all prices to constant US dollars.
#
#
# This is done using the Producer price index and the 2014-2016
# mean conversion rate.
# In this case, the mean LCU price in 2014-2016 converted to USD is used
# as the base amount, and is altered by the Producer price index.
#
# The producer price index is used as it is more abundant the price data,
# and will allow for an estimate of the price per tonne in places where no official
# price was reported.
#
# The Producer price index for 2014-2016 is set to 100 in this case.
# As it is the average exchange rate which is used across this period.
################################################################################



#################################################################
# Libraries
#################################################################
library(tidyverse, quietly = TRUE)


#################################################################
# FAO Price data in LCU, SLC and USD
#################################################################
# Load FAO price data
prices <- arrow::read_parquet(here::here('data', 'raw', 'FAOSTAT', '20211021_Prices_E_All_Data_(Normalized).parquet')) %>%
    rename_with(~tolower(gsub(' ', '_', .x)))



#################################################################
# FAO Officiel Exchange Rates
#################################################################
# Exchange rates - Get the average 2014-2016 Exchange Rates
exchange_rates <- arrow::read_parquet(here::here('data', 'raw', 'FAOSTAT', '20213501_Exchange_rate_E_All_Data_(Normalized).parquet')) %>%
    rename_with(~tolower(gsub(' ', '_', .x))) %>%
    filter(year %in% c(2014:2016)) %>%
    group_by(area_code, area, iso_currency_code, currency) %>%
    summarise(mean_conversion = mean(value, na.rm = TRUE), .groups = 'drop')



#################################################################
# Constant Prices
#################################################################
# Get only annual values
prices <- prices %>%
    filter(months_code == 7021)



# Get only Live animals, and live animals items in SLC and producer price index
prices <- prices %>%
    filter(str_detect(item, 'Meat|Eggs|Milk|Live|Wool|Offal|Fat|Lard'),
           element_code %in% c(5531, 5539)) %>%
    select(area_code, area, item_code, item, year, element, value) %>%
    spread(element, value)  %>%
    rename(pp_index  = `Producer Price Index (2014-2016 = 100)`)

# Get the Mean LCU price for 2014-2016
mean_price <- prices %>%
    group_by(area_code, area, item_code, item) %>%
    filter(year %in% 2014:2016) %>%
    summarise(mean_price_lcu = mean(`Producer Price (SLC/tonne)`, na.rm = TRUE), .groups='drop') %>%
    drop_na(mean_price_lcu)


# Join
prices_means <- prices %>%
    left_join(mean_price, by = c('area_code', 'area', 'item_code','item')) %>%
    left_join(exchange_rates, by = c('area_code', 'area')) %>%
    mutate(
        constant_usd = (pp_index/100) * mean_price_lcu/mean_conversion
    ) %>%
    drop_na(constant_usd)



#################################################################
# Write to File
#################################################################
# Save the constant prices
arrow::write_parquet(prices_means,
                     here::here('data', 'output','FAOSTAT',
                                paste(format(Sys.Date(), '%Y%m%d'), 'FAO-Constant-2014-2016-prices.parquet', sep = '_')))



