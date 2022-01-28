####################################
# Creator: Gabriel Dennis
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210830
#
# File Description: This script imputes liveweights for livestock which
# are not present in the FAOSTAT technical conversion factors table and
# are present in the FAOSTAT liveweight price data.
#
# The imputation method is done via regional imputation at broader and broader
# regions depending on the availability of data.
#
#  - Current imputation method is simply the median value
#
#     Inputs:
#     # FAO liveweight conversion factors
#     /data/output/{date}_FAO_Technical_Conversion_Factors.parquet
#     # FAO liveweight prices
#     /data/output/{date}_FAOSTAT_Annual_Meat_Liveweight_Prices_USD_LCU_SLC.parquet
#     # FAO category mappings between stocks, prices and tcfs
#     /data/
#
#     Output:
#     # FAO liveweight conversion factors
#     /data/output/{date}_FAOSTAT_liveweight_conversion_factors_IMPUTED.parquet
####################################


## 0 - Load Libraries ------------------------------#

library(dplyr)
library(tidyr)
library(magrittr)
library(ggplot2)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
theme_set(theme_bw())
source('src/FAOSTAT_helper_functions.R')

visualise <- FALSE


## 1 - Read in Data  ------------------------------#

tcfs <- arrow::read_parquet(
  data_file_path('FAO_Technical_Conversion_Factors.parquet')
) %>%
  select(iso3, animal_en, live_weight) %>%
  filter(!is.na(iso3)) %>%
  mutate(
    live_weight = if_else(
      animal_en %in% c("chickens", "turkeys", "geese", "ducks", "rabbits"),
      as.numeric(live_weight)/1000, as.numeric(live_weight)
    )) %>%
  pivot_wider(names_from = animal_en,
              values_from = live_weight) %>%
  pivot_longer(
    cols = cattle:geese,
    names_to =  'animal'
  )

prices <- arrow::read_parquet(
  data_file_path('FAOSTAT_Annual_Meat_Liveweight_Prices_USD_LCU_SLC.parquet')
)

item_maps <- readr::read_csv(
  data_file_path('FAOSTAT_category_mappings.csv', ''),
  col_select = c('fao_prices', 'fao_tcf'),
  col_types = 'cc'
)

## 2 - Visualise Where we are missing values ------------------------------#
if (visualise ) {
world <- ne_countries(scale = "medium", returnclass = "sf")

# Spread the conversion factors and join them by iso
world_tcf <- world %>%
  right_join(tcfs %>%
            rename(iso_a3 = iso3))

spread_price <- prices %>%
  rename(iso_a3 = iso3c) %>%
  count(iso_a3, animal) %>%
  spread(animal, n) %>%
  gather(key = 'animal', value = 'value',-iso_a3)


world_price <- world %>%
  right_join(spread_price, by='iso_a3')

# TCF distribution
p <- ggplot(world_tcf) +
  geom_sf(aes(fill = value), color = 'black') +
  ggtitle("Technical Conversion Factors Liveweights",
          subtitle ="FAO") +
  scale_fill_viridis_c(option = "plasma", trans = "sqrt") +
  facet_wrap(~animal)
ggsave("output/figs/tcf_availability_map.png", plot=p,
       width=10, height=5, dpi=150)


# Price distribution
world_price$value <-  cut(world_price$value, breaks = seq(0, 30, by = 5))
p1 <- ggplot(world_price) +
  geom_sf(aes(fill = value)) +
  scale_fill_brewer(palette="RdYlBu", na.value="white") +
  facet_wrap(vars(animal))
ggsave("output/figs/fao_price_availability_map.png", plot=p1,
       width = 10, height=5, dpi=150)
}



## 2 - Map items and impute regionally  ------------------------------#

# Add different regional aggregations to FAO_tcfs
# Use better ones
tcfs$region23 <- countrycode::countrycode(tcfs$iso3,
                                          'iso3c',
                                          'region23')

tcfs$continent <- countrycode::countrycode(tcfs$iso3,
                                          'iso3c',
                                          'continent')

region <- tcfs %>%  group_by(region23, animal) %>%
  summarise(region_med = median(value, na.rm = TRUE))

continent <- tcfs %>%  group_by(continent, animal) %>%
  dplyr::summarise(continent_med = median(value, na.rm = TRUE))

tcfs <- tcfs %>%
  left_join(region) %>%
  left_join(continent) %>%
  select(-region23, -continent) %>%
  mutate(
    value = if_else(!is.na(value),value, if_else(!is.na(region_med),region_med, continent_med ))
  ) %>%
  select(-region_med, -continent_med)





## 3 - Write to file ------------------------------#
output_file <- file.path('data', 'output',
                          paste0(format(Sys.Date(),'%Y%m%d'),
                   '_FAOSTAT_liveweight_conversion_factors_IMPUTED.parquet'))

arrow::write_parquet(tcfs,output_file)



























