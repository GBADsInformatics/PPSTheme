####################################
# Creator: Gabriel Dennis
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited:20211108
#
# File Description: This script calculates AS2 in constant 2014-2016 US dollars.
####################################
source(here::here('src', 'utils', 'FAOSTAT_helper_functions.R'))

library(tidyverse, quietly = TRUE, warn.conflicts = FALSE)




############################################ Data
# Load Stocks
stocks <- get_fao_livestock_numbers()


# Load prices
prices <- arrow::read_parquet(get_gbads_file('FAO-Constant-2014-2016-prices', dir=here::here('data', 'output'))) %>%
    drop_na(constant_usd) %>%
    add_country_codes(area_code, area) %>%
    filter(str_detect(item, 'Meat live weight')) %>%
    separate(item, c(NA, 'animal'), sep = ', ', extra = 'merge')


# Load Conversion Ratios
conversions <- arrow::read_parquet(get_gbads_file('FAO_LiveWeights_Imputed_Conversions.parquet', dir=here::here('data', 'output'))) %>%
    drop_na(live_weight_kg) %>%
    rename(conversion_animals = animal, iso3_code = iso3)




# Tibble to convert between different categories
stock_animals <- c(
"Asses",
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
"Turkeys")

price_animals <- c(
"ass",
"buffalo",
NA,
"camel",
"cattle",
"chicken",
"duck",
"goose",
"goat",
"horse",
"mule",
"pig",
"rabbit",
NA,
"sheep",
"turkey"
)

conversion_animals <- c(
"asses",
"buffaloes",
NA,
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
NA,
"sheep",
"turkeys"
)
conv_df <- tibble(stock_animals, price_animals, conversion_animals)


as2 <- stocks %>%
    left_join(conv_df %>%
            rename(item = stock_animals, animal = price_animals), by = c('item')) %>%
    left_join(prices, by = c('iso3_code', 'country','animal', 'year')) %>%
    left_join(conversions, by = c('iso3_code', 'country', 'conversion_animals', 'year')) %>%
    mutate(value_constant_usd = (live_weight_kg/1000) * constant_usd * value) %>%
    select(iso3_code, country, year, conversion_animals, value_constant_usd) %>%
    drop_na(value_constant_usd, conversion_animals) %>%
    rename(animal = conversion_animals)

###############################################################################
# Remove Venezuala, Belerus and Zimbabwe globally, until can find correct
# conversion rates which do not flucuate too much
###############################################################################
# FAO exchange rates
exchange_rates <- arrow::read_parquet(here::here('data', 'raw', 'FAOSTAT', '20213501_Exchange_rate_E_All_Data_(Normalized).parquet')) %>%
    rename_with(~tolower(gsub(' ', '_', .x)))

# Venezuale exchange rate goes crazy,
# Zimbabwe LCU must be incorrect
# Beleruse has unusually high values aroudn 2014-2015 for the mean price
ggplot(exchange_rates %>% filter(area %in% c('Venezuela (Bolivarian Republic of)', 'Zimbabwe', 'Belarus')),
       aes(x = year, y = value)) +
    geom_point() +
    facet_wrap(vars(area), scales = 'free_y')

ggplot(as2 %>% filter(iso3_code %in% c('VEN', 'BLR', 'ZWE')) %>% group_by(country, year) %>% summarise(value = sum(value_constant_usd, na.rm = TRUE)),
       aes(x = year, y = value)) +
    geom_point() +
    facet_wrap(vars(country), scales = 'free_y')
###############################################################################
# Remove Venezuala after 2017
# Remove Belarus overall until its values can be checked
# Remove Zimbabwe before 2010
###############################################################################
as2 <- as2 %>%
    filter(!((iso3_code == 'VEN') & (year >=2018))) %>%
    filter(!((iso3_code == 'BLR'))) %>%
    filter(!((iso3_code == 'ZWE') & (year < 2010)))

# Save AS2
arrow::write_parquet(as2, here::here('data', 'output', 'AS2_Value-of-animal-stock_Constant-2014-2016-prices.parquet'))



# Look at a plot globally
ggplot(as2 %>% group_by(year) %>% summarise(value = sum(value_constant_usd, na.rm = TRUE)), aes(year, value)) + geom_point() +
    scale_y_continuous(labels = scales::dollar_format())
