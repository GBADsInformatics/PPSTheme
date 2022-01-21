#!/usr/bin/env python

import pandas as pd
import requests
import csv
import sys
import datetime
from cleanFaoConversion import GBADsAPI as GBADsAPI

if __name__ == '__main__':

	# Read in all data 
	if len(sys.argv) != 2: 
		sys.exit('Please provide original live weight table as a system argument.')
	else: 
		file = sys.argv[1]
		live_weight = pd.read_csv(file, encoding='utf8')

	#FIXME put this as a command line argument where can only accept options supported by API
	data_source = 'faostat' 

	dfs = []

	# produce all years of data
	for year in range(1961, 2018):

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

	# Create outfile name 
	now = datetime.datetime.now()
	outfile = "%s_biomass_liveWeight_%s.csv" % (now.strftime("%Y%m%d"), data_source)
	df_full.to_csv(outfile, index = False)


