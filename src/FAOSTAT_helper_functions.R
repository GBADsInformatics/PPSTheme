####################################
# Creator: Gabriel Dennis 
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited: 20210811
# 
# File Description: This script 
# contains some helper functions to clean 
# up FAOSTAT data
####################################

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
