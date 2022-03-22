# Makefile to make all analysis targets in this project

# Variables
R_DIR=R/
SCRIPT_DIR=inst/
SOURCE_DATA_DIR=data/source/
PROCESSED_DATA_DIR=data/processed/
FIGURE_DIR=output/figures/
TABLE_DIR=output/tables/

#-----------------------------------------
# Data
#
# Downloads the latest datasets
# ---------------------------------------
$(PROCESSED_DATA_DIR)faostat/value_of_production.parquet:
	Rscript $(SCRIPT_DIR)/data/data-download.R --data value_of_production

$(PROCESSED_DATA_DIR)faostat/producer_prices.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data producer_prices 

$(PROCESSED_DATA_DIR)faostat/crops_and_livestock_products.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data crops_and_livestock_products 

global_aquaculture_production:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data global_aquaculture_production

$(PROCESSED_DATA_DIR)world_bank/ppp_conversion.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data ppp_conversion

$(PROCESSED_DATA_DIR)world_bank/population.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data population

FAOSTATConversionFactorData:
	# Fao Conversion factors

#----------------------------------------
# Codes
#----------------------------------------
data/codes/FAOSTAT/FAOSTAT-CPC_cropItemCodes.rds:
	Rscript --vanilla $(SCRIPT_DIR)/codes/get-faostat-crop-codes.R 

#-----------------------------------------
# Analysis 
# ---------------------------------------
#
# Reproduces the livestock value table
$(PROCESSED_DATA_DIR)faostat/faostat_livestock_values.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/values/getFAOLivestockValues.R
		

# Reproduces the aquaculture value table 
$(PROCESSED_DATA_DIR)fao/fao_global_aquaculture_production_values.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/values/getFAOAquacultureValues.R 

# Reproduces the crop values tables
$(PROCESSED_DATA_DIR)faostat/faostat_crop_values.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/values/getFAOCropValues.R


#--------------------------------------
# Figures and tables 
# -------------------------------------
$(FIGURE_DIR)figure%.png:
	Rscript --vanilla $(SCRIPT_DIR)/figures/generate-figures.R --figure 

$(TABLE_DIR)table%.png: 
	Rscript --vanilla $(SCRIPT_DIR)/tables/generate-tables.R --table

#------------------------------------
# Tests
#------------------------------------
tests:
	# Make tests
