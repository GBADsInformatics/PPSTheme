# Makefile to make all analysis targets in this project

# Variables
R_DIR=R/
SCRIPT_DIR=inst/
SOURCE_DATA_DIR=data/source/
PROCESSED_DATA_DIR=data/processed/
OUTPUT_DATA_DIR=data/output/
FIGURE_DIR=output/figures/
TABLE_DIR=output/tables/

#-----------------------------------------
# Data
#
# Downloads the latest datasets
# ---------------------------------------

# TODO: Turn this into a single make

# Downloads the FAOSTAT VOP Table
$(PROCESSED_DATA_DIR)faostat/value_of_production.parquet:
	Rscript $(SCRIPT_DIR)/data/data-download.R --data value_of_production

# Downloads the FAOSTAT Producer Prices table
$(PROCESSED_DATA_DIR)faostat/producer_prices.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data producer_prices 

# Downloads the FAOSTAT Crops and Livestock Products Table
$(PROCESSED_DATA_DIR)faostat/crops_and_livestock_products.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data crops_and_livestock_products 

# Downloads the FAOSTAT GLobal Aquaculture production database
$(SOURCE_DATA_DIR)/faostat/global_aquaculture_production:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data global_aquaculture_production

# World bank LCU to PPP conversion 
$(OUTPUT_DATA_DIR)world_bank/ppp_conversion.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data ppp_conversion
	Rscript --vanilla $(SCRIPT_DIR)/values/get-world-bank-ppp-conversion.R

# World Bank Population Indicator
$(PROCESSED_DATA_DIR)world_bank/population.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data population


# World Bank GDP Per Capita PPP Indicator
$(PROCESSED_DATA_DIR)world_bank/gdp_per_capita_ppp.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data gdp_per_capita_ppp

# IMF/IFS LCU to USD ($) Exchange Rates (area-weighted)
# Missing values inputted using the IMF/IFC LCU to USD ($)
# official period average exchanged rate
$(OUTPUT_DATA_DIR)world_bank/lcu_conversion.parquet:
	# Area weighed 
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data lcu_conversion
	# Average Official Exchange Rate
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data lcu_conversion_official
	# Inpute missing values
	Rscript --vanilla $(SCRIPT_DIR)/values/get-world-bank-lcu-usd-conversion.R


FAOSTATConversionFactorData:
	# TODO

#----------------------------------------
# Codes
#----------------------------------------

# Downloads the correspondence file between FAO and CPC codes 
data/codes/FAOSTAT/CPCtoFCL_codes.xlsx:
	wget -O data/codes/FAOSTAT/CPCtoFCL_codes.xlsx 'https://www.fao.org/fileadmin/templates/ess/classifications/Correspondence_CPCtoFCL.xlsx'

data/codes/FAOSTAT/FAOSTAT-CPC_cropItemCodes.rds:
	Rscript --vanilla $(SCRIPT_DIR)/codes/get-faostat-crop-codes.R 


# Subset Country Codes which are used throughout 
data/output/codes/faostat_iso3_country_codes.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/codes/get-project-country-codes.R

#-----------------------------------------
# Analysis 
# ---------------------------------------
#
# Reproduces the livestock value table
$(OUTPUT_DATA_DIR)faostat/faostat_livestock_values.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/values/get-fao-livestock-values.R
		

# Reproduces the aquaculture value table 
# Requires
#  - Global Aquaculture Production database to be downloaded
#  - LCU Conversion
#  - PPP Conversion
$(OUTPUT_DATA_DIR)fao/fao_aquaculture_values.parquet: $(SOURCE_DATA_DIR)/faostat/global_aquaculture_production \
	$(OUTPUT_DATA_DIR)/world_bank/lcu_conversion.parquet 
	Rscript --vanilla $(SCRIPT_DIR)/values/get-fao-aquaculture-values.R 

# Reproduces the crop values tables
$(OUTPUT_DATA_DIR)faostat/faostat_crop_values.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/values/get-fao-crop-values.R


#--------------------------------------
# Figures and tables 
#
# TODO: add more command line arguments
# depending on which journal the 
# submission is being made to 
# -------------------------------------
$(FIGURE_DIR)figure_2.pdf:
	Rscript --vanilla $(SCRIPT_DIR)/figures/generate-figures.R --figure 2 

$(FIGURE_DIR)figure_3.pdf:
	Rscript --vanilla $(SCRIPT_DIR)/figures/generate-figures.R --figure 3 

$(FIGURE_DIR)figure_4.pdf:
	Rscript --vanilla $(SCRIPT_DIR)/figures/generate-figures.R --figure 4 

$(FIGURE_DIR)figure_5.pdf:
	Rscript --vanilla $(SCRIPT_DIR)/figures/generate-figures.R --figure 5 

$(FIGURE_DIR)figure_6.pdf:
	Rscript --vanilla $(SCRIPT_DIR)/figures/generate-figures.R --figure 6 

#------------------------------------
# Tests
#------------------------------------
tests:
	# Make tests
