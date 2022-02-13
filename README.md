GBADS - Livestock Value
================

<!-- README.md is generated from README.Rmd. Please edit that file -->

[![License: CC BY-SA
4.0](https://img.shields.io/badge/license-CC%20BY--SA%204.0-blue.svg)](https://cran.r-project.org/web/licenses/CC%20BY-SA%204.0)
[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

# Description

This repository contains all R code and data for the *GBADS* global
livestock value estimation manuscript.

## Files

    #> DESCRIPTION
    #> LICENSE.md
    #> NAMESPACE
    #> PPSTheme.Rproj
    #> R/mmage_funcs.R
    #> R/scripts/20220201_getFAOAquacultureValues.R
    #> R/scripts/20220201_getFAOCropValues.R
    #> R/scripts/20220204_getFAOLivestockValues.R
    #> R/utils/FAOSTAT_helper_functions.R
    #> R/utils/conversion_functions.R
    #> R/utils/data_loading_functions.R
    #> R/utils/functions.R
    #> README.Rmd
    #> README.md
    #> data/.gitignore
    #> data/FAOSTAT.dvc
    #> data/FAO_Global_Aquaculture_Production.dvc
    #> data/codes/FAOSTAT/20211021_FAOSTAT_Country_Codes.csv
    #> data/codes/FAOSTAT/20211021_FAOSTAT_Item_Codes.csv
    #> data/codes/FAOSTAT/FAOSTAT_Country_Codes.rds
    #> data/codes/FAOSTAT/FAOSTAT_Crop_Item_Codes.Rds
    #> data/codes/FAOSTAT/FAOSTAT_Item_Codes.rds
    #> data/codes/FAOSTAT/FAOSTAT_Livestock_Codes.rds
    #> data/codes/FAOSTAT/FAOSTAT_Livestock_Meat_Item_Codes.rds
    #> data/codes/FAOSTAT/FAOSTAT_Meat_Live_Weight_Codes.rds
    #> data/codes/FAOSTAT/FAOSTAT_Vop_Item_Codes.Rds
    #> data/codes/FAOSTAT/FAOSTAT_Vop_Items_Non-Indigenous_Codes.Rds
    #> data/output.dvc
    #> docs/global-value-livestock-aquaculture.Rmd
    #> mmage_2.4-3.tar.gz
    #> references.bib
    #> renv.lock
    #> renv/.gitignore
    #> renv/activate.R

# Data

## Version Control

Currently the data contained in this repository is tracked using the
tool [dvc](https://dvc.org/).

### Aquaculture (FAO[1])

-   Conversions to liveweights are done using country specific numbers.

| iso3_code          | faost_code        | name_en       | species_code       | year                | tonnes                       | value_1000_usd                           | exchange_rate             | slc_price                                                          | mean_2014_2016_slc_price                | mean_2014_2016_exchange                                         | aquaculture_constant_2014_2016_usd_price                                                                                | aquaculture_constant_2014_2016_constant_usd_value   | date     | contributor                                     | format      | language | source                                                                                                                                                                      |
|:-------------------|:------------------|:--------------|:-------------------|:--------------------|:-----------------------------|:-----------------------------------------|:--------------------------|:-------------------------------------------------------------------|:----------------------------------------|:----------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------|:----------------------------------------------------|:---------|:------------------------------------------------|:------------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ISO 3166-1 alpha-3 | FAOSTAT Area Code | FAO Area Name | ASFIS Species Code | Year in YYYY format | Metric Tonnes of live weight | Current value in thousands of US dollars | FAO Exchange rate for SLC | SLC prices per tonne calculated using the FAO annual exchange rate | Average SCL price between 2014 and 2016 | Average exchange rate between SLC and USD between 2014 and 2016 | Constant prices per tonne of aquaculture using the 2014-2016 SLC prices and the mean exchange rates for the same period | Constant prices multiplied by production quantities | 20220204 | Gabriel Dennis CSIRO, <gabriel.dennis@csiro.au> | Arrow Table | English  | FAO.GLOBAL AQUACULTURE PRODUCTION. License: CC BY–NC–SA 3.0 IGO. Extracted from: <https://www.fao.org/fishery/statistics-query/en/aquaculture>. Data of Access: 2022-02-01. |

Table: Metadata

    #> The data contains 41025 observations of the following 13 variables:
    #>   - iso3_code: 206 entries, such as CHN (4.20%); TWN (3.08%); KOR (3.04%) and 203 others (126 missing)
    #>   - faost_code: n = 41025, Mean = 122.47, SD = 70.13, Median = , MAD = 88.96, range: [1, 299], Skewness = 0.08, Kurtosis = -1.10, 5.10% missing
    #>   - name_en: 208 entries, such as China (4.20%); Taiwan Province of China (3.08%); Korea, Republic of (3.04%) and 205 others (0 missing)
    #>   - species_code: 615 entries, such as FCP (4.96%); TRR (4.33%); TLN (4.06%) and 612 others (0 missing)
    #>   - year: n = 41025, Mean = 2007.87, SD = 7.28, Median = 2009.00, MAD = 8.90, range: [1994, 2019], Skewness = -0.23, Kurtosis = -1.08, 0% missing
    #>   - tonnes: n = 41025, Mean = 43636.60, SD = 3.16e+05, Median = 268.00, MAD = 394.37, range: [2.00e-03, 10978362], Skewness = 16.50, Kurtosis = 375.12, 0% missing
    #>   - value_1000_usd: n = 41025, Mean = 78012.63, SD = 4.83e+05, Median = 948.83, MAD = 1394.37, range: [8.00e-03, 1.82e+07], Skewness = 15.03, Kurtosis = 308.26, 0% missing
    #>   - exchange_rate: n = 41025, Mean = 18505.92, SD = 1.16e+06, Median = , MAD = 8.81, range: [1.17e-04, 7.64e+07], Skewness = 65.75, Kurtosis = 4321.28, 5.10% missing
    #>   - slc_price: n = 41025, Mean = 6988.84, SD = 2.37e+05, Median = , MAD = 641.87, range: [5.24e-06, 2.30e+07], Skewness = 89.02, Kurtosis = 8365.49, 5.10% missing
    #>   - mean_2014_2016_slc_price: n = 41025, Mean = 3293.30, SD = 16304.94, Median = , MAD = 561.58, range: [7.47e-03, 7.28e+05], Skewness = 36.20, Kurtosis = 1583.82, 16.07% missing
    #>   - mean_2014_2016_exchange: n = 41025, Mean = 955.31, SD = 3598.76, Median = , MAD = 9.99, range: [0.30, 28622.67], Skewness = 5.23, Kurtosis = 29.69, 5.12% missing
    #>   - aquaculture_constant_2014_2016_usd_price: n = 41025, Mean = 21540.56, SD = 3.16e+05, Median = , MAD = 3066.91, range: [24.27, 7.08e+06], Skewness = 21.13, Kurtosis = 448.05, 16.07% missing
    #>   - aquaculture_constant_2014_2016_constant_usd_value: n = 41025, Mean = 1.14e+08, SD = 6.14e+08, Median = , MAD = 2.26e+06, range: [7.56, 1.81e+10], Skewness = 11.32, Kurtosis = 169.02, 16.07% missing

|     | Variable                                          | n_Obs | percentage_Missing |         Mean |           SD |   Median |          MAD |          Min |          Max |   Skewness |    Kurtosis | n_Entries | n_Missing |
|:----|:--------------------------------------------------|------:|-------------------:|-------------:|-------------:|---------:|-------------:|-------------:|-------------:|-----------:|------------:|----------:|----------:|
| 6   | iso3_code                                         | 41025 |          0.3071298 |           NA |           NA |       NA |           NA |           NA |           NA |         NA |          NA |       206 |       126 |
| 8   | faost_code                                        | 41025 |          5.0968921 | 1.224742e+02 | 7.012797e+01 |       NA | 8.895600e+01 |    1.0000000 | 2.990000e+02 |  0.0810013 |   -1.095632 |        NA |        NA |
| 1   | name_en                                           | 41025 |          0.0000000 |           NA |           NA |       NA |           NA |           NA |           NA |         NA |          NA |       208 |         0 |
| 2   | species_code                                      | 41025 |          0.0000000 |           NA |           NA |       NA |           NA |           NA |           NA |         NA |          NA |       615 |         0 |
| 5   | year                                              | 41025 |          0.0000000 | 2.007866e+03 | 7.277978e+00 | 2009.000 | 8.895600e+00 | 1994.0000000 | 2.019000e+03 | -0.2319707 |   -1.083225 |        NA |        NA |
| 3   | tonnes                                            | 41025 |          0.0000000 | 4.363660e+04 | 3.156720e+05 |  268.000 | 3.943716e+02 |    0.0020000 | 1.097836e+07 | 16.5009277 |  375.117197 |        NA |        NA |
| 4   | value_1000_usd                                    | 41025 |          0.0000000 | 7.801263e+04 | 4.825715e+05 |  948.833 | 1.394375e+03 |    0.0080000 | 1.815239e+07 | 15.0308738 |  308.260905 |        NA |        NA |
| 7   | exchange_rate                                     | 41025 |          5.0968921 | 1.850592e+04 | 1.161012e+06 |       NA | 8.811921e+00 |    0.0001174 | 7.636994e+07 | 65.7488843 | 4321.276253 |        NA |        NA |
| 9   | slc_price                                         | 41025 |          5.0968921 | 6.988845e+03 | 2.368969e+05 |       NA | 6.418679e+02 |    0.0000052 | 2.299476e+07 | 89.0232802 | 8365.493233 |        NA |        NA |
| 13  | mean_2014_2016_slc_price                          | 41025 |         16.0658135 | 3.293304e+03 | 1.630494e+04 |       NA | 5.615838e+02 |    0.0074699 | 7.276670e+05 | 36.2045466 | 1583.823899 |        NA |        NA |
| 10  | mean_2014_2016_exchange                           | 41025 |          5.1163924 | 9.553054e+02 | 3.598757e+03 |       NA | 9.986088e+00 |    0.2958489 | 2.862267e+04 |  5.2341299 |   29.686403 |        NA |        NA |
| 12  | aquaculture_constant_2014_2016_usd_price          | 41025 |         16.0658135 | 2.154056e+04 | 3.155164e+05 |       NA | 3.066910e+03 |   24.2674416 | 7.078235e+06 | 21.1264617 |  448.053793 |        NA |        NA |
| 11  | aquaculture_constant_2014_2016_constant_usd_value | 41025 |         16.0658135 | 1.138805e+08 | 6.143593e+08 |       NA | 2.259051e+06 |    7.5590854 | 1.810283e+10 | 11.3150964 |  169.024438 |        NA |        NA |

### FAOSTAT

#### Crop Production and Values FAO[2]

| iso3_code          | faost_code        | area              | year                | tonnes        | producer_price_index_2014_2016_100                                                                        | producer_price_lcu_tonne                           | producer_price_slc_tonne                              | producer_price_usd_tonne                        | gross_production_value_constant_2014_2016_thousand_i                                                                                                    | gross_production_value_constant_2014_2016_thousand_slc                                                                                                             | gross_production_value_constant_2014_2016_thousand_us                                                                                        | gross_production_value_current_thousand_slc                                                                                                          | gross_production_value_current_thousand_us                    | date     | contributor                                     | format      | language | source                                                                                                                             |
|:-------------------|:------------------|:------------------|:--------------------|:--------------|:----------------------------------------------------------------------------------------------------------|:---------------------------------------------------|:------------------------------------------------------|:------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------|:---------|:------------------------------------------------|:------------|:---------|:-----------------------------------------------------------------------------------------------------------------------------------|
| ISO 3166-1 alpha-3 | FAOSTAT Area Code | FAOSTAT Area Name | Year in YYYY format | Metric Tonnes | An FAOSTAT Items producer price index, for a certain item calculated to average 100 between 2014 and 2016 | Producer price of item in local currency per tonne | Producer price of item in national currency per tonne | Producer price of item in current USD per tonne | Gross production value of item in constant thousand 2014 2016 international dollars, for a certain item calculated to average 100 between 2014 and 2016 | Gross production value of item in constant 2014 2016 in thousand standard local currency units, for a certain item calculated to average 100 between 2014 and 2016 | Gross production value of item in constant thousand 2014 2016 US dollars, for a certain item calculated to average 100 between 2014 and 2016 | Gross production value of item in current thousand standard local currency units, for a certain item calculated to average 100 between 2014 and 2016 | Gross production value of item in current thousand US dollars | 20220201 | Gabriel Dennis CSIRO, <gabriel.dennis@csiro.au> | Arrow Table | English  | \[FAO.\] \[Database Title.\] \[Dataset Title.\] \[Latest update: Day/month/year.\] \[(Accessed \[Day/month/year).\] \[URL or URI\] |

    #> The data contains 235302 observations of the following 17 variables:
    #>   - iso3_code: 203 entries, such as chn (1.25%); mex (1.22%); esp (1.10%) and 200 others (0 missing)
    #>   - faost_code: n = 235302, Mean = 127.87, SD = 73.20, Median = 123.00, MAD = 93.40, range: [1, 299], Skewness = 0.05, Kurtosis = -1.04, 0% missing
    #>   - area: 202 entries, such as china (1.25%); mexico (1.22%); spain (1.10%) and 199 others (2041 missing)
    #>   - item_code: n = 235302, Mean = 364.57, SD = 186.62, Median = 397.00, MAD = 229.80, range: [15, 723], Skewness = -0.14, Kurtosis = -1.05, 0% missing
    #>   - item: 148 entries, such as vegetables_fresh_nes (2.11%); maize (1.85%); tomatoes (1.84%) and 145 others (78 missing)
    #>   - group: 8 entries, such as fruits_nuts (29.33%); vegetables (27.08%); cereals (11.30%) and 5 others (0 missing)
    #>   - year: n = 235302, Mean = 2006.70, SD = 7.49, Median = 2007.00, MAD = 8.90, range: [1994, 2019], Skewness = -0.02, Kurtosis = -1.20, 0% missing
    #>   - tonnes: n = 235302, Mean = 8.46e+05, SD = 9.54e+06, Median = , MAD = 24922.51, range: [0, 768594154], Skewness = 41.00, Kurtosis = 2421.78, 5.53% missing
    #>   - producer_price_index_2014_2016_100: n = 235302, Mean = 132.11, SD = 5467.18, Median = , MAD = 37.06, range: [0, 1826612], Skewness = 233.25, Kurtosis = 71163.58, 23.03% missing
    #>   - producer_price_lcu_tonne: n = 235302, Mean = 3.25e+06, SD = 6.00e+07, Median = , MAD = 6399.64, range: [8, 6030622000], Skewness = 42.89, Kurtosis = 2676.77, 56.38% missing
    #>   - producer_price_slc_tonne: n = 235302, Mean = 4.43e+05, SD = 6.58e+06, Median = , MAD = 3851.79, range: [0, 911729000], Skewness = 74.76, Kurtosis = 8171.27, 56.40% missing
    #>   - producer_price_usd_tonne: n = 235302, Mean = 868.08, SD = 1443.33, Median = , MAD = 401.78, range: [1, 72627], Skewness = 10.04, Kurtosis = 252.49, 57.38% missing
    #>   - gross_production_value_constant_2014_2016_thousand_i: n = 235302, Mean = 2.22e+05, SD = 1.76e+06, Median = , MAD = 13064.67, range: [0, 83171068], Skewness = 25.38, Kurtosis = 855.73, 7.02% missing
    #>   - gross_production_value_constant_2014_2016_thousand_slc: n = 235302, Mean = 3.77e+08, SD = 7.57e+09, Median = , MAD = 2.70e+05, range: [0, 546895942887], Skewness = 50.09, Kurtosis = 2985.10, 24.44% missing
    #>   - gross_production_value_constant_2014_2016_thousand_us: n = 235302, Mean = 3.04e+05, SD = 2.34e+06, Median = , MAD = 19299.00, range: [0, 104717097], Skewness = 23.69, Kurtosis = 752.73, 26.15% missing
    #>   - gross_production_value_current_thousand_slc: n = 235302, Mean = 7.77e+10, SD = 2.63e+13, Median = , MAD = 1.73e+05, range: [0, 10556762563058048], Skewness = 387.15, Kurtosis = 1.54e+05, 28.62% missing
    #>   - gross_production_value_current_thousand_us: n = 235302, Mean = 2.58e+05, SD = 2.07e+06, Median = , MAD = 16142.55, range: [0, 127058656], Skewness = 27.25, Kurtosis = 1035.63, 30.62% missing

|     | Variable                                               |  n_Obs | percentage_Missing |         Mean |           SD | Median |         MAD |  Min |          Max |    Skewness |      Kurtosis | n_Entries | n_Missing |
|:----|:-------------------------------------------------------|-------:|-------------------:|-------------:|-------------:|-------:|------------:|-----:|-------------:|------------:|--------------:|----------:|----------:|
| 3   | iso3_code                                              | 235302 |          0.0000000 |           NA |           NA |     NA |          NA |   NA |           NA |          NA |            NA |       203 |         0 |
| 1   | faost_code                                             | 235302 |          0.0000000 | 1.278678e+02 | 7.319916e+01 |    123 |     93.4038 |    1 | 2.990000e+02 |   0.0515483 |     -1.042242 |        NA |        NA |
| 7   | area                                                   | 235302 |          0.8673959 |           NA |           NA |     NA |          NA |   NA |           NA |          NA |            NA |       202 |      2041 |
| 4   | item_code                                              | 235302 |          0.0000000 | 3.645653e+02 | 1.866241e+02 |    397 |    229.8030 |   15 | 7.230000e+02 |  -0.1400328 |     -1.046834 |        NA |        NA |
| 6   | item                                                   | 235302 |          0.0331489 |           NA |           NA |     NA |          NA |   NA |           NA |          NA |            NA |       148 |        78 |
| 2   | group                                                  | 235302 |          0.0000000 |           NA |           NA |     NA |          NA |   NA |           NA |          NA |            NA |         8 |         0 |
| 5   | year                                                   | 235302 |          0.0000000 | 2.006702e+03 | 7.493762e+00 |   2007 |      8.8956 | 1994 | 2.019000e+03 |  -0.0241628 |     -1.197112 |        NA |        NA |
| 8   | tonnes                                                 | 235302 |          5.5273648 | 8.463472e+05 | 9.535437e+06 |     NA |  24922.5060 |    0 | 7.685942e+08 |  40.9980075 |   2421.782133 |        NA |        NA |
| 10  | producer_price_index_2014_2016_100                     | 235302 |         23.0333784 | 1.321102e+02 | 5.467185e+03 |     NA |     37.0650 |    0 | 1.826612e+06 | 233.2463075 |  71163.578293 |        NA |        NA |
| 15  | producer_price_lcu_tonne                               | 235302 |         56.3803113 | 3.254386e+06 | 5.995170e+07 |     NA |   6399.6429 |    8 | 6.030622e+09 |  42.8910619 |   2676.766400 |        NA |        NA |
| 16  | producer_price_slc_tonne                               | 235302 |         56.3994356 | 4.427112e+05 | 6.576198e+06 |     NA |   3851.7948 |    0 | 9.117290e+08 |  74.7575606 |   8171.265930 |        NA |        NA |
| 17  | producer_price_usd_tonne                               | 235302 |         57.3769029 | 8.680791e+02 | 1.443329e+03 |     NA |    401.7846 |    1 | 7.262700e+04 |  10.0439641 |    252.488875 |        NA |        NA |
| 9   | gross_production_value_constant_2014_2016_thousand_i   | 235302 |          7.0241647 | 2.215318e+05 | 1.759735e+06 |     NA |  13064.6712 |    0 | 8.317107e+07 |  25.3783120 |    855.728138 |        NA |        NA |
| 11  | gross_production_value_constant_2014_2016_thousand_slc | 235302 |         24.4400813 | 3.767294e+08 | 7.569565e+09 |     NA | 269987.3904 |    0 | 5.468959e+11 |  50.0912747 |   2985.096897 |        NA |        NA |
| 12  | gross_production_value_constant_2014_2016_thousand_us  | 235302 |         26.1497990 | 3.039650e+05 | 2.335384e+06 |     NA |  19299.0042 |    0 | 1.047171e+08 |  23.6856483 |    752.729610 |        NA |        NA |
| 13  | gross_production_value_current_thousand_slc            | 235302 |         28.6215162 | 7.771958e+10 | 2.633606e+13 |     NA | 173118.7542 |    0 | 1.055676e+16 | 387.1506410 | 154029.791746 |        NA |        NA |
| 14  | gross_production_value_current_thousand_us             | 235302 |         30.6248991 | 2.580833e+05 | 2.066523e+06 |     NA |  16142.5488 |    0 | 1.270587e+08 |  27.2542318 |   1035.632786 |        NA |        NA |

#### Livestock Production and Values (FAO[3])

| iso3_code          | faost_code        | area              | year                | item_code         | item                                     | animal                          | head              | tonnes        | gross_production_value_constant_2014_2016_thousand_i                                                                                                    | gross_production_value_constant_2014_2016_thousand_slc                                                                                                             | gross_production_value_constant_2014_2016_thousand_us                                                                                        | gross_production_value_current_thousand_slc                                                                                                          | gross_production_value_current_thousand_us                    | producer_price_index_2014_2016_100                                                                        | producer_price_lcu_tonne                           | producer_price_slc_tonne                              | producer_price_usd_tonne                        | yield_kg                                                 | carcass_pct                     | lbw_kg                                                                             | stock_value_lcu                                                                                  | stock_value_slc                                                                                     | stock_value_usd                                                                        | mean_slc_price_per_tonne_2014_2016                  | mean_usd_conversion_2014_2016                                                           | producer_price_usd_per_tonne_2014_2016                                                                             | stock_value_constant_2014_2016_usd                                                                                      | date     | contributor                                     | format      | language | source                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | year_range        | frequency |
|:-------------------|:------------------|:------------------|:--------------------|:------------------|:-----------------------------------------|:--------------------------------|:------------------|:--------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------|:----------------------------------------------------------------------------------------------------------|:---------------------------------------------------|:------------------------------------------------------|:------------------------------------------------|:---------------------------------------------------------|:--------------------------------|:-----------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------|:----------------------------------------------------|:----------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------|:---------|:------------------------------------------------|:------------|:---------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:------------------|:----------|
| ISO 3166-1 alpha-3 | FAOSTAT Area Code | FAOSTAT Area Name | Year in YYYY format | FAOSTAT item code | FAOSTAT production item name (lowercase) | english name for livestock type | Number of animals | Metric Tonnes | Gross production value of item in constant thousand 2014 2016 international dollars, for a certain item calculated to average 100 between 2014 and 2016 | Gross production value of item in constant 2014 2016 in thousand standard local currency units, for a certain item calculated to average 100 between 2014 and 2016 | Gross production value of item in constant thousand 2014 2016 US dollars, for a certain item calculated to average 100 between 2014 and 2016 | Gross production value of item in current thousand standard local currency units, for a certain item calculated to average 100 between 2014 and 2016 | Gross production value of item in current thousand US dollars | An FAOSTAT Items producer price index, for a certain item calculated to average 100 between 2014 and 2016 | Producer price of item in local currency per tonne | Producer price of item in national currency per tonne | Producer price of item in current USD per tonne | Animal yield/carcass weight calculated from FAOSTAT data | FAO carcass % conversion factor | Adult live body weight equivalent in kg, calculated via yield_kg/(carcass_pct/100) | Value of animal stock in local currency units, calculated via producer_price_lcu_tonne \* tonnes | Value of animal stock in standard currency units, calculated via producer_price_slc_tonne \* tonnes | Value of animal stock in US dollars, calculated via producer_price_usd_tonne \* tonnes | mean slc price per tonne averaged over 2014 to 2016 | Mean conversion of slc to US dollars from 2014 to 2016 using the annual exchange rantes | Producer price per tonne in USD, calculated via mean_slc_price_per_tonne_2014_2016 / mean_usd_conversion_2014_2016 | Value of animal stock in constant 2014 2016 US dollars, calculated via producer_price_usd_per_tonne_2014_2016 \* tonnes | 20220211 | Gabriel Dennis CSIRO, <gabriel.dennis@csiro.au> | Arrow Table | English  | \[FAO.\] Crops and livestock products.\[Accessed 2022-01-28.\] <https://fenixservices.fao.org/faostat/static/bulkdownloads/Production_Crops_Livestock_E_All_Data_(Normalized).zip> - - \[FAO.\] Value of Agricultural Production.\[Accessed 2022-01-28.\]<https://fenixservices.fao.org/faostat/static/bulkdownloads/Value_of_Production_E_All_Data_(Normalized).zip> - - \[FAO.\] Prices: Producer Prices.\[Accessed 2022-01-28.\] <http://fenixservices.fao.org/faostat/static/bulkdownloads/Prices_E_All_Data_(Normalized).zip> | From:1996 to 1997 | Yearly    |

    #> The data contains 131219 observations of the following 27 variables:
    #>   - iso3_code: 202 entries, such as chn (0.90%); egy (0.83%); tur (0.82%) and 199 others (48 missing)
    #>   - faost_code: n = 131219, Mean = 126.62, SD = 72.77, Median = , MAD = 94.89, range: [1, 299], Skewness = 0.02, Kurtosis = -1.09, 0.04% missing
    #>   - area: 201 entries, such as china (0.90%); egypt (0.83%); turkey (0.82%) and 198 others (609 missing)
    #>   - item: 6 entries, such as stock (30.78%); meat (26.80%); offals (15.76%) and 3 others (48 missing)
    #>   - animal: 24 entries, such as cattle (17.37%); goat (14.82%); sheep (14.43%) and 21 others (48 missing)
    #>   - year: n = 131219, Mean = 2007.56, SD = 6.91, Median = , MAD = 8.90, range: [1996, 2019], Skewness = -9.86e-03, Kurtosis = -1.20, 0.04% missing
    #>   - head: n = 131219, Mean = 2.74e+08, SD = 6.75e+09, Median = , MAD = 4.78e+05, range: [0, 569077421000], Skewness = 59.67, Kurtosis = 4007.65, 11.96% missing
    #>   - tonnes: n = 131219, Mean = 3.66e+05, SD = 2.99e+06, Median = , MAD = 7497.99, range: [0, 1.38e+08], Skewness = 20.50, Kurtosis = 549.04, 9.19% missing
    #>   - yield_kg: n = 131219, Mean = 61.79, SD = 84.76, Median = , MAD = 20.46, range: [0, 457.80], Skewness = 1.57, Kurtosis = 1.80, 76.45% missing
    #>   - carcass_pct: n = 131219, Mean = 0.61, SD = 0.13, Median = , MAD = 0.15, range: [0.31, 0.97], Skewness = 0.23, Kurtosis = -1.45, 78.04% missing
    #>   - lbw_kg: n = 131219, Mean = 146.19, SD = 170.92, Median = , MAD = 56.44, range: [0, 900], Skewness = 0.85, Kurtosis = -0.58, 71.69% missing
    #>   - gross_production_value_constant_2014_2016_thousand_i: n = 131219, Mean = 5.19e+05, SD = 2.54e+06, Median = , MAD = 34351.84, range: [3, 49196398], Skewness = 10.27, Kurtosis = 128.69, 85.90% missing
    #>   - gross_production_value_constant_2014_2016_thousand_slc: n = 131219, Mean = 6.50e+08, SD = 7.53e+09, Median = , MAD = 1.03e+06, range: [1, 275162149725], Skewness = 20.50, Kurtosis = 528.93, 71.35% missing
    #>   - gross_production_value_constant_2014_2016_thousand_us: n = 131219, Mean = 7.90e+05, SD = 4.52e+06, Median = , MAD = 59395.18, range: [1, 155583048], Skewness = 18.88, Kurtosis = 489.78, 72.28% missing
    #>   - gross_production_value_current_thousand_slc: n = 131219, Mean = 1.83e+09, SD = 2.74e+11, Median = , MAD = 6.68e+05, range: [1, 52128784998300], Skewness = 189.97, Kurtosis = 36102.16, 72.46% missing
    #>   - gross_production_value_current_thousand_us: n = 131219, Mean = 6.47e+05, SD = 3.94e+06, Median = , MAD = 48196.36, range: [1, 207738084], Skewness = 25.20, Kurtosis = 944.10, 73.44% missing
    #>   - producer_price_index_2014_2016_100: n = 131219, Mean = 90.18, SD = 1322.48, Median = , MAD = 29.65, range: [0, 283661], Skewness = 173.05, Kurtosis = 34830.40, 52.53% missing
    #>   - producer_price_lcu_tonne: n = 131219, Mean = 1.21e+07, SD = 2.18e+08, Median = , MAD = 21601.48, range: [80, 1.125e+10], Skewness = 30.09, Kurtosis = 1098.53, 81.41% missing
    #>   - producer_price_slc_tonne: n = 131219, Mean = 1.05e+06, SD = 8.17e+06, Median = , MAD = 12317.44, range: [0, 404521000], Skewness = 21.69, Kurtosis = 747.23, 81.42% missing
    #>   - producer_price_usd_tonne: n = 131219, Mean = 2205.93, SD = 2066.51, Median = , MAD = 1245.38, range: [33, 33996], Skewness = 3.06, Kurtosis = 18.48, 81.90% missing
    #>   - stock_value_lcu: n = 131219, Mean = 8.78e+11, SD = 8.01e+13, Median = , MAD = 0.00, range: [0, 16321509020323868], Skewness = 151.08, Kurtosis = 25522.56, 23.40% missing
    #>   - stock_value_slc: n = 131219, Mean = 2.00e+11, SD = 9.88e+12, Median = , MAD = 0.00, range: [0, 1612566265665600], Skewness = 95.84, Kurtosis = 11816.71, 23.40% missing
    #>   - stock_value_usd: n = 131219, Mean = 1.93e+08, SD = 3.67e+09, Median = , MAD = 0.00, range: [0, 3.70e+11], Skewness = 55.78, Kurtosis = 4205.12, 23.61% missing
    #>   - mean_slc_price_per_tonne_2014_2016: n = 131219, Mean = 1.74e+06, SD = 1.01e+07, Median = , MAD = 20532.28, range: [160, 113709500], Skewness = 8.37, Kurtosis = 76.76, 80.84% missing
    #>   - mean_usd_conversion_2014_2016: n = 131219, Mean = 872.52, SD = 3536.15, Median = , MAD = 14.58, range: [0.30, 28622.67], Skewness = 6.02, Kurtosis = 38.32, 1.57% missing
    #>   - producer_price_usd_per_tonne_2014_2016: n = 131219, Mean = 2899.56, SD = 3689.42, Median = , MAD = 1477.76, range: [96.49, 68142.33], Skewness = 8.90, Kurtosis = 125.82, 80.84% missing
    #>   - stock_value_constant_2014_2016_usd: n = 131219, Mean = 3.07e+08, SD = 5.66e+09, Median = , MAD = 0.00, range: [0, 4.02e+11], Skewness = 40.31, Kurtosis = 1981.30, 22.95% missing

|     | Variable                                               |  n_Obs | percentage_Missing |         Mean |           SD | Median |          MAD |          Min |          Max |    Skewness |      Kurtosis | n_Entries | n_Missing |
|:----|:-------------------------------------------------------|-------:|-------------------:|-------------:|-------------:|-------:|-------------:|-------------:|-------------:|------------:|--------------:|----------:|----------:|
| 3   | iso3_code                                              | 131219 |          0.0365801 |           NA |           NA |     NA |           NA |           NA |           NA |          NA |            NA |       202 |        48 |
| 2   | faost_code                                             | 131219 |          0.0365801 | 1.266204e+02 | 7.276729e+01 |     NA | 9.488640e+01 |    1.0000000 | 2.990000e+02 |   0.0154792 |    -1.0904881 |        NA |        NA |
| 6   | area                                                   | 131219 |          0.4641096 |           NA |           NA |     NA |           NA |           NA |           NA |          NA |            NA |       201 |       609 |
| 4   | item                                                   | 131219 |          0.0365801 |           NA |           NA |     NA |           NA |           NA |           NA |          NA |            NA |         6 |        48 |
| 1   | animal                                                 | 131219 |          0.0365801 |           NA |           NA |     NA |           NA |           NA |           NA |          NA |            NA |        24 |        48 |
| 5   | year                                                   | 131219 |          0.0365801 | 2.007560e+03 | 6.914304e+00 |     NA | 8.895600e+00 | 1996.0000000 | 2.019000e+03 |  -0.0098648 |    -1.2016301 |        NA |        NA |
| 9   | head                                                   | 131219 |         11.9647307 | 2.740580e+08 | 6.748602e+09 |     NA | 4.775677e+05 |    0.0000000 | 5.690774e+11 |  59.6733184 |  4007.6501982 |        NA |        NA |
| 8   | tonnes                                                 | 131219 |          9.1899801 | 3.655330e+05 | 2.988353e+06 |     NA | 7.497992e+03 |    0.0000000 | 1.379568e+08 |  20.5010035 |   549.0367369 |        NA |        NA |
| 20  | yield_kg                                               | 131219 |         76.4485326 | 6.178687e+01 | 8.476246e+01 |     NA | 2.045988e+01 |    0.0000000 | 4.578000e+02 |   1.5698676 |     1.7962393 |        NA |        NA |
| 21  | carcass_pct                                            | 131219 |         78.0405277 | 6.089239e-01 | 1.333268e-01 |     NA | 1.482600e-01 |    0.3100000 | 9.700000e-01 |   0.2267946 |    -1.4517749 |        NA |        NA |
| 16  | lbw_kg                                                 | 131219 |         71.6938858 | 1.461899e+02 | 1.709247e+02 |     NA | 5.643764e+01 |    0.0000000 | 9.000000e+02 |   0.8465214 |    -0.5791894 |        NA |        NA |
| 27  | gross_production_value_constant_2014_2016_thousand_i   | 131219 |         85.9029561 | 5.187439e+05 | 2.539509e+06 |     NA | 3.435184e+04 |    3.0000000 | 4.919640e+07 |  10.2663353 |   128.6932661 |        NA |        NA |
| 15  | gross_production_value_constant_2014_2016_thousand_slc | 131219 |         71.3456131 | 6.498522e+08 | 7.532200e+09 |     NA | 1.032282e+06 |    1.0000000 | 2.751621e+11 |  20.5040812 |   528.9322395 |        NA |        NA |
| 17  | gross_production_value_constant_2014_2016_thousand_us  | 131219 |         72.2784048 | 7.903696e+05 | 4.520192e+06 |     NA | 5.939518e+04 |    1.0000000 | 1.555830e+08 |  18.8810931 |   489.7769699 |        NA |        NA |
| 18  | gross_production_value_current_thousand_slc            | 131219 |         72.4643535 | 1.826532e+09 | 2.742951e+11 |     NA | 6.683309e+05 |    1.0000000 | 5.212878e+13 | 189.9667128 | 36102.1641410 |        NA |        NA |
| 19  | gross_production_value_current_thousand_us             | 131219 |         73.4405841 | 6.472795e+05 | 3.941642e+06 |     NA | 4.819636e+04 |    1.0000000 | 2.077381e+08 |  25.2037660 |   944.1037590 |        NA |        NA |
| 14  | producer_price_index_2014_2016_100                     | 131219 |         52.5305024 | 9.017501e+01 | 1.322481e+03 |     NA | 2.965200e+01 |    0.0000000 | 2.836610e+05 | 173.0458614 | 34830.3973209 |        NA |        NA |
| 24  | producer_price_lcu_tonne                               | 131219 |         81.4104665 | 1.205346e+07 | 2.177791e+08 |     NA | 2.160148e+04 |   80.0000000 | 1.125000e+10 |  30.0854882 |  1098.5309228 |        NA |        NA |
| 25  | producer_price_slc_tonne                               | 131219 |         81.4165632 | 1.052035e+06 | 8.173627e+06 |     NA | 1.231744e+04 |    0.0000000 | 4.045210e+08 |  21.6939585 |   747.2279480 |        NA |        NA |
| 26  | producer_price_usd_tonne                               | 131219 |         81.8997249 | 2.205934e+03 | 2.066514e+03 |     NA | 1.245384e+03 |   33.0000000 | 3.399600e+04 |   3.0603352 |    18.4826685 |        NA |        NA |
| 11  | stock_value_lcu                                        | 131219 |         23.3975263 | 8.779119e+11 | 8.006253e+13 |     NA | 0.000000e+00 |    0.0000000 | 1.632151e+16 | 151.0758342 | 25522.5614141 |        NA |        NA |
| 12  | stock_value_slc                                        | 131219 |         23.4005746 | 2.001742e+11 | 9.875646e+12 |     NA | 0.000000e+00 |    0.0000000 | 1.612566e+15 |  95.8377091 | 11816.7107066 |        NA |        NA |
| 13  | stock_value_usd                                        | 131219 |         23.6086238 | 1.928891e+08 | 3.666185e+09 |     NA | 0.000000e+00 |    0.0000000 | 3.696460e+11 |  55.7820156 |  4205.1214003 |        NA |        NA |
| 22  | mean_slc_price_per_tonne_2014_2016                     | 131219 |         80.8404271 | 1.741903e+06 | 1.005043e+07 |     NA | 2.053228e+04 |  160.0000000 | 1.137095e+08 |   8.3680247 |    76.7628108 |        NA |        NA |
| 7   | mean_usd_conversion_2014_2016                          | 131219 |          1.5683704 | 8.725217e+02 | 3.536149e+03 |     NA | 1.458246e+01 |    0.2958489 | 2.862267e+04 |   6.0150984 |    38.3172324 |        NA |        NA |
| 23  | producer_price_usd_per_tonne_2014_2016                 | 131219 |         80.8404271 | 2.899562e+03 | 3.689425e+03 |     NA | 1.477756e+03 |   96.4874233 | 6.814233e+04 |   8.8960687 |   125.8224660 |        NA |        NA |
| 10  | stock_value_constant_2014_2016_usd                     | 131219 |         22.9456100 | 3.074802e+08 | 5.655661e+09 |     NA | 0.000000e+00 |    0.0000000 | 4.020543e+11 |  40.3063136 |  1981.2951440 |        NA |        NA |

# Methods

<!--- Add diagrams of the workflow --->

## Aquaculture

## Crops

## Livestock

# Results

<!--- Add automated results to this section --->

## Tables

![](C:/Users/DEN173/Projects/GBADS/PPSTheme/output/tables/tab_aquaculture_value_2006-2018.png)
![](C:/Users/DEN173/Projects/GBADS/PPSTheme/output/tables/tab_bra_chn_ind_usa_values_2006-2018.png)
![](C:/Users/DEN173/Projects/GBADS/PPSTheme/output/tables/tab_livestock_value_2006-2018.png)

## Figures

# R Package References

-   Alex Couture-Beil (2022). rjson: JSON for R. R package version
    0.2.21. <https://CRAN.R-project.org/package=rjson>
-   Arel-Bundock et al., (2018). countrycode: An R package to convert
    country names and country codes. Journal of Open Source Software,
    3(28), 848, <https://doi.org/10.21105/joss.00848>
-   Garrett Grolemund, Hadley Wickham (2011). Dates and Times Made Easy
    with lubridate. Journal of Statistical Software, 40(3), 1-25. URL
    <https://www.jstatsoft.org/v40/i03/>.
-   Guangchuang Yu (2021). badger: Badge for R Package. R package
    version 0.1.0. <https://CRAN.R-project.org/package=badger>
-   H. Wickham. ggplot2: Elegant Graphics for Data Analysis.
    Springer-Verlag New York, 2016.
-   Hadley Wickham (2011). The Split-Apply-Combine Strategy for Data
    Analysis. Journal of Statistical Software, 40(1), 1-29. URL
    <http://www.jstatsoft.org/v40/i01/>.
-   Hadley Wickham (2019). assertthat: Easy Pre and Post Assertions. R
    package version 0.2.1.
    <https://CRAN.R-project.org/package=assertthat>
-   Hadley Wickham (2019). stringr: Simple, Consistent Wrappers for
    Common String Operations. R package version 1.4.0.
    <https://CRAN.R-project.org/package=stringr>
-   Hadley Wickham (2021). forcats: Tools for Working with Categorical
    Variables (Factors). R package version 0.5.1.
    <https://CRAN.R-project.org/package=forcats>
-   Hadley Wickham and Dana Seidel (2020). scales: Scale Functions for
    Visualization. R package version 1.1.1.
    <https://CRAN.R-project.org/package=scales>
-   Hadley Wickham and Maximilian Girlich (2022). tidyr: Tidy Messy
    Data. R package version 1.2.0.
    <https://CRAN.R-project.org/package=tidyr>
-   Hadley Wickham, Jim Hester and Jennifer Bryan (2022). readr: Read
    Rectangular Text Data. R package version 2.1.2.
    <https://CRAN.R-project.org/package=readr>
-   Hadley Wickham, Romain François, Lionel Henry and Kirill Müller
    (2021). dplyr: A Grammar of Data Manipulation. R package version
    1.0.7. <https://CRAN.R-project.org/package=dplyr>
-   Hadley Wickham. testthat: Get Started with Testing. The R Journal,
    vol. 3, no. 1, pp. 5–10, 2011
-   Jesse Piburn (2020). wbstats: Programmatic Access to the World Bank
    API. Oak Ridge National Laboratory. Oak Ridge, Tennessee. URL
    <https://doi.org/10.11578/dc.20171025.1827>
-   Jim Hester and Jennifer Bryan (2022). glue: Interpreted String
    Literals. R package version 1.6.1.
    <https://CRAN.R-project.org/package=glue>
-   JJ Allaire and Yihui Xie and Jonathan McPherson and Javier Luraschi
    and Kevin Ushey and Aron Atkins and Hadley Wickham and Joe Cheng and
    Winston Chang and Richard Iannone (2021). rmarkdown: Dynamic
    Documents for R. R package version 2.11. URL
    <https://rmarkdown.rstudio.com>.
-   Kevin Ushey (2022). renv: Project Environments. R package version
    0.15.2. <https://CRAN.R-project.org/package=renv>
-   Kirill Müller (2020). here: A Simpler Way to Find Your Files. R
    package version 1.0.1. <https://CRAN.R-project.org/package=here>
-   Kirill Müller and Hadley Wickham (2021). tibble: Simple Data Frames.
    R package version 3.1.6. <https://CRAN.R-project.org/package=tibble>
-   Lionel Henry and Hadley Wickham (2020). purrr: Functional
    Programming Tools. R package version 0.3.4.
    <https://CRAN.R-project.org/package=purrr>
-   Makowski, D., Ben-Shachar, M.S., Patil, I. & Lüdecke, D. (2020).
    Automated Results Reporting as a Practical Tool to Improve
    Reproducibility and Methodological Best Practices Adoption. CRAN.
    Available from <https://github.com/easystats/report>. doi: .
-   Malte Grosser (2019). snakecase: Convert Strings into any Case. R
    package version 0.11.0.
    <https://CRAN.R-project.org/package=snakecase>
-   Mario Frasca (2019). logging: R Logging Package. R package version
    0.10-108. <https://CRAN.R-project.org/package=logging>
-   Matthieu Lesnoff (2021). mmage: A R package for sex-and-age
    population matrix models. R package version 2.4-3.
-   Michael C. J. Kao, Markus Gesmann and Filippo Gheri (2022). FAOSTAT:
    Download Data from the FAOSTAT Database. R package version 2.2.3.
    <https://CRAN.R-project.org/package=FAOSTAT>
-   Neal Richardson, Ian Cook, Nic Crane, Jonathan Keane, Romain
    François, Jeroen Ooms and Apache Arrow (2021). arrow: Integration to
    ‘Apache’ ‘Arrow’. R package version 6.0.1.
    <https://CRAN.R-project.org/package=arrow>
-   R Core Team (2021). R: A language and environment for statistical
    computing. R Foundation for Statistical Computing, Vienna, Austria.
    URL <https://www.R-project.org/>.
-   Richard Iannone and Mauricio Vargas (2022). pointblank: Data
    Validation and Organization of Metadata for Local and Remote Tables.
    R package version 0.10.0.
    <https://CRAN.R-project.org/package=pointblank>
-   Sam Firke (2021). janitor: Simple Tools for Examining and Cleaning
    Dirty Data. R package version 2.1.0.
    <https://CRAN.R-project.org/package=janitor>
-   Stefan Milton Bache and Hadley Wickham (2022). magrittr: A
    Forward-Pipe Operator for R. R package version 2.0.2.
    <https://CRAN.R-project.org/package=magrittr>
-   Tony Fischetti (2021). assertr: Assertive Programming for R Analysis
    Pipelines. R package version 2.8.
    <https://CRAN.R-project.org/package=assertr>
-   Wickham et al., (2019). Welcome to the tidyverse. Journal of Open
    Source Software, 4(43), 1686, <https://doi.org/10.21105/joss.01686>
-   Yihui Xie (2021). knitr: A General-Purpose Package for Dynamic
    Report Generation in R. R package version 1.37.

# References

<div id="refs">

</div>

[1] [“<span class="nocase">Global aquaculture production 1950-2019
(FishstatJ)</span>” (Rome: FAO; FAO Fisheries Division, 2021),
[www.fao.org/fishery/statistics/software/fishstatj/en](https://www.fao.org/fishery/statistics/software/fishstatj/en)](#ref-FAO2021e).

[2] [“<span class="nocase">Crops and livestock products</span>”
(FAOSTAT, 2021),
<https://fenixservices.fao.org/faostat/static/bulkdownloads/Production_Crops_Livestock_E_All_Data_(Normalized).zip>](#ref-FAO2021d).

[3] 
