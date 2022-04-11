#!/usr/bin/Rscript --vanilla

###################################################
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
# Date Created:  20220408
#
# Description: This script takes in the World Banks weighted average
# USD to LCU conversion rate (PA.NUS.ATLS) which is stored in
#
#  - data/processed/world_bank/lcu_conversion.parquet
#
# This script simply reads this file, subsets it
# for countries/regions which are to be included in the final
# analysis.
#
# The output location of this script will be in
# - data/output/world_bank/lcu_conversion.parquet
#
# These locations are currently available in the
# project config file stored in conf/config.yml
#
####################################


# Activate Project --------------------------------------------------------

renv::activate(project = '.')



# Import Configuration Files ----------------------------------------------

config <- config::get(file = file.path('conf', 'config.yml'))


# Import LCU USD Conversion Data ----------------------------------------------

# Subset for the regions which will be used in the remainder of this
# analysis
lcu_conversion_file <- config$data$processed$tables$lcu_conversion
output_lcu_conversion_file <- config$data$output$lcu_conversion

# Location of country codes
country_codes <- config$data$codes$faostat$country_codes$output_codes |>
  arrow::read_parquet()


logging::loginfo(paste0("Importing and transforming world bank LCU to USD Exchange Rate",
                 "Conversion Data: PA.NUS.ATLS"))

arrow::read_parquet(lcu_conversion_file) |>
  dplyr::rename(
    iso3_code = country_code,
    country = country_name
  ) |>
  tidyr::gather(key = "year",
                value = "value",
                -iso3_code,
                -country,
                -indicator_name,
                -indicator_code) |>
  tidyr::drop_na(value) |>
  dplyr::filter(value > 0) |>
  assertr::verify(value > 0) |>
  dplyr::filter(
    iso3_code %in% unique(country_codes$iso3_code)
  ) |>
  dplyr::mutate(
    year = as.numeric(substr(year, 2, nchar(year)))
  ) |>
  arrow::write_parquet(
    sink = here::here(output_lcu_conversion_file)
  )


# Exit the Script ---------------------------------------------------------
logging::loginfo("Exit")

