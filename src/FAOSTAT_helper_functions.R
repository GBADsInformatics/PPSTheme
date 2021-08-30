####################################
# Creator: Gabriel Dennis 
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210827
# 
# File Description: This script 
# contains some helper functions to clean 
# up FAOSTAT data
####################################



# This function reads in a FAOSTAT table using the FAOSTAT package
# 
# The table is downloaded only if it the latest version of the table is not 
# already stored in the data/temp directory.  It also saves a subsetted parquet 
# file to the temp directory for easy reanalysis. 
read_fao_table <- function(code, fao_zip_name, vars) {
  require(stringr)
  require(dplyr)
  # Temporary directory
  tmp_dir <- file.path('data', 'temp')
  # Temporary zip file
  tmp_file <- file.path(tmp_dir, paste0(fao_zip_name, '.zip'))
  tmp_parquet <- file.path(tmp_dir, paste0(format(Sys.Date(),'%Y%m%d'), '_', 
               str_remove(fao_zip_name,'_(Normalized)'), '.parquet'))
  
  if (file.exists(tmp_parquet)) {
    df <- arrow::read_parquet(tmp_parquet)
  } else {
    # Get the bulk normalized zip
    df <- FAOSTAT::get_faostat_bulk(code = code, tmp_dir)
    
    if (!file.exists(tmp_file)) {
      stop(paste0("File was stored with a  different file name, ", 
                  list.files(temp_dir)))
    } else if (length(setdiff(vars, names(df))) > 0) {
      stop(paste0('FAOSTAT raw data has incorrect column names: ',
                  names(livestock_df)))
    }
    
    #Subset file 
    df <- select(df, all_off(vars))
    # Save to parquet file
    arrow::write_parquet(df, tmp_parquet)
  }
  return(df)
}





clean_faostat_element <- function(element, element_string) {
  require(stringr)
  return(
    str_remove_all(element, element_string) %>% 
      str_remove_all('[()]') %>% 
      trimws() %>% 
      str_replace_all(' ', '_')
  )
}



data_file_path <- function(data_file, dir= NA) {
  if (is.na(dir)) {
    output_data_folder <- file.path('data', 'output')
  } else{
    output_data_folder <- file.path('data',dir)
  }
  
  output_data_files <- list.files(output_data_folder)
  return(
    file.path(output_data_folder, 
              output_data_files[stringr::str_detect(output_data_files, data_file)])
  )
}
