# PPSTheme

A space for code made by PPS modellers and analysts in the Global Burden of Animal Diseases (GBADs). For each of your models please follow the best practices set by GBADs Informatics, as articulated in the Data Governance Handbook.

# Code

## Biomass calculations in python: 

Name of relevant directories: `/src` and `/data`

Author: Kassy Raymond

### Description
Data cleaning and biomass calculations were coded in python to assist in the ingestion of biomass data into the knowledge engine. 

### Use
* `/data`
	* `<date>_liveWeightFAO.csv` is the original csv file that provides live weights for livestock animals according to: https://www.fao.org/economic/the-statistics-division-ess/methodology/methodology-systems/technical-conversion-factors-for-agricultural-commodities/en/
	* `<date>_liveWeightFAO_cleaned.csv` is the cleaned livestock live weights. Information about cleaning and rational can be found in FIXME.
	* `<date>_biomass_liveWeight_faostat.csv` is the output file that has all biomass estimates calculated using the GBADs API. Information about the API call can be found in `src/BiomassCalc.py`.
* `/src`
	* `cleanFaoConversion.py` maps countries to FAO country names and converts all live weights to kg. To run you must specify the input file as a command line argument. The input file used is `<date>_liveWeightFAO.csv`. The output file is `<date>_liveWeightFAO_cleaned.csv`.
		* Running: `cleanFaoConversion.py <date>_liveWeightFAO.csv`
	* `BiomassCalc.py` calculates biomass by multiplying population of animals by live weight. The program takes one command line argument, which is the live weight file `<date>_liveWeightFAO_cleaned.csv`. 
		* Running: `BiomassCalc.py <date>_liveWeightFAO_cleaned.csv <source> <path to data dir>` 

### TO DO: 
* Add functionality to calculate biomass using TLUs. 

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
