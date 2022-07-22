#! /usr/bin/Rscript --vanilla

################################################################
#
# Project: GBADS: Global Burden of Animal Disease
#
# Author: Gabriel Dennis
#
# Position: Research Technician, CSIRO
#
# Email: gabriel.dennis@csiro.au
#
# CSIRO ID: den173
#
# GitHub ID: denn173
#
# Maps FAOSTAT crop codes to CPC codes
# I/O: defined in the config and makefile
####################################



## 0 - Libraries  ------------------------------#
suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(tidyr)
  library(janitor)
  library(LivestockValueGBADS)
})



# Config ------------------------------------------------------------------
config <- config::get()




# The Food groups don't match perfectly
#  - USE the CPC groupings given by
#  https://www.fao.org/fileadmin/templates/ess/classifications/Correspondence_CPCtoFCL.xlsx
food_groups <- tribble(
  ~group, ~code,
  "cereals", "011",
  "vegetables", "012",
  "fruits_nuts", "013",
  "oilseed_oil_fruits", "014",
  "roots_tubers", "015",
  "coffe_spice_crops", "016",
  "pulses", "017",
  "sugar_crops", "018"
)

# FAOSTAT Item codes
faostat_item_codes <- config$data$codes$faostat$items$item_codes |>
  readRDS() |>
  clean_names() |>
  sanitize_columns(exclude = c("domain_code"))



# Need to check further how to avoid double counting
#  - Keep as is for now as it seems that the separate codes
#    remove the issues of double counting
crop_groups <- faostat_item_codes |>
  dplyr::filter(domain_code == "QCL") |>
  select(item, item_code, cpc_code) |>
  mutate(
    item_group = substr(cpc_code, start = 1, stop = 3)
  ) |>
  filter(item_group %in% food_groups$code) |>
  left_join(food_groups, by = c("item_group" = "code")) |>
  drop_na(item)


# Write to output codes directories ---------------------------------------
saveRDS(
  crop_groups,
  file.path(
    config$data$codes$faostat$dir,
    "FAOSTAT-CPC_cropItemCodes.rds"
  )
)
saveRDS(
  food_groups,
  file.path(
    config$data$codes$faostat$dir,
    "CPC_cropGroups.rds"
  )
)
