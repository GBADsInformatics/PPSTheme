# this is a quick estimation of global livestock biomass using FAOSTAT with different average live body weights 

####packages####
sessionInfo()

# Create list of packages needed
packages = c('FAOSTAT','tidyverse','Hmisc','ggplot2','dplyr',
             'data.table','sp','raster','tmap','sf','haven',
             'foreign', 'viridis', 'hrbrthemes',"rstatix", "ggpubr")

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
# install.packages("devtools")
#devtools::install_github("hadley/bigvis")
#library(bigvis)
getwd()
setwd("C:/users/li292/OneDrive - CSIRO/duty work(1)/study/R skills/animal health modeling in R/GBADs/" )
rm(list = ls())
#==== load data====
  # #----*download livestock data from FAOSTAT: Only need do this once----
# # # folder to store the data
# data_folder = "data_raw3"
#  dir.create(data_folder)
# #
# FAOmetaTable
#  fao_metadata = FAOsearch()
# FAOsearch(dataset =  "per", full =  T)
# # ##Load livestock stock data: Need to know which code for population of live animals
#  production_livestock <- get_faostat_bulk(code = "QCL", data_folder = data_folder)
# # # Show the structure of the data
#  str(production_livestock)
# # 
# # unique(production_livestock$item)
# # unique(production_livestock$element)
# 
#  production_livestock = production_livestock %>% filter(element == "Stocks")
# ## Cache the file i.e. save the data frame in the serialized RDS format for fast reuse later. 
# # saveRDS(production_livestock, "data_raw/production_livestock_e_all_data.rds")
# 
# #----*download human population data from FAOSTAT: Only need do this once----
#  # folder to store the data
#  data_folder = "data_raw_pop"
#  dir.create(data_folder)
#  FAOsearch(dataset =  "Population", full =  T)
# ##Load human population data: Need to know which code for population 
#  pop <- get_faostat_bulk(code = "OA", data_folder = data_folder)
#  # Show the structure of the data
#  str(pop)
#  
# unique(pop$unit)# only use 1000 persons as the universal unit
# unique(pop$area)# only use 1000 persons as the universal unit
# 
#  # pop_bothsex = pop %>% filter(element == "Total Population - Both sexes")
# ## Cache the file i.e. save the data frame in the serialized RDS format for fast reuse later.
#  saveRDS(pop, "data_raw_pop/pop_e_all_data.rds")

#----*load data----
# Now you can load your local version of the data from the RDS file
# pop <- readRDS("data_raw_pop/pop_e_all_data.rds")
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

unique(livestock$area) # Please note that there were group values in area and species. Don't double count when calculating population and biomass
unique(livestock$item) # 21 species included. However, there are some overlaps between aggregated species: cattle and buffaloes? sheep and goats? poultry birds(include chickens mainly)? 
unique(livestock$unit)
unique(livestock$flag) # the meaning of flags: see the dataset in FAOSTAT. There is another column named "description of flags"


livestock[livestock$item == "Cattle and Buffaloes", ] # more than 12600 records, how to deal with these values: conversion values?
livestock[livestock$item == "Sheep and Goats", ]

livestock[livestock$unit == "No", ] # about 10000 records. Looks like these are "head"

# summary of data errors
# 1. There are some overlaps between the item. For example, there are some overlaps between aggregated species: cattle and buffaloes? sheep and goats? poultry birds(clude chickens, ducks?) vs chickens?
# For these species, need to consider what conversion values to use.
# 2. Some countries use thousand as the unit of livestock numbers, need to scale
# data to basic unit. There are also some records using "No" as the unit. Need to check what unit is it. Maybe just "head"

# scale data to basic unit
livestock[livestock$unit == "1000 Head", ]
livestock = mutate(livestock, value.new = ifelse(livestock$unit == "1000 Head", livestock$value*1000, livestock$value))

#---- liveweight for species and country----



#----* TLU conversion ratios for specie only----
# Need to consider conversion ratios for not only species but also countries. 
# There is a universal unit of TLU, which have defined the ratios of species to 1 standard tropic livestock unit. See paper: 
# Tropical Livestock Unit (TLU) defined as a mature animal weighing 250 kg (Houerou and Hoste 1977; Stotz 1983) 
# The conversion ratios of species in Kenya can be find in: http://www.fao.org/3/t0828e/T0828E07.htm

unique(livestock$item)
tlu.ratio <- data.frame(item = unique(livestock$item), ratio = c(0.5, 1, 0.7, 0.01, 0.1, 0.8, 0.7, 0.1, 0.7, 0.01, 0.1, NA, 0.7, NA, NA, 0.2, NA, NA, NA, NA))
# the ratio were from paper: doi: 10.3389/fvets.2020.556788. Assuming: cattle and buffaloes = cattle = 0.7 TLU, poultry birds = chicken =.01; 
# NO ratio for these species:                   
# [13] "Buffaloes"              "Ducks"                 
# [15] "Geese and guinea fowls"   "Beehives"               
# [17] "Turkeys"                "Rabbits and hares"     
# [19] "Camelids, other"        "Rodents, other"        
# [21] "Pigeons, other birds"  

# NEED UPDATE: Will need update these ratios when possible. 
write.csv(tlu.ratio, "TLU ratio for species.csv")

#----* liveweight for specie and country using weight of slaughtered animals----
# Here is a conversion table from FAO, Gabriel downloaded and cleaned from FAOSTAT
fao.bodyweight <- read.csv(file = "C:/Users/li292/OneDrive - CSIRO/duty work(1)/study/R skills/animal health modeling in R/GBADs/data/Appendix 1 slaughter weight faostat.csv",
                           header = T, stringsAsFactors = FALSE,na.strings=c("", "*", "-", "?")) # blank values and "*" "-" were marked as na
unique(fao.bodyweight$animal_en)

head(fao.bodyweight, 50)# need to change the body weight of chickens, turkeys, rabbits,ducks and geese as its unit is gram not kg!
# scale data to basic unit

fao.bodyweight = mutate(fao.bodyweight, live_weight = ifelse(fao.bodyweight$animal_en %in% c("chickens", "turkeys","rabbits", "ducks","geese"), fao.bodyweight$live_weight/1000, fao.bodyweight$live_weight))


unique(fao.bodyweight$country_name)# 199 countries have values. but for which species?
unique(fao.bodyweight$live_weight)# which countries don't have live weight for which species? there is a 0 in the record
names(fao.bodyweight)[1] <- "id"

fao.bodyweight <- fillCountryCode("country_name", fao.bodyweight, outCode = "FAOST_CODE") # attach the fao codes for countries
unique(fao.bodyweight$FAOST_CODE)

# China was not attached with a code. Need to know if "China" here include "the mainland of China" only? if so the code for it should be 41?
fao.bodyweight$FAOST_CODE[fao.bodyweight$country_name == "China"] = 41


#---- BIOMASS ----
#----* TLU conversion ratios for species only----
str(livestock)
tlu.ratio

livestock1 = merge(tlu.ratio,livestock,  by = "item")
livestock1 = mutate(livestock1, tlu = value.new*ratio, 
                   biomass = tlu*250)# unit of biomass is "kg"

head(livestock1, 20)
unique(livestock1$item)


# write.csv(livestock1, "biomass of stock animals using TLU by country and year.csv")
# # global livestock biomass using TLU
# livestock.biomass.tlu = livestock1 %>% 
#   filter(area == "World") %>% 
#   filter(item %in% c("Asses", "Camels","Cattle and Buffaloes",
#                      "Poultry Birds", "Goats", "Horses", "Mules", "Pigs", "Sheep")) %>%
#   group_by(year) %>% 
#   dplyr::summarise(global.biomass.tlu = sum(biomass, na.rm = T))
# head(livestock.biomass.tlu, 20)
# ----** Global livestock and human biomass using TLU method----
str(livestock)
unique(livestock$area) # there is a category "world" 210
livestock.biomass = livestock %>% 
  filter(area == "World") %>% 
  group_by(year, item) %>% 
  dplyr::summarise(livestock.pop = sum(value.new))
head(livestock.biomass, 20)

# there are some overlaps between items in the data: cattle vs cattle and buffaloes
# Here need to exclude some items to avoid double count of livestock.biomass.
unique(livestock.biomass$item)

livestock.biomass2 = livestock.biomass %>% 
  filter(!is.na(livestock.pop)) %>% # choose records that is not NA
  filter(!(item %in% c("Cattle and Buffaloes", "Sheep and Goats", "Poultry Birds"))) %>% # delete these item that already aggregated in other catrgories: "Cattle and Buffaloes", "Poultry Birds", sheep goat. Need to check the aggregated animals
  group_by(year,item) %>% 
  summarise(livestock.pop =sum(livestock.pop))
str(livestock.biomass2)
head(livestock.biomass2)



livestock.biomass3 = merge(tlu.ratio,livestock.biomass2,  by = "item")
livestock.biomass.global.species = mutate(livestock.biomass3, tlu = livestock.pop*ratio, 
                                          biomass = tlu*250) %>% group_by(year, item) %>% summarise(livestock.biomass =sum(biomass, na.rm = T))
str(livestock.biomass.global.species)# THIS calculate the biomass by species and year
unique(livestock.biomass.global.species$item)
# write.csv(livestock.biomass.global.species, "livestock_biomass_global_species.csv")
# graph for global livestock biomass 
dat = livestock.biomass.global.species %>% 
  filter(year >= 2000) %>% # choose time window
  filter((item %in% c("Cattle", "Sheep", "Goats", "Pigs", "Chickens", "Asses","Buffaloes","Camels","Horses","Mules" ))) %>% 
  group_by(year, item) %>% 
  summarise(biomass = sum(livestock.biomass, na.rm = T))
head(dat, 20);tail(dat, 20)

dat2 = livestock.biomass.global.species %>% 
  filter(year >= 2019) %>% # choose time window
  filter((item %in% c("Cattle", "Sheep", "Goats", "Pigs", "Chickens", "Asses","Buffaloes","Camels","Horses","Mules" ))) %>% 
  group_by(year, item) %>% 
  summarise(biomass = sum(livestock.biomass, na.rm = T)) 
dat2

# Compute the position of labels
dat2 <- dat2 %>% 
  arrange(desc(biomass)) %>%
  mutate(prop = biomass / sum(dat2$biomass) *100)


pie <- dat2 %>% 
  ggplot(aes(fill=item, y=biomass, x="")) + 
  geom_bar(width=1, stat="identity")+
  coord_polar("y", start=0)
pie 



  dat %>% ggplot(aes(fill=reorder(item, biomass), y=biomass/1000000000, x=year)) + 
    geom_bar(position="stack", stat="identity")+
  ggtitle( "Global livestock biomass of major species")+
  labs(y = "Total Biomass (Billion kg)", x = "year")+
  theme(plot.title = element_text(hjust = 0.5,size=20),
        axis.text=element_text(size=12),
        axis.title=element_text(size=20,face="bold"),
        legend.key.size = unit(2, 'cm'), #change legend key size
        legend.key.height = unit(1, 'cm'), #change legend key height
        legend.key.width = unit(1, 'cm'), #change legend key width
        legend.title = element_text(size=14), #change legend title font size
        legend.text = element_text(size=18)) 

  rm(dat, dat2, pie)



livestock.biomass.global = mutate(livestock.biomass3, tlu = livestock.pop*ratio, 
                                  biomass = tlu*250) %>% group_by(year) %>% summarise(livestock.biomass =sum(biomass, na.rm = T)) # this calculate global livestock biomass by year using the TLU method
# the species included in this calculation are: Asses, camel, cattle, buffalo, chicken, goat, sheep, horses, mules, pigs.            

# due to the fact that TLU table and slaughter weight table have different items covered in each, 
# to compare the values of the two ways,need to produce a global biomass for only five major species: cattle, goat, sheep, chicken and pig
livestock.biomass2new = livestock.biomass %>% 
  filter(!is.na(livestock.pop)) %>% # choose records that is not NA
  filter((item %in% c("Cattle", "Sheep", "Goats", "Pigs", "Chickens"))) %>% # delete these item that already aggregated in other catrgories: "Cattle and Buffaloes", "Poultry Birds", sheep goat. Need to check the aggregated animals
  group_by(year,item) %>% 
  summarise(livestock.pop =sum(livestock.pop))
str(livestock.biomass2new)
unique(livestock.biomass2new$item) # yes only 5 species included

livestock.biomass3new = merge(tlu.ratio,livestock.biomass2new,  by = "item")
livestock.biomass.global.speciesnew = mutate(livestock.biomass3new, tlu = livestock.pop*ratio, 
                                          biomass = tlu*250) %>% group_by(year, item) %>% summarise(livestock.biomass =sum(biomass, na.rm = T))
str(livestock.biomass.global.speciesnew)# THIS calculate the biomass by species and year

livestock.biomass.globalnew = mutate(livestock.biomass3new, tlu = livestock.pop*ratio, 
                                  biomass = tlu*250) %>% group_by(year) %>% summarise(livestock.biomass =sum(biomass, na.rm = T)) # this calculate global livestock biomass by year using the TLU method
# the species included in this calculation are:  cattle,  chicken, goat, sheep, pigs.            

write.csv(livestock.biomass.globalnew, "livestock_biomass_global_five_species.csv")
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

human.animal.biomass = merge(pop.biomass,livestock.biomass.global,  by = "year"); tail(human.animal.biomass)
# the species included in this calculation are: Asses, camel, cattle, buffalo, chicken, goat, sheep, horses, mules, pigs.            

# export data table:
# write.csv(human.animal.biomass, "human and animal biomass by year raw.csv")

#----* slaughter weight for species by country----
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
# still need to change some item names in the dataset "fao.bodyweight" 
#? why no item code for species in the dataset "fao.bodyweight". ask Gabriel 

fao.bodyweight$item <- gsub('Goat', 'Goats', fao.bodyweight$animal_en)
fao.bodyweight$item <- gsub('Rabbits', 'Rabbits and hares', fao.bodyweight$animal_en) # need to note that hares may not weight the same as rabbits. However, the dataset of slaughtered weight have aggregated the two species. 
fao.bodyweight$item <- gsub('Geese', 'Geese and guinea fowls', fao.bodyweight$animal_en) # guines fowl may not weight the same as geese

str(fao.bodyweight)

livestock$FAOST_CODE <-  livestock$area_code

livestock2 = merge(livestock,fao.bodyweight, by = c("FAOST_CODE","item"))
str(livestock2)   
# biomass for stock animals using slaughter weight
livestock2 = mutate(livestock2, biomass = value.new *live_weight)# unit of biomass is "kg"

head(livestock2, 20)
# write.csv(livestock2, "biomass of stock animals using slaughter weight by country and year.csv")
# ----* visualization ----
# ----** global livestock biomass of major species by year using two TLU and slaughter weight----

str(livestock.biomass.globalnew)# global livestock biomass TLU for 5 major species
str(livestock2) # global livestock biomass using slaughter weight by species

unique(livestock2$animal_en)
livestock.biomass.global.slau = livestock2%>%
  filter(animal_en %in% c("Cattle", "Chickens","Goats", "Pigs", "Sheep")) %>%
  group_by(year) %>% summarise(livestock.biomass.global.slau =sum(biomass, na.rm = T))
str(livestock.biomass.global.slau)

livebiomass.global= merge(livestock.biomass.global.slau, livestock.biomass.globalnew, by = "year")
head(livebiomass.global);tail(livebiomass.global)
write.csv(livebiomass.global, "global livestock biomass of five species using two methods.csv ")
livebiomass.global %>% ggplot(aes(year)) + 
  geom_point(aes(y = livestock.biomass.global.slau/1000000000, colour = "red"), size = 5)+ 
  geom_point(aes(y = livestock.biomass/1000000000, colour = "blue"), size = 5)+ 
  ggtitle( "Global livestock biomass using different live body weight")+
  labs(y = "Total Biomass (Billion kg)", x = "year")+
  theme(plot.title = element_text(hjust = 0.5, size = 20),
        axis.text=element_text(size=14),
        axis.title=element_text(size=20,face="bold"),
        legend.key.size = unit(2, 'cm'), #change legend key size
        legend.key.height = unit(2, 'cm'), #change legend key height
        legend.key.width = unit(1, 'cm'), #change legend key width
        legend.title = element_text(size=10), #change legend title font size
        legend.text = element_text(size=20)) +#change legend text font size
  scale_color_manual(name = "", labels = c( "TLU", "slaughter weight"), values = c("red","blue")) 

# ----** global livestock biomass by year and species using TLU and slaughter weight----
#----*** global sheep biomass by year and species using TLU and slaughter weight----
str(livestock.biomass.global.species)# global livestock biomass TLU
str(livestock2) # global livestock biomass using slaughter weight by species

unique(livestock.biomass.global.species$item)
unique(livestock2$item)
sheep.biomass.global.slau = livestock2%>%
  filter(animal_en %in% c( "Sheep")) %>%
  group_by(year) %>% summarise(sheep.biomass.global.slau =sum(biomass, na.rm = T))
str(sheep.biomass.global.slau)
sheep.biomass.global.tlu = livestock.biomass.global.species %>% filter(item == "Sheep")
sheepbiomass.global= merge(sheep.biomass.global.slau, sheep.biomass.global.tlu, by = c("year"))
head(sheepbiomass.global)

sheepbiomass.global %>% ggplot(aes(year)) + 
  geom_point(aes(y = sheep.biomass.global.slau/1000000000, colour = "red"), size = 5)+ 
  geom_point(aes(y = livestock.biomass/1000000000, colour = "blue"), size = 5)+ 
  ggtitle( "Global sheep biomass using different live body weight")+
  labs(y = "Total Biomass (Billion kg)", x = "year")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text=element_text(size=8),
        axis.title=element_text(size=14,face="bold"),
        legend.key.size = unit(1, 'cm'), #change legend key size
        legend.key.height = unit(1, 'cm'), #change legend key height
        legend.key.width = unit(1, 'cm'), #change legend key width
        legend.title = element_text(size=10), #change legend title font size
        legend.text = element_text(size=14)) +#change legend text font size
  scale_color_manual(name = "", labels = c( "TLU", "slaughter weight"), values = c("red","blue")) 
#----*** global chicken biomass by year and species using two TLU and slaughter weight----
str(livestock.biomass.global.species)# global livestock biomass TLU
str(livestock2) # global livestock biomass using slaughter weight by species

unique(livestock.biomass.global.species$item)
unique(livestock2$item)
chicken.biomass.global.slau = livestock2%>%
  filter(animal_en %in% c( "Chickens")) %>%
  group_by(year) %>% summarise(chicken.biomass.global.slau =sum(biomass, na.rm = T))
str(chicken.biomass.global.slau)
chicken.biomass.global.tlu = livestock.biomass.global.species %>% filter(item == "Chickens")
chickenbiomass.global= merge(chicken.biomass.global.slau, chicken.biomass.global.tlu, by = c("year"))
head(chickenbiomass.global)

chickenbiomass.global %>% ggplot(aes(year)) + 
  geom_point(aes(y = chicken.biomass.global.slau/1000000000, colour = "red"), size = 5)+ # be aware that the weight of chicken was in grams not kg!
  geom_point(aes(y = livestock.biomass/1000000000, colour = "blue"), size = 5)+ 
  ggtitle( "Global chicken biomass using different live body weight")+
  labs(y = "Total Biomass (Billion kg)", x = "year")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text=element_text(size=8),
        axis.title=element_text(size=14,face="bold"),
        legend.key.size = unit(1, 'cm'), #change legend key size
        legend.key.height = unit(1, 'cm'), #change legend key height
        legend.key.width = unit(1, 'cm'), #change legend key width
        legend.title = element_text(size=10), #change legend title font size
        legend.text = element_text(size=14)) +#change legend text font size
  scale_color_manual(name = "", labels = c( "TLU", "slaughter weight"), values = c("red","blue")) 

#----*** global pig biomass by year and species using two TLU and slaughter weight----
str(livestock.biomass.global.species)# global livestock biomass TLU
str(livestock2) # global livestock biomass using slaughter weight by species

unique(livestock.biomass.global.species$item)
unique(livestock2$item)
pig.biomass.global.slau = livestock2%>%
  filter(animal_en %in% c( "Pigs")) %>%
  group_by(year) %>% summarise(pig.biomass.global.slau =sum(biomass, na.rm = T))

pig.biomass.global.tlu = livestock.biomass.global.species %>% filter(item == "Pigs")


pigbiomass.global= merge(pig.biomass.global.slau, pig.biomass.global.tlu, by = c("year"))
head(pigbiomass.global)

pigbiomass.global %>% ggplot(aes(year)) + 
  geom_point(aes(y = pig.biomass.global.slau/1000000000, colour = "red"), size = 5)+ 
  geom_point(aes(y = livestock.biomass/1000000000, colour = "blue"), size = 5)+ 
  ggtitle( "Global pig biomass using different live body weight")+
  labs(y = "Total Biomass (Billion kg)", x = "year")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text=element_text(size=8),
        axis.title=element_text(size=14,face="bold"),
        legend.key.size = unit(1, 'cm'), #change legend key size
        legend.key.height = unit(1, 'cm'), #change legend key height
        legend.key.width = unit(1, 'cm'), #change legend key width
        legend.title = element_text(size=10), #change legend title font size
        legend.text = element_text(size=14)) +#change legend text font size
  scale_color_manual(name = "", labels = c( "TLU", "slaughter weight"), values = c("red","blue")) 
#----*** global cattle biomass by year using TLU and slaughter weight----
str(livestock.biomass.global.species)# global livestock biomass TLU
str(livestock2) # global livestock biomass using slaughter weight by species

unique(livestock.biomass.global.species$item)
unique(livestock2$item)
cattle.biomass.global.slau = livestock2%>%
  filter(animal_en %in% c( "Cattle")) %>%
  group_by(year) %>% summarise(cattle.biomass.global.slau =sum(biomass, na.rm = T))

cattle.biomass.global.tlu = livestock.biomass.global.species %>% filter(item == "Cattle")


cattlebiomass.global= merge(cattle.biomass.global.slau, cattle.biomass.global.tlu, by = c("year"))
head(cattlebiomass.global)

cattlebiomass.global %>% ggplot(aes(year)) + 
  geom_point(aes(y = cattle.biomass.global.slau/1000000000, colour = "red"), size = 5)+ 
  geom_point(aes(y = livestock.biomass/1000000000, colour = "blue"), size = 5)+ 
  ggtitle( "Global cattle biomass using different live body weight")+
  labs(y = "Total Biomass (Billion kg)", x = "year")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text=element_text(size=20),
        axis.title=element_text(size=20,face="bold"),
        legend.key.size = unit(1, 'cm'), #change legend key size
        legend.key.height = unit(1, 'cm'), #change legend key height
        legend.key.width = unit(1, 'cm'), #change legend key width
        legend.title = element_text(size=10), #change legend title font size
        legend.text = element_text(size=14)) +#change legend text font size
  scale_color_manual(name = "", labels = c( "TLU", "slaughter weight"), values = c("red","blue")) 

# ----** livestock biomass of 5 major species by country 2019 ----
str(livestock2) # global livestock biomass using slaughter weight by species
livestock2$area_code = as.character(livestock2$area_code)

str(livestock2$area)
str(livestock2$biomass)

major.country.slau <- livestock2%>%
  filter(year == 2019) %>% 
  filter(animal_en %in% c("Cattle", "Chickens","Goats", "Pigs", "Sheep"))%>%
  group_by(area, area_code)%>% mutate(biomass.major.species =sum(biomass, na.rm = T))
  
major.country.slau <- as.data.frame(major.country.slau)
major.country.slau <- major.country.slau %>%
  group_by(area, area_code)%>% 
  summarise(biomass.major.species =unique(biomass.major.species, na.rm = T))


str(major.country.slau)
pop2019 = pop %>% filter(year == 2019 & element == c("Total Population - Both sexes")) 


data = merge(pop2019, major.country.slau, by = c("area_code", "area"))
head(data, 100)
data = data %>% mutate(biomass.perCapital = biomass.major.species/(value*1000))

## Compute aggregates under the FAO continental region.
relation.df = FAOregionProfile[, c("FAOST_CODE", "UNSD_MACRO_REG")]
head(relation.df, 100)
relation.df$area_code = relation.df$FAOST_CODE
data = merge(data, relation.df, by = c("area_code"))# add continents to countries.
data$UNSD_MACRO_REG[data$area_code == 41] = "Asia" 

data %>%
  arrange(desc(value)) %>%
  mutate(country = factor(area, area)) %>%
  ggplot(aes(x=value/1000, y=biomass.major.species/1000000000, size = biomass.major.species, color = UNSD_MACRO_REG)) +
  geom_point(alpha=0.5) +
  scale_size(range = c(.1, 24), name="Population (Million)")+
  scale_fill_viridis(discrete=TRUE, guide=FALSE, option="A") +
  theme_ipsum() +
  ylab("Livestock biomass (Billion Kg)") +
  xlab("Population (Million)") +
  theme(legend.position = "none",
        axis.text.x = element_text(size=18),
        axis.text.y = element_text(size=18),
        axis.title.x = element_text(size=20,face="bold"),
        axis.title.y = element_text(size=20,face="bold"))+
  geom_text(aes(label=ifelse(biomass.major.species>18000000000,as.character(area),'')),hjust=1,vjust=0, size = 5)


## Compute aggregates under the FAO continental region-delete the top ones, so the other countries will not clustered.

data %>% filter(data$biomass.major.species < 18000000000) %>% 
  arrange(desc(value)) %>%
  mutate(country = factor(area, area)) %>%
  ggplot(aes(x=value/1000, y=biomass.major.species/1000000000, size = biomass.major.species, color = UNSD_MACRO_REG)) +
  geom_point(alpha=0.5) +
  scale_size(range = c(.1, 24), name="Population (Million)")+
  scale_fill_viridis(discrete=TRUE, guide=FALSE, option="A") +
  theme_ipsum() +
  ylab("Livestock biomass (Billion Kg)") +
  xlab("Population (Million)") +
  theme(legend.position = "none",
        axis.text.x = element_text(size=18),
        axis.text.y = element_text(size=18),
        axis.title.x = element_text(size=20,face="bold"),
        axis.title.y = element_text(size=20,face="bold"))+
  geom_text(aes(label=ifelse(biomass.major.species>5000000000|value>50000,as.character(area),'')),hjust=0,vjust=0, size = 4)

## Compute aggregates under the FAO continental region-delete the top ones, size to the biomass percapital.

data %>% filter(data$biomass.major.species < 18000000000) %>% 
  arrange(desc(value)) %>%
  mutate(country = factor(area, area)) %>%
  ggplot(aes(x=value/1000, y=biomass.major.species/1000000000, size = biomass.perCapital, color = UNSD_MACRO_REG)) +
  geom_point(alpha=0.5) +
  scale_size(range = c(.1, 24), name="Population (Million)")+
  xlim(0, 50)+
  scale_fill_viridis(discrete=TRUE, guide=FALSE, option="A") +
  theme_ipsum() +
  ylab("Livestock biomass (Billion Kg)") +
  xlab("Population (Million)") +
  theme(legend.position = "none",
        axis.text.x = element_text(size=18),
        axis.text.y = element_text(size=18),
        axis.title.x = element_text(size=20,face="bold"),
        axis.title.y = element_text(size=20,face="bold"))+
  geom_text(aes(label=ifelse(biomass.perCapital>400,as.character(area),'')),hjust=0.1,vjust=0.5, size = 4)
  

## Compute aggregates under the FAO continental region-delete the top ones, so the other countries will not clustered.

data %>% filter(biomass.perCapital > 200 & value < 50000) %>% 
  arrange(desc(value)) %>%
  mutate(country = factor(area, area)) %>%
  ggplot(aes(x=value/1000, y=biomass.major.species/1000000000, size = biomass.perCapital, color = UNSD_MACRO_REG)) +
  geom_point(alpha=0.5) +
  scale_size(range = c(.1, 24), name="Population (Million)")+
  scale_fill_viridis(discrete=TRUE, guide=FALSE, option="A") +
  theme_ipsum() +
  ylab("Livestock biomass (Billion Kg)") +
  xlab("Population (Million)") +
  theme(legend.position = "none",
        axis.text.x = element_text(size=18),
        axis.text.y = element_text(size=18),
        axis.title.x = element_text(size=20,face="bold"),
        axis.title.y = element_text(size=20,face="bold"))+
  geom_text(aes(label=ifelse(biomass.perCapital>400,as.character(area),'')),hjust=1,vjust=0, size = 2)

#rm(data)

# ----** Ethiopia livestock biomass by year using different live body weights----

options(digits=2)

unique(livestock$area)
et.livestock1 = livestock1[livestock1$area == "Ethiopia", ]# TLU for species only
et.livestock2 = livestock2[livestock2$area == "Ethiopia", ] # livebody weight table from Gabriel
#et.livestock3 = livestocktlu[livestocktlu$AreaCode == 238, ] # FAO/OIE TLU table


str(et.livestock1)
str(et.livestock2)
#str(et.livestock3)  


et.biomass =Reduce(function(x,y) merge(x = x, y = y, by = c("item_code","year")), 
       list(et.livestock1, et.livestock2))

# # show the biomass of different species by year:
# 
# ggplot(et.livestock[et.livestock$item %in% c("Asses","Cattle", "Cattle and Buffaloes", "Chickens" ,"Goats", "Sheep" , "Sheep and Goats" ),], aes( factor(year), biomass, size= 10))+
#   facet_grid(~item)+
#   geom_boxplot()+
#   labs(y = "Total Biomass", x = "year")
# 
# ggplot(et.livestock[et.livestock$item %in% c("Cattle", "Cattle and Buffaloes"),], aes( factor(year), biomass, size= 10))+
#   facet_grid(~item)+
#   geom_point()+
#   labs(y = "Total Biomass", x = "year") 
# # "cattle and buffaloes" is the same values of "cattle"?
# 
# ggplot(et.livestock[et.livestock$item %in% c("Goats", "Sheep" , "Sheep and Goats"),], aes( factor(year), biomass, size= 10))+
#   facet_grid(~item)+
#   geom_point()+
#   labs(y = "Total Biomass", x = "year")
# # here "sheep and goat" = sum("goats", "sheep")
# 
# 
# # visualize cattle biomass in ethiopia with 3 coeifficents
# # 4 figures arranged in 2 rows and 2 columns

str(et.biomass)
et.biomass2019 = et.biomass %>% filter (item.x %in% c("Cattle"), year >= 2010 )
et.biomass2019
et.biomass %>% filter (item.x %in% c("Cattle"), year >= 2010 ) %>% 
  ggplot(aes(year)) + 
  geom_point(aes(y = biomass.x/1000000000, colour = "blue", text = biomass.x/1000000000), size = 5)+
  geom_point(aes(y = biomass.y/1000000000, colour = "red"), size = 5)+ 
  ggtitle( "Cattle biomass in Ethiopia using different live body weight")+
  labs(y = "Total Biomass (Billion kg)", x = "year")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.text=element_text(size=20),
        axis.title=element_text(size=20,face="bold"),
        legend.key.size = unit(1, 'cm'), #change legend key size
        legend.key.height = unit(1, 'cm'), #change legend key height
        legend.key.width = unit(1, 'cm'), #change legend key width
        legend.title = element_text(size=10), #change legend title font size
        legend.text = element_text(size=14)) +#change legend text font size
  scale_color_manual(name = "", labels = c("TLU","slaughter weight"), values = c("red","blue")) 

# ----** Ethiopia livestock biomass by national statistic using FAO reported live body weights----
# here the population data from the AgSSLv 2020 was used. live body weight was 250 kg for a cattle in ET (value from FAO)
pop2020 = 70291776

biomass.national = pop2020*250
biomass.national


## summary: The two ways of estimating liveweight will have very different outputs. Need to let the users to choose which conversion rate to use.

# ====Dynmod for biomass and values by country====

# ----*livestock population by country----

# extract ruminant population by country in 2019
ls.country= livestock %>% filter(year == 2019) %>% filter(item %in% c("Cattle", "Sheep", "Goats") )

# add columns to make a table for Dynmod modeling by country

ls.country$milk = NA
ls.country$meat = NA
ls.country$femaleJuvenile = NA
ls.country$femaleSubAdult = NA
ls.country$femaleAdult = NA
ls.country$maleJuvenile = NA
ls.country$maleSubAdult = NA
ls.country$maleAdult = NA

ls.country$parturition = NA
ls.country$prolificacy = NA
ls.country$ProbFemale = NA

ls.country$femaleJuvenileMortality = NA
ls.country$femaleSubAdultMortality = NA
ls.country$femaleAdultMortality = NA
ls.country$maleJuvenileMortality = NA
ls.country$maleSubAdultMortality = NA
ls.country$maleAdultMortality = NA

ls.country$femaleJuvenileOfftake = NA
ls.country$femaleSubAdultOfftake = NA
ls.country$femaleAdultOfftake = NA
ls.country$maleJuvenileOfftake = NA
ls.country$maleSubAdultOfftake = NA
ls.country$maleAdultOfftake = NA
# LIVE body weight
ls.country$femaleJuvenileLBW = NA
ls.country$femaleSubAdultLBW = NA
ls.country$femaleAdultLBW = NA
ls.country$maleJuvenileLBW = NA
ls.country$maleSubAdultLBW = NA
ls.country$maleAdultLBW = NA
#carcass dressing rate
ls.country$carcassYield = NA
# values of live animals
ls.country$femaleJuvenilePrice = NA
ls.country$femaleSubAdultPrice = NA
ls.country$femaleAdultPrice = NA
ls.country$maleJuvenilePrice = NA
ls.country$maleSubAdultPrice = NA
ls.country$maleAdultPrice = NA
# milk yield
ls.country$lactationDay = NA
ls.country$milkPerDay = NA
#skin and hide
ls.country$femaleJuvenileSkin = NA
ls.country$femaleSubAdultSkin = NA
ls.country$femaleAdultSkin = NA
ls.country$maleJuvenileSkin = NA
ls.country$maleSubAdultSkin = NA
ls.country$maleAdultSkin = NA
# wool for sheep/ goat
ls.country$woolJuvenile = NA
ls.country$woolSubAdult = NA
ls.country$woolAdult = NA
#manure
ls.country$manureJuvenile = NA
ls.country$manureSubAdult = NA
ls.country$manureAdult = NA

#feed requirement
ls.country$femaleJuvenileFeed = NA
ls.country$femaleSubAdultFeed = NA
ls.country$femaleAdultFeed = NA
ls.country$maleJuvenileFeed = NA
ls.country$maleSubAdultFeed = NA
ls.country$maleAdultFeed = NA


sere.systems = c("LS", "LMS", "LGA", "LGH", "LGT", "MIA", "MIH", "MIT", "MRA", "MRH", "MRT") 
ls.country[sere.systems] <- NA

ix <- which(colnames(ls.country) %in% c("FAOST_CODE"))
clean <- ls.country[,-ix]
clean_long <- gather(clean, prodSys, pop, LS:MRT, factor_key=TRUE)
str(clean_long)
# write.csv(clean_long, "dynmod parameters by country and systems.csv") # the first column is ID
rm(sere.systems, ix, clean, clean_long)

#====BIOMASS by regions====

asianCtry = readxl::read_xlsx(path = "data/OIE list of asian countries.xlsx", sheet = "Sheet2", skip = 3)
class(asianCtry)

# ----** Global livestock biomass using TLU method----
str(livestock)
unique(livestock$area) # there is a category "world" 210
livestock.biomass.area = livestock %>% 
  group_by(year, item, area) %>% 
  dplyr::summarise(livestock.pop = sum(value.new))
head(livestock.biomass.area, 20)

# there are some overlaps between items in the data: cattle vs cattle and buffaloes
# Here need to exclude some items to avoid double count of livestock.biomass.

livestock.biomass2.area = livestock.biomass.area %>% 
  filter(!is.na(livestock.pop)) %>% # choose records that is not NA
  filter(!(item %in% c("Cattle and Buffaloes", "Sheep and Goats", "Poultry Birds"))) %>% # delete these item that already aggregated in other catrgories: "Cattle and Buffaloes", "Poultry Birds", sheep goat. Need to check the aggregated animals
  group_by(year,item, area) %>% 
  summarise(livestock.pop =sum(livestock.pop))

head(livestock.biomass2.area)



livestock.biomass3.area = merge(tlu.ratio,livestock.biomass2.area,  by = "item")
livestock.biomass.global.species.area = mutate(livestock.biomass3.area , tlu = livestock.pop*ratio, 
                                          biomass = tlu*250) %>% group_by(year, item, area) %>% summarise(livestock.biomass =sum(biomass, na.rm = T))
head(livestock.biomass.global.species.area)# THIS calculate the biomass by species and year
# write.csv(livestock.biomass.global.species, "livestock_biomass_global_species.csv")
# graph for global livestock biomass 
unique(livestock.biomass.global.species.area$area)
dat2.area = livestock.biomass.global.species.area %>% 
  filter(year == 2019 & area %in% c("World","Australia","Africa","Asia", "China, mainland", "Europe", "Northern America","South America")) %>% # choose time window
  filter((item %in% c("Cattle", "Sheep", "Goats", "Pigs", "Chickens", "Asses","Buffaloes","Camels","Horses","Mules" ))) %>% 
  group_by(year, area) %>% 
  summarise(biomass = sum(livestock.biomass, na.rm = T)) 
dat2.area

# Compute the position of labels
dat2.area <- dat2.area %>% 
  arrange(desc(biomass)) %>%
  mutate(prop = biomass / 494710296700 *100)

write.csv(dat2.area, "livestock biomass of asia and other FAO regions using TLU.csv")

rm(dat2.area)


# export data table:
# write.csv(human.animal.biomass, "human and animal biomass by year raw.csv")

#====producer prices by regions====

prodPriceCtl = read.csv(file = "data/FAOSTAT_data_producer prices of cattle in regions.csv", header = T, stringsAsFactors = FALSE,na.strings=c("", "*", "-", "?"))
class(prodPriceCtl)
str(prodPriceCtl)

# t-test to see if regional prices different 

prodPriceCtl %>%
  group_by(subRegion) %>%
  get_summary_stats(Value, type = "mean_sd")

res.aov <- prodPriceCtl %>% anova_test(Value ~ subRegion)
res.aov
# # Pairwise comparisons
pwc <- prodPriceCtl %>%
  pairwise_t_test(Value ~ subRegion, p.adjust.method = "bonferroni")
pwc


# export data table:
# write.csv(human.animal.biomass, "human and animal biomass by year raw.csv")

