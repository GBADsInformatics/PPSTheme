# this is a quick estimation of global livestock biomass using population data from FAOSTAT and two different sources of liveweight of species.
# One source of liveweight was the TLU concepts: each species has a conversion rate for 1 TLU and I TLU was considered as 250kg; Another source of liveweight was the 
# slaugther weight from FAO. These slaughter weights were national-specific and were updated in different years (not for all countries). 

#==== Packages and====
sessionInfo()
# install.packages("FAOSTAT")

library(FAOSTAT)
library(tidyverse)
library(Hmisc)
library(data.table)
library(sp)
library(raster)
#install.packages("tmap")
library(tmap)
 #install.packages("countrycode")
library(countrycode)

library(sf)
library(haven)
library(foreign)

getwd()
rm(list = ls())

#vignette("countrycode", package = "countrycode")
#==== load data====
#----*download from FAOSTAT: Only need do this once----
# # folder to store the data
data_folder = "data_raw3"
 dir.create(data_folder)
# 
FAOmetaTable
 fao_metadata = FAOsearch()
FAOsearch(dataset =  "stock", full =  T)
# ##Load livestock stock data: Need to know which code for population of live animals
 production_livestock <- get_faostat_bulk(code = "QCL", data_folder = data_folder)
# # Show the structure of the data
 str(production_livestock)
# 
# unique(production_livestock$item)
# unique(production_livestock$element)
# 
 production_livestock = production_livestock %>% filter(element == "Stocks")


## Cache the file i.e. save the data frame in the serialized RDS format for fast reuse later. 
# saveRDS(production_livestock, "data_raw/production_livestock_e_all_data.rds")

#----*download from FAOSTAT: Only need do this once----
 # folder to store the data
 data_folder = "data_raw_pop"
 dir.create(data_folder)
 FAOsearch(dataset =  "Population", full =  T)
##Load human population data: Need to know which code for population 
 pop <- get_faostat_bulk(code = "OA", data_folder = data_folder)
 # Show the structure of the data
 str(pop)
 
unique(pop$unit)# only use 1000 persons as the universal unit
unique(pop$area)# only use 1000 persons as the universal unit

 # pop_bothsex = pop %>% filter(element == "Total Population - Both sexes")


## Cache the file i.e. save the data frame in the serialized RDS format for fast reuse later.
 saveRDS(pop, "data_raw_pop/pop_e_all_data.rds")

#----*load data----
# Now you can load your local version of the data from the RDS file
pop <- readRDS("data_raw_pop/pop_e_all_data.rds")
 # Now you can load your local version of the data from the RDS file
 livestock <- readRDS("data_raw/production_livestock_e_all_data.rds")
 

# ## Load livestock slaughter data
# FAOsearch(dataset = "livestock",full = F)
# slau_livestock <- get_faostat_bulk(code = "QL", data_folder = data_folder)
# # Show the structure of the data
# str(slau_livestock)
# 
# # Cache the file i.e. save the data frame in the serialized RDS format for fast reuse later.
# saveRDS(slau_livestock, "data_raw/slaughtered_livestock_e_all_data.rds")
# # Now you can load your local version of the data from the RDS file
# slau.livestock <- readRDS("data_raw/slaughtered_livestock_e_all_data.rds")
# str(slau.livestock)

# ## Download World Bank data and meta-data
# WB.lst = getWDItoSYB(indicator = c("SP.POP.TOTL", "NY.GDP.MKTP.CD"),
#                      name = c("totalPopulation", "GDPUSD"),
# 
#                                           getMetaData = TRUE, printMetaData = TRUE)
# 
# str(WB.lst)
#---- check the errors----
str(livestock)

unique(livestock$area) # why there are so many Chinas and even Europe?
unique(livestock$item) # 21 species included. However, there are some overlaps between aggregated species: cattle and buffaloes? sheep and goats? poultry birds(clude chickens, ducks?)? 
unique(livestock$unit)
unique(livestock$flag) # the meaning of flags: see the dataset in FAOSTAT. There is another column named "description of flags"




livestock[livestock$item == "Cattle and Buffaloes", ] # more than 12600 records, how to deal with these values: conversion values?
livestock[livestock$item == "Sheep and Goats", ]

livestock[livestock$unit == "No", ] # about 10000 records. Looks like these are "head"?



# summary of data errors
# 1. There are some overlaps between the item. For example, there are some overlaps between aggregated species: cattle and buffaloes? sheep and goats? poultry birds(clude chickens, ducks?) vs chickens?
# For these species, need to consider what conversion values to use.
# 2. Some countries use thousand as the unit of livestock numbers, need to scale
# data to basic unit. There are also some records using "No" as the unit. Need to check what unit is it. Maybe just "head"

# scale data to basic unit
livestock[livestock$unit == "1000 Head", ]
livestock = mutate(livestock, value.new = ifelse(livestock$unit == "1000 Head", livestock$value*1000, livestock$value))

#---- conversion ratios for species and country----

# Need to consider conversion ratios for not only species but also countries. 
# There is a universal unit of LSU, which have defined the ratios of species to 1 standard tropic livestock unit. See paper: 
# Tropical Livestock Unit (TLU) defined as a mature animal weighing 250 kg (Houerou and Hoste 1977; Stotz 1983) 
# The conversion ratios of species in Kenya can be find in: http://www.fao.org/3/t0828e/T0828E07.htm

#----* conversion ratios for specie only----
unique(livestock$item)
tlu.ratio <- data.frame(item = unique(livestock$item), ratio = c(0.5, 1, 0.7, 0.01, 0.1, 0.8, 0.7, 0.1, 0.7, 0.01, 0.1, NA, NA, NA, NA, 0.2, NA, NA, NA, NA))
# Here is the source of TLU ratio: doi: 10.3389/fvets.2020.556788. Assuming: cattle and buffaloes = cattle = 0.7 TLU, poultry birds = chicken =.01; 
# NO ratio for these species:                   
# [13] "Buffaloes"              "Ducks"                 
# [15] "Geese and guinea fowls"   "Beehives"               
# [17] "Turkeys"                "Rabbits and hares"     
# [19] "Camelids, other"        "Rodents, other"        
# [21] "Pigeons, other birds"  

# NEED UPDATE: Will need update these ratios when possible. 

#----* conversion ratios for specie and country----
# OIE is using a conversion table for livestock in different continents
# Here is a conversion table from FAO, Gabriel downloaded and cleaned from FAOSTAT. The source of this table: https://www.fao.org/economic/the-statistics-division-ess/methodology/methodology-systems/technical-conversion-factors-for-agricultural-commodities/en/
fao.bodyweight <- read.csv(file = "C:/Users/li292/OneDrive - CSIRO/duty work(1)/study/R skills/animal health modeling in R/GBADs/data/faostat_conversions.csv",
                           header = T, stringsAsFactors = FALSE,na.strings=c("", "*", "-", "?")) # blank values and "*" "-" were marked as na
str(fao.bodyweight)
names(fao.bodyweight)[1] <- "id"

fao.bodyweight <- fillCountryCode("country_name", fao.bodyweight, outCode = "FAOST_CODE") # attach the fao codes for countries
unique(fao.bodyweight$FAOST_CODE)

# China was not attached with a code. Need to know if "China" here include "the mainland of China" only? if so the code for it should be 41?
fao.bodyweight$FAOST_CODE[fao.bodyweight$country_name == "China"] = 41

# # use the exiting body weight value by country to calculate the biomass
# 
# #find out which countries were not the same in the two lists of names
# 
# list1 <- unique(fao.bodyweight$country_name)
# list2 <- unique(livestock$area)
# setdiff(list1,list2) # 38 country names are not in livestock dataframe
# setdiff(list2,list1) #83 can't find in the fao.bodyweight. If there is coding system for countries? even for historical names?


#---- BIOMASS ----
str(livestock)
tlu.ratio

livestock = merge(tlu.ratio,livestock,  by = "item")
livestock = mutate(livestock, tlu = value.new*ratio, 
                   biomass = tlu*250)# unit of biomass is "kg"

head(livestock, 20)
# merge tables of live body weights and population by country and species. 
# the Country names has been standardized by using the fao coding system. However, Need to make sure the species are the same

#find out which countries were not the same in the two lists of names

list1 <- unique(fao.bodyweight$animal_en)
list2 <- unique(livestock$item)
setdiff(list1,list2) # Need to change the lower to upper for the first letter of animal names
capFirst <- function(s) {
  paste(toupper(substring(s, 1, 1)), substring(s, 2), sep = "")
}

fao.bodyweight$animal_en <- capFirst(fao.bodyweight$animal_en)
# still need to change some names

fao.bodyweight$item <- gsub('Goat', 'Goats', fao.bodyweight$animal_en)
fao.bodyweight$item <- gsub('Rabbits', 'Rabbits and hares', fao.bodyweight$animal_en) # need to note that hares may not weight the same as rabbits
fao.bodyweight$item <- gsub('Geese', 'Geese and guinea fowls', fao.bodyweight$animal_en) # guines fowl may not weight the same as geese

str(fao.bodyweight); str(livestock)
livestock$FAOST_CODE = livestock$area_code
livestock2 = merge(livestock,fao.bodyweight,   by = c("FAOST_CODE","item"))
str(livestock2)   
# biomass for stock animals
livestock2 = mutate(livestock2, biomass = value.new *live_weight)# unit of biomass is "kg"

head(livestock2, 20)


str(livestock)
unique(livestock$area) # there is a category "world"
livestock.biomass = livestock %>% 
  filter(area == "World") %>% 
  group_by(year, item) %>% 
  dplyr::summarise(livestock.biomass = sum(biomass))
head(livestock.biomass, 20)

# there are some overlaps between items in the data: cattle vs cattle and buffaloes
# Here need to exlude some items to avoid double count of livestock.biomass.
unique(livestock.biomass$item)

livestock.biomass2 = livestock.biomass %>% 
  filter(!is.na(livestock.biomass)) %>% # choose records that is not NA
  filter(!(item %in% c("Cattle", "Sheep and Goats", "Chickens"))) %>% 
  group_by(year) %>% 
  summarise(livestock.biomass =sum(livestock.biomass))
str(livestock.biomass2)


# global human biomass
# assuming average body weight of 50kg
str(pop)
unique(pop$area) # there is a category "world"
pop.biomass = pop %>% 
  filter(element == "Total Population - Both sexes") %>% 
  filter(area == "World") %>% 
  mutate(biomass = value*1000 *50)# unit of biomass is "kg"

pop.biomass

# Merge a table that combine human biomass and livestock biomass

human.animal.biomass = merge(pop.biomass,livestock.biomass2,  by = "year")
# export data table for Edna:
# write.csv(human.animal.biomass, "human and animal biomass by year raw.csv")
# ----* visulization ----
options(digits=2)

unique(livestock$area)
et.livestock = livestock[livestock$area == "Ethiopia"|livestock$area == "Ethiopia", ]
et.livestock2 = livestock2[livestock2$area == "Ethiopia"|livestock2$area == "Ethiopia", ]

str(et.livestock)
str(et.livestock2)
# show the biomass of different species by year:

ggplot(et.livestock[et.livestock$item %in% c("Asses","Cattle", "Cattle and Buffaloes", "Chickens" ,"Goats", "Sheep" , "Sheep and Goats" ),], aes( factor(year), biomass, size= 10))+
  facet_grid(~item)+
  geom_boxplot()+
  labs(y = "Total Biomass", x = "year")

ggplot(et.livestock[et.livestock$item %in% c("Cattle", "Cattle and Buffaloes"),], aes( factor(year), biomass, size= 10))+
  facet_grid(~item)+
  geom_point()+
  labs(y = "Total Biomass", x = "year") 
# "cattle and buffaloes" is the same values of "cattle"?

ggplot(et.livestock[et.livestock$item %in% c("Goats", "Sheep" , "Sheep and Goats"),], aes( factor(year), biomass, size= 10))+
  facet_grid(~item)+
  geom_point()+
  labs(y = "Total Biomass", x = "year")
# here "sheep and goat" = sum("goats", "sheep")
et.livestock %>% filter (item %in% c("Cattle"), year >= 2010 ) %>% 
  ggplot( aes( factor(year), biomass/1000000000, size= 10))+
  facet_grid(~item)+
  geom_point()+
  labs(y = "Total Biomass (Billion kg)", x = "year")+
  geom_text(aes(label=as.character(formatC(biomass/1000000000,4)),hjust=0.5, vjust=-0.5))

  
et.livestock %>% filter (item %in% c("Goats", "Sheep"), year >= 2010 ) %>% 
  ggplot( aes( factor(year), biomass/1000000000, size= 5))+
  facet_grid(~item)+
  geom_point()+
  labs(y = "Total Biomass (Billion kg)", x = "year")+
  geom_text(aes(label=as.character(formatC(biomass/1000000000,2)),hjust=0.2, vjust=-0.5), size= 4 )

# using another coversion rate for figure:
et.livestock2 %>% filter (item %in% c("Cattle"), year >= 2010 ) %>% 
  ggplot( aes( factor(year), biomass/1000000000, size= 10))+
  facet_grid(~item)+
  geom_point()+
  labs(y = "Total Biomass (Billion kg)", x = "year")+
  geom_text(aes(label=as.character(formatC(biomass/1000000000,4)),hjust=0.5, vjust=-0.5))

# using another coversion rate for figure:
et.livestock2 %>% filter (item %in% c("Goats", "Sheep"), year >= 2010 ) %>% 
  ggplot( aes( factor(year), biomass/1000000000, size= 5))+
  facet_grid(~item)+
  geom_point()+
  labs(y = "Total Biomass (Billion kg)", x = "year")+
  geom_text(aes(label=as.character(formatC(biomass/1000000000,2)),hjust=0.2, vjust=-0.5), size= 4 )


## summary: The two conversion rates have very different outputs. Need to let the users to choose which conversion rate to use.

