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
$(PROCESSED_DATA_DIR)faostat/faostat_value_of_production.parquet:
	Rscript $(SCRIPT_DIR)/data/data-download.R --data value_of_production

$(PROCESSED_DATA_DIR)faostat/faostat_producer_prices.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data producer_prices 

$(PROCESSED_DATA_DIR)faostat/faostat_crops_and_livestock_products.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data crops_and_livestock_products 

$(PROCESSED_DATA_DIR)fao/fao_producer_prices.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/data/data-download.R --data global_aquaculture_production

FAOSTATConversionFactorData:
	# Fao Conversion factors
	
#-----------------------------------------
# Analysis 
# ---------------------------------------
#
# Reproduces the livestock value table
$(PROCESSED_DATA_DIR)faostat/faostat_livestock_values.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/values/20220204_getFAOLivestockValues.R
		

# Reproduces the aquaculture value table 
$(PROCESSED_DATA_DIR)fao/fao_global_aquaculture_production_values.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/values/20220201_getFAOAquacultureValues.R 

# Reproduces the crop values tables
$(PROCESSED_DATA_DIR)faostat/faostat_crop_values.parquet:
	Rscript --vanilla $(SCRIPT_DIR)/values/20220201_getFAOCropValues.R


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
