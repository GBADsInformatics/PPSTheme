#!/usr/bin/env python

import pandas as pd
import requests
import csv
import sys
import datetime

class GBADsAPI: 

	def make_url_table(base_url, table_name, format='csv'):
		 return("%stable_name=%s&format=%s" % (base_url, table_name, format))


	def make_call(url): 
		with requests.Session() as s:
		    download = s.get(url)

		    decoded_content = download.content.decode('utf-8')

		    cr = csv.reader(decoded_content.splitlines(), delimiter=',')
		    my_list = list(cr)	
			
		return(my_list)


	def make_custom_call(year, source, country='*'): 
		url = 'http://gbadske.org:9000/GBADsLivestockPopulation/%s?year=%s&country=%s&species=*&format=file' % (source, year, country)
		with requests.Session() as s: 
			download = s.get(url)

			decoded_content = download.content.decode('utf-8')

			cr = csv.reader(decoded_content.splitlines(), delimiter=',')
			my_list = list(cr)

		return(my_list)


if __name__ == '__main__':

	# Read in all data 
	if len(sys.argv) != 2: 
		sys.exit('Please provide original live weight table as a system argument.')
	else: 
		file = sys.argv[1]
	try:
		con_table = pd.read_csv(file, encoding='utf-8-sig')
	except: 
		sys.exit('Please provide valid file.')

	# Create name for output file
	now = datetime.datetime.now()
	outfile = "%s_weightsFAO_cleaned.csv" % (now.strftime("%Y%m%d"))

	all_countries = GBADsAPI.make_call('http://gbadske.org:9000/GBADsLivestockPopulation/faostat?year=1996&country=*&species=*&format=file')
	df = pd.DataFrame(all_countries) 

	# Make first row the headers 
	header = df.iloc[0]
	df = df[1:]
	df.columns = header

	# Get unique list of countries
	df_countries = pd.unique(df["country"])

	# First wrangle conversion table: 
	con_table.rename(columns={'country_name': 'country', 'animal_en': 'species'}, inplace = True)
	con_table = con_table.drop(columns=['carcass_pct', 'iso3'])

	# Dictionary of mappings
	country_mappings = {
		"Congo - Brazzaville": "Congo",
		"CÙte díIvoire": "Côte d'Ivoire",
		"Tanzania": "United Republic of Tanzania",
		"Congo - Kinshasa": "Democratic Republic of the Congo",
		"Antigua & Barbuda": "Antigua and Barbuda",
		"China": "China, mainland",
		"St. Kitts & Nevis": "Saint Kitts and Nevis",
		"St. Vincent & Grenadines": "Saint Vincent and the Grenadines",
		"Bosnia & Herzegovina": "Bosnia and Herzegovina",
		"Vietnam": "Viet Nam",
		"Hong Kong SAR China": "China, Hong Kong SAR",
		"S„o TomÈ & PrÌncipe": "Sao Tome and Principe",
		"Iran": "Iran (Islamic Republic of)",
		"Syria": "Syrian Arab Republic",
		"United States": "United States of America", 
		"Trinidad & Tobago": "Trinidad and Tobago",
		"Venezuela": "Venezuela (Bolivarian Republic of)",
		"St. Lucia": "Saint Lucia",
		"South Korea": "Republic of Korea",
		"Moldova": "Republic of Moldova",
		"Russia": "Russian Federation",
		"Laos": "Lao People's Democratic Republic",
		"Brunei": "Brunei Darussalam",
		"Sudan": "Sudan (former)",
		"Myanmar (Burma)": "Myanmar",
		"United Kingdom": "United Kingdom of Great Britain and Northern Ireland",
		"Belgium": "Belgium-Luxembourg",
		"Boliva": "Bolivia (Plurinational State of)",
		"North Korea": "Democratic People's Republic of Korea"
	}

	# List of countries from conversion table 
	con_table.replace({"country": country_mappings},inplace=True)
	con_countries = pd.unique(con_table["country"])

	# See which countries match between con_countries and dataset 
	match = []
	no_match = []
	for i in con_countries: 
		win = 0
		for j in df_countries: 
			if i == j: 
				win = 1
		if win != 1: 
			no_match.append(i)
		else: 
			match.append(i)

	print(no_match)

	# Remove all non-matches from the conversion table dataframe 
	con_table = con_table.set_index('country')

	# Ensure the categories are named the same 
	for i in no_match: 
	 	con_table = con_table.drop([i])

	# Make df species title case
	con_table["species"] = con_table["species"].str.title()

	# Convert grams to kg for chickens, rabbits, ducks, geese, and turkeys (divide by 1000)
	for i in ['Chickens', 'Rabbits', 'Turkeys', 'Ducks', 'Geese']:
		con_table.loc[con_table["species"] == i, "live_weight"] = con_table.loc[con_table["species"] == i, "live_weight"].divide(1000)
		con_table.loc[con_table["species"] == i, "carcass_weight"] = con_table.loc[con_table["species"] == i, "carcass_weight"].divide(1000)
	
	con_table.reset_index(level=0, inplace=True)

	# Remove double-counting of Guinea 
	rm_animal_guinea = ["ganado vacuno", "ovinos", "caprinos", "cerdos", "gallinas"]  

	for i in rm_animal_guinea: 
		index = con_table.index[ (con_table['country'] == 'Guinea') & (con_table['animal'] == i)].tolist()
		con_table = con_table.drop(index)

	# Remove China, Hong Kong SAR to avoid double counting
	con_table = con_table[con_table["country"].str.contains("China, Hong Kong SAR")==False]

	# Drop remaining unneeded columns
	con_table = con_table.drop(columns=['animal'])

	con_table = con_table.sort_values(by='country')


	# Save to outfile
	con_table.to_csv(outfile, index = False, encoding='utf-8-sig')
	 
