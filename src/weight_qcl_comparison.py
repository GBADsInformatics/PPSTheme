#!/usr/bin/env python

import pandas as pd
import requests
import csv
import sys
import datetime

def faostat_country_call(species):
	url = 'http://gbadske.org:9000/GBADsPublicQuery/livestock_countries_population_faostat?fields=iso3,country,year,species,population&query=species=\'%s\'&format=file' % species

	with requests.Session() as s:
		download = s.get(url)

		decoded_content = download.content.decode('utf-8')

		cr = csv.reader(decoded_content.splitlines(), delimiter=',')
		my_list = list(cr)	

	return(my_list)

# Read in weight data 
if len(sys.argv) < 2: 
	sys.exit('Please provide original weight table as a sys argument and provide path for outfile')
else: 
	file = sys.argv[1]
	outpath = sys.argv[2]

try: 
	weight_df = pd.read_csv(file, encoding='utf8')
except: 
	sys.exit('Could not read file. Ensure that the file exists and correct file path is provided.')

species_mapping = {
	"Geese":"Geese and guinea fowls",
	"Rabbits":"Rabbits and hares"
}

# map species so they match those used in faostat
weight_df.replace({"species": species_mapping},inplace=True)

wdf_species = weight_df.groupby('species')['iso3']

print('---- INFO ----\n')
print('This document provides a report of comparison between the weight table from FAO used for biomass and the FAOSTAT QCL data table.')
print('We compare the data available for a given country given a species as compared to FAOSTAT QCL.')

print('\n---- NUMBER OF RECORDS BY SPECIES IN WEIGHT TABLE ----\n')
print('The number of countries that report a species in the weight table.\n')
print(wdf_species.count().to_markdown())
print('\n')

species_list = pd.unique(weight_df['species'])

for species in species_list:

	data = faostat_country_call(species)
			
	df = pd.DataFrame(data) 

	# Make first row the headers 
	header = df.iloc[0]
	df = df[1:]
	df.columns = header

	# Get some info
	iso3species_count = df.groupby('iso3')['species'].count()
	w_df = weight_df.loc[weight_df['species'] == species]
	w_df = pd.unique(w_df['iso3'])

	# Diffs between sets 
	diffs = (set(w_df) ^ set(pd.unique(df['iso3'])))
	in_fao = diffs - set(w_df)
	in_weight = set(w_df) - set(pd.unique(df['iso3']))

	print('\n---- NUMBER OF %s RECORDS BY COUNTRY ----\n' % species)

	print('There are %d countries reporting %s in FAOSTAT QCL compared to %d countries in the weight table.' % ((len(pd.unique(df['iso3']))), species, len(w_df)))

	print('\n%d records occur in FAOSTAT QCL pop table but not in the weight table for this species:\n' % (len(in_fao)))

	if len(in_fao) == 0: 
		print('No difference\n')
	else:
		print('%s\n' % in_fao)
	print('%d records occur in the weight table but not in the FAOSTAT QCL pop table for this species:\n' % len(in_weight))

	if len(in_weight) == 0: 
		print('All occurences in weight table occur in FAOSTAT QCL')
	else: 
		print((set(w_df) - set(pd.unique(df['iso3']))))

	print('\n')

	print('---- NUMBER OF OCCURENCES OF SPECIES %s BY COUNTRY BETWEEN BOTH DATA TABLES ----\n' % species)
	# Prep dfs for calc	
	df = pd.merge(df, weight_df, on=['iso3','species'], how='inner')
	iso3species_count = df.groupby('iso3')['species'].count()
	print('There are %d common countries reporting %s. \n' % ((len(pd.unique(df['iso3']))), species))
	print('The list of common countries: \n%s\n' % pd.unique(df['iso3']))
	# print('A count of the number of records (number of years) of data available for %s for a given country.' % species)
	# print(df.groupby('iso3')['species'].count().to_markdown())
	print('\n')
	print('----------------------------------------------------------------------------------')

