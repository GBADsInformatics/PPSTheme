# PPSTheme

A space for code made by PPS modellers and analysts in the Global Burden of Animal Diseases (GBADs). For each of your models please follow the best practices set by GBADs Informatics, as articulated in the Data Governance Handbook.

# Code

## Biomass calculations in python: 


## Yin's original biomass calculation code

Name of file: `20210831_biomassUsingFAOSTAT.R`

Description: 

Use: 

## Biomass calculations in R: 

Name of file: `20210818_YinBiomassCalculation.R`

Author: Kassy Raymond and Yin Li

Description: 
- R code with biomass calculator for species using TLUs and conversion ratios from https://web.archive.org/web/20110223202019/, http://www.fao.org/ag/againfo/programmes/en/lead/toolbox/Mixed1/TLU.htm, http://www.fao.org/3/t0828e/T0828E07.htm. This code is adapted from the original notebook of Yin Li (found here: FIXME ask Yin to upload .Rmd code to this GitHub repo. 
- Functionality to get data from the FAOSTAT bulk .zip files available through Fenix Services. 
- Scale data to equal units (1000 Heads and No (Number of Animals) to Head - definition of units from FAOSTAT can be found here: http://www.fao.org/faostat/en/#definitions) 
- Filter datasets by species that have conversion ratios
- Calculate simple biomass by species using conversion ratios from the sources in the description (FIXME - get URI for these sources from Yin). 

Use: 
- To use, download the .R file and replace variables `dir` and `out_data` with the path to your project and the name/path of where you would like the output data to be saved, respectively
