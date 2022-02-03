####################################
# Creator: Gabriel Dennis
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210902
#
# File Description:  This script cleans DADIS weight
# and population data.
####################################


## 0 - Libraries ------------------------------#
library(tidyverse, quietly = TRUE)



## 1 - Import  ------------------------------#
files <- list.files('data/raw/dad-is', full.names = TRUE)


# Weights and Metadata on Each Species
weight_cols <- c('Country',
                 'ISO3',
                 'Specie',
                 'Breed/Most common name',
                 'Weight males',
                 'Weight females',
                 'Carcass weight',
                 'Dressing percentage')

weights <- readr::read_csv(files[str_detect(files, 'Metadata')],
                           skip = 1,
                           col_select = weight_cols) %>%
          rename_with(~tolower(gsub('\\s', '_', .x))) %>%
          rename(
            species = specie,
            breed  = `breed/most_common_name`
            )



# Populations of each species
pop_cols <- c('Country',
              'ISO3',
              'Specie',
              'Breed',
              'Year',
              'Population min',
              'Population max')

# Population data
population <- readr::read_csv(files[str_detect(files, 'Population')],
                              skip = 1,
                              col_select = pop_cols) %>%
  rename_with(~tolower(gsub('\\s', '_', .x))) %>%
  rename(species = specie)

## 2 - Create Conversion Tables for each country ------------------------------#

# Stocks
population <- population %>%
  rename(species = specie) %>%
  select(iso3, species, breed, year, population_min, population_max)

population$stock <- rowMeans(population[, c('population_min', 'population_max')],
                             na.rm = TRUE)

# Weights table
weights$weight <- rowMeans(weights[, c('weight_males', 'weight_females')],
                          na.rm = TRUE)


# Drop all values which are mising in the weight column
weights <- weights %>%
  select(iso3, species, breed, weight) %>%
  drop_na(weight)




# Get weights as the average of male and female (slightly bad)
# As the population numbers

## Join tables
population <- population %>%
  left_join(weights,
            by = c('iso3', 'species', 'breed')
            )


#na_prop_total <-
na_prop_total <- population %>%
  mutate(
    na_weight = if_else(is.na(weight), 0, stock)
  ) %>%
  group_by(
    iso3, species
  ) %>%
  dplyr::summarise(
    na_prop  = (1  - sum(na_weight, na.rm = TRUE)/sum(stock, na.rm = TRUE)) * 100
  )



# May be a problem with this method.
# Highly variable with the amount of data which is available for any one country
# which makes this level of granularity somewhat a moot point of interest.
# May just need to go back to a much more coarse level of weights.
# There is not enough data to get any better estimate than the one which is currently
# available to us via the TCFs from the FAO or vie the LUs which are used
# by both the FAO and the OIE.
















