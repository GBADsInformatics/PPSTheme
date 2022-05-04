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
# Date Last Edited:  20220131
#
# Description:  Contains a series of helper functions
# to work with data downloaded from the FAOSTAT
# API
####################################


## 0 - Libraries  ------------------------------#
library(readr)
library(arrow)
library(rjson)
library(janitor)
library(FAOSTAT)
library(dplyr)
library(tidyr)



##  - Function to print date string  ------------------------------#
#' iso_date
#'
#' @return returns data in YYYYMMDD format
#' @example iso_date()
iso_date <- function() {
  format(Sys.Date(), format = "%Y%m%d")
}


file_name <- function(source, tags,
                      extension = ".parquet",
                      output_dir = here::here("data", "output")) {
  base_dir <- file.path(output_dir, source)
  if (!dir.exists(base_dir)) {
    dir.create(base_dir)
  }
  file.path(base_dir, paste0(
    source, "_",
    paste(tags, collapse = "_"), extension
  ))
}



##  - Function to find latest GBADS file  ------------------------------#

#' get_gbads_file
#'
#' @param str regex string to match file name
#' @param dir directory of gbads file
#'
#' @return the full path the the appropriate name
get_gbads_file <- function(str, dir) {
  files <- list.files(dir)
  file_match <- grep(str, files, value = TRUE, fixed = TRUE)
  return(file.path(dir, sort(file_match, decreasing = TRUE)[1]))
}





#' get_fao_metadata
#'
#' import metadata for set of FAOSTAT datasets
#' from the FAOSTAT metadata json file
#'
#' @param dataset_codes character vector of dataset codes
#' @param metadata_json location of the metadata json
#'
#' @return list of dataset metadata
get_fao_metadata <- function(dataset_codes,
                             metadata_json = Sys.glob(
                               here::here(
                                 "data",
                                 "FAOSTAT",
                                 "*FAOSTAT_datasets_E.json"
                               )
                             )) {
  metadata <- rjson::fromJSON(file = metadata_json)

  # Filter through and extract dataset codes
  metadata <- metadata$Datasets$Dataset %>% purrr::discard(~ !(.x$DatasetCode %in% dataset_codes))
  names(metadata) <- purrr::map(metadata, ~ .x$DatasetCode)
  return(metadata)
}


# - Cleans FAOSTAT countries -------------------------------------------------------------------
#' clean_countries
#'
#' Cleans the countries imported from faostat by removing multiple versions
#' of China for any one year and removing countries which invalid ISO3 codes
#'
#' @param df a dataframe containing the correct columns
#' @param code_col column name containing faostat codes
#' @param year_col column name containing years as %Y format
#' @param value_col column name containing the faostat values
#'
#' @return dataframe with double counted and missing values removed
#' @export
#'
#' @examples
clean_countries <- function(df,
                            code_col = "area_code",
                            year_col = "year",
                            value_col = "value") {
  names(df)[names(df) == code_col] <- "FAOST_CODE"

  countries <- FAOSTAT::FAOcountryProfile %>%
    select(FAOST_CODE, ISO3_CODE)

  df %>%
    FAOSTAT::FAOcheck(
      var = value_col,
      year = year_col,
      data = .,
      type = "multiChina"
    ) %>% # Check for multiple China entries
    drop_na(value) %>% # Remove missing values
    left_join(countries, by = "FAOST_CODE") %>%
    drop_na(ISO3_CODE) %>% # Remove countries without valid ISO3_CODES according to FAO
    mutate(
      area = plyr::mapvalues(area, c("China, mainland"), c("China"))
    ) %>%
    relocate(ISO3_CODE, .before = everything()) %>%
    janitor::clean_names()
}


##  - Sanitize character columns if necessary ------------------------------#
#' sanitize_columns
#'
#' this function sanitizes character columns by removing unusual characters
#' and turns selected colums to snakecase
#'
#' @param df a dataframe
#' @param exclude character vector containing which column names will be excluded
#'
#' @return a dataframe which only has ASCII characters in its character columns
#'
#' @examples
#' sanitize_columns(data.frame(a = "a"))
sanitize_columns <- function(df, exclude = NULL) {
  character_cols <- sapply(df, class)
  character_cols <- names(character_cols)[character_cols == "character" &
    !grepl(character_cols, "iso3")]
  df |>
    mutate_at(
      setdiff(character_cols, exclude),
      ~ snakecase::to_any_case(.x)
    )
}
