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

if __name__ == '__main__':

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

	species_list = pd.unique(weight_df['species'])
	dfs = []

	for species in species_list:

		data = faostat_country_call(species)
				
		df = pd.DataFrame(data) 

		# Make first row the headers 
		header = df.iloc[0]
		df = df[1:]
		df.columns = header
		df = pd.merge(df, weight_df, on=['iso3','species'], how='inner')
		dfs.append(df)

	df_full = pd.concat(dfs)
	df_full = df_full.drop(['carcass_weight', 'country_y', 'animal', 'carcass_pct'], axis=1)
	df_full.population = pd.to_numeric(df_full.population, errors='coerce')
	df_full['biomass'] = df_full['population'] * df_full['live_weight']
	df_full['biomass'] = df_full['biomass'].astype(int)

	now = datetime.datetime.now()
	outfile = "%s/%s_biomass_live_weight_fao.csv" % (outpath, now.strftime("%Y%m%d"))

	df_full.to_csv(outfile, index = False)
