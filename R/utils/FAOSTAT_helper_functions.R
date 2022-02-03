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
library(magrittr)
library(readr)
library(arrow)
library(rjson)
library(janitor)
library(FAOSTAT)



##  - Function to print date string  ------------------------------#
#' iso_date
#'
#' @return returns data in YYYYMMDD format 
iso_date <- function() {
  format(Sys.Date(), format = "%Y%m%d")
}


file_name <- function(source, tags, 
                      extension = ".parquet",
                      output_dir = here::here('data', 'output')) {
  base_dir <- file.path(output_dir, source)
  if (!dir.exists(base_dir)) {
    dir.create(base_dir)
  }
  file.path(base_dir, paste0(iso_date(),'_', source ,'_',
         paste(tags, collapse = '_'),  extension))
}


##  Function to convert downloaded zip files into Parquet  ------------------------------#
#' zip_to_parquet
#'
#' @param file_name zip file name
zip_to_parquet <- function(file_name) {
  if (!grep(".zip$", file_name)) {
    stop(
      paste0(file_name, " is not a zip file.")
    )
  } else if (!file.exists(file_name)) {
    stop(paste0(
      file_name, " does not exist"
    ))
  }

  # Read in data from zip file
  data <- readr::read_csv(file_name, progress = FALSE)

  output_file_name <- file.path(
    dirname(file_name),
    gsub(".zip", ".parquet", basename(file_name)) %>%
      gsub("_\\(Normalized\\)", "", .)
  )
  arrow::write_parquet(data, output_file_name)
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
                               here::here("data",
                                          "FAOSTAT", 
                                          "*FAOSTAT_datasets_E.json"))) {
                               
  metadata <- rjson::fromJSON(file = metadata_json)
  
  # Filter through and extract dataset codes 
  metadata <- metadata$Datasets$Dataset %>% purrr::discard(~!(.x$DatasetCode %in% dataset_codes))
  names(metadata) <- purrr::map(metadata, ~.x$DatasetCode)
  return(metadata)
}


# - Cleans FAOSTAT countries -------------------------------------------------------------------
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
      type = "multiChina") %>%  # Check for multiple China entries
    drop_na(value) %>%  # Remove missing values 
    left_join(countries, by = "FAOST_CODE") %>%
    drop_na(ISO3_CODE) %>%  # Remove countries without valid ISO3_CODES according to FAO 
    mutate(
      area = plyr::mapvalues(area, c('China, mainland'), c('China'))
    ) %>% 
    relocate(ISO3_CODE, .before = everything()) %>% 
    janitor::clean_names()
}


##  - Sanitize character columns if necessary ------------------------------#
sanitize_columns <- function(df) {
  df %>%
    mutate_if(~is.character(.x),
              ~iconv(.x, "UTF-8", "ASCII") %>%
                snakecase::to_any_case())
}



