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

