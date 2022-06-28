#!/usr/bin/env python

import pandas as pd
import requests
import csv
import sys
import datetime
from cleanFaoConversion import GBADsAPI as GBADsAPI

if __name__ == '__main__':

	# Read in all data 
	if len(sys.argv) != 4: 
		sys.exit('Please provide original live weight table as a system argument.')
	elif sys.argv[2] != 'oie' and sys.argv[2] != 'faostat':
		sys.exit('Please provide valid data source: faostat or oie')
	else: 
		file = sys.argv[1]
		data_source = sys.argv[2]
		outpath = sys.argv[3]

	try: 
		live_weight = pd.read_csv(file, encoding='utf8')
	except: 
		sys.exit('Could not read file. Ensure that the file exists and correct file path is provided.')


	# FIXME: Would be best if the years were not hard coded... 
	if data_source == 'faostat': 
		start_year = 1961
		end_year = 2017
	elif data_source == 'oie': 
		start_year = 2005
		end_year = 2017

	dfs = []

	# produce all years of data
	for year in range(start_year, end_year+1):

		data = GBADsAPI.make_custom_call(str(year), data_source)
				
		df = pd.DataFrame(data) 

		# Make first row the headers 
		header = df.iloc[0]
		df = df[1:]
		df.columns = header

		# Prep dfs for calc	
		df = pd.merge(df, live_weight, on=['country','species'], how='inner')
		df.population = pd.to_numeric(df.population, errors='coerce')

		# Calculate biomass - multiply population by liveweight
		df['biomass'] = df['population'] * df['live_weight']

		dfs.append(df)

	df_full = pd.concat(dfs)

	df_full['biomass'] = df_full['biomass'].astype(int)

	# Create outfile name 
	now = datetime.datetime.now()
	outfile = "%s/%s_biomass_liveWeight_%s.csv" % (outpath, now.strftime("%Y%m%d"), data_source)

	df_full.to_csv(outfile, index = False)
