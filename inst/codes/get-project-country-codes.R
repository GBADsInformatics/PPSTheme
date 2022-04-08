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
# Description: This file takes as input the current
# FAOSTAT Country Codes and produces a subset of these
# codes based which are used for all subsequant analysis
#
# - Note: these codes contain multiple Chinese regions
#   which are subset to make sure that china is not double
#   counted. China will always be mapped to CHN
#
# The input code file is contained in
#  - data/codes/FAOSTAT_Country_Codes.Rds
#
# Output:
# - data/output/codes/faostat_iso3_country_codes.parquet
#
# These locations are contained in the project configuration file
# - conf/config.yml
# and the dependencies are contained withing the Makefile recipe
# to rebuild the output file.
####################################


# Activate Project --------------------------------------------------------

renv::activate(project = ".")
logging::basicConfig()

# Load Configuration ------------------------------------------------------

config <- config::get(file = file.path("conf", "config.yml"))



# Import Raw FAOSTAT Country Codes as RDS ---------------------------------
country_codes_config <- config$data$codes$faostat$country_codes

input_country_codes_file <- normalizePath(country_codes_config$raw_codes)
output_country_codes_file <- country_codes_config$output_codes

if (dir.exists(here::here(dirname(output_country_codes_file)))) {
  logging::loginfo("Creating output directory")
  dir.create(here::here(dirname(output_country_codes_file)))
} else {
  logging::loginfo("Output directory already exists")
}

logging::loginfo("Subsetting FAOSTAT Country Codes")

iso3_codes <- input_country_codes_file |>
  readRDS() |>
  janitor::clean_names() |>
  dplyr::distinct(country, iso3_code) |>
  tidyr::drop_na()


# Write to File ----------------------------------------------------------
arrow::write_parquet(
  x = iso3_codes,
  sink = here::here(output_country_codes_file)
)

logging::loginfo("Exit")
