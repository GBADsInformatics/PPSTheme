# Creation info -----------------------------------------------
#########################################################
# Creator: Kassy Raymond
# Email: kraymond@uoguelph.ca
# GBADs theme: Informatics
# Date of creation: 08-18-2021
# Date last edited: 08-18-2021

# Note: Original code from Yin Li - FIXME add link to original code in GitHub
# Description: 
# An estimate of biomass using TLU values from 
# https://web.archive.org/web/20110223202019/
# http://www.fao.org/ag/againfo/programmes/en/lead/toolbox/Mixed1/TLU.htm. 
# The conversion ratios of species can be find in: http://www.fao.org/3/t0828e/T0828E07.htm
# Original calculation code was adapted from Yin Li 
#########################################################

# Install and load packages -----------------------------------------------

# Create list of packages needed
packages = c('FAOSTAT','tidyverse','Hmisc','ggplot2','dplyr')

# Check to see which packages need installing, then load and install packages 
package.check <- lapply(
  packages,
  FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE)
      library(x, character.only = TRUE)
    }
  }
)

# Functions -----------------------------------------------

load_FAOSTAT_data <- function(dir_path, fao_code, fao_element){
# To download data using the FAOSTAT package in R, you must create or specify a folder to store the retrieved data from. Use ?get_faostat_bulk for more information. 
    
  # Check to see if the data dir given exists, if it doesn't create dir
  ifelse(!dir.exists(dir_path), 
         dir.create(dir_path), FALSE)
  
  # Use fao_code to get data from fao
  df <- get_faostat_bulk(code = fao_code, data_folder = dir_path)
  
  # Filter download based on element
  df <- df %>% 
    filter(element == fao_element)
  
  return(df)
}

equal_units <- function(fao_df, unit_col){
  
  # quosure for unit col
  unit_col <- enquo(unit_col)
  
  # Expected units for livestock include 'No', 'Head', and '1000 Heads' (http://www.fao.org/faostat/en/#definitions) 'No' means number, which can be assumed to be the same as 'head'
  expected_units <- c('No', 'Head', '1000 Head')
  
  # Get unique units
  unique_units <- distinct(fao_df, unit) %>% pull(unit)
  
  # check to see if the units in the unit col are what are expected
  is_equal <- setequal(expected_units, unique_units)==TRUE
  
  return(is_equal)
  
}

scale_by_head <- function(fao_df, unit_col, value_col){
  
  # Create quosure 
  unit_col <- enquo(unit_col)
  value_col <- enquo(value_col)
  
  # check to see if units in the unit col are equal to what is expected 
  is_equal <- equal_units(fao_df, unit_col)
  
  # check to see if the units in the unit col are what are expected 
  if (is_equal == TRUE){
    
    # if the units are in 1000 heads, multiple value col by 1000
    fao_df_scaled <- fao_df %>% 
      group_by(!!unit_col) %>% 
      mutate(., scaled_value = ifelse(unit =='1000 Head', value*1000, value)) %>% 
      mutate(., scaled_unit = ifelse(unit =='1000 Head'| unit == 'No', 'Head', unit)) 
    
    return(fao_df_scaled)
  
  }else {
    stop('Units in dataset are unexpected. Units from FAO for livestock should include one or more of the following: No, Head or 1000 Head')
  }
} 

filter_species <- function(fao_df, item_col, species){
  
  # filter species in item_col based on what is provided as species
  
  # create quosure
  item_col <- enquo(item_col)
  
  # filter 
  filtered_df <- fao_df %>% 
    dplyr::filter(!!item_col %in% species)
  
  return(filtered_df)
  
}

calc_simple_biomass <- function(fao_df, num_head_col, species_tlu_ratio, unit_biomass_kg){
  # use tlu ratio to calculate biomass with df
  
  # create quosure
  num_head_col <- enquo(num_head_col)
  
  # merge conversion ratio into pre-existing df 
  df <- merge(species_tlu_ratio, fao_df, by = "item")
  
  # mutate based to yield biomass based on conversion 
  biomass_df <- df %>% 
    mutate(., tlu = !!num_head_col*ratio, biomass = tlu*unit_biomass_kg)
  
  return(biomass_df)

}

# Load data  ----------------------------------------------- 

# Could add as sys args but most use R in RStudio instead of terminal --vanilla version
dir = '/Users/kassyraymond/PhD/trunk/PPS_Dashboard'
fao_code = 'QCL'
fao_element = 'Stocks'
out_data = '/Users/kassyraymond/PhD/trunk/PPS_Dashboard/20210819_yinBiomassCalc.csv'

# load data from faostat using the above information
production_df <- load_FAOSTAT_data(dir, fao_code, fao_element)

# Drop columns and clean ----------------------------------------------- 

# drop unneeded data
prod_df <- select(production_df, -c('item_code', 'element_code','year_code', 'flag', 'element'))

# Scale and analyze  ----------------------------------------------- 

# check and scale data to basic unit
prod_df <- scale_by_head(prod_df, unit, value)

# set up conversion ratios for species using ratios from doi: 10.3389/fvets.2020.556788
# put this in function where you can ask for ratios for the species that you want
species_tlu_ratio <- enframe(c(Cattle = 0.7, Chickens = 0.01, Asses = 0.5, Camels = 1, Goats = 0.1, Horses = 0.8, Mules = 0.7, Sheep = 0.2, Pigs = 0.2), name = 'item', value = 'ratio')

# keep only species that we have a conversion ratio for
prod_df_filtered <- filter_species(prod_df, item, species_tlu_ratio$item)

# calculate simple biomass using tlus above
simple_biomass <- calc_simple_biomass(prod_df_filtered, scaled_value, species_tlu_ratio, 250)

# remove any unnecessary columns
simple_biomass <- select(simple_biomass, -c('unit','value'))

# save as df
write.csv(simple_biomass, out_data, row.names = FALSE)
