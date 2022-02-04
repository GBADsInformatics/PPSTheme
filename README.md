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
    #> R/as2-calculation.R
    #> R/o1-calculation.R
    #> R/scripts/20210901_cleanDADISPopulationAndWeightData.R
    #> R/scripts/20211108_convert-constant-usd.R
    #> R/scripts/20220201_getFAOAquacultureValues.R
    #> R/scripts/20220201_getFAOCropValues.R
    #> R/utils/FAOSTAT_helper_functions.R
    #> R/utils/conversion_functions.R
    #> R/utils/data_loading_functions.R
    #> R/utils/functions.R
    #> README.Rmd
    #> README.md
    #> data/.gitignore
    #> data/FAOSTAT.dvc
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
    #> docs/global-value-livestock-aquaculture.Rmd
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

# Methods

## Aquaculture

## Crops

## Livestock

# Results

<!--- Add automated results to this section --->

## Tables

## Figures

``` r
knitr::include_graphics(here::here('output', 'figurescars.png'))
```

<img src="C:/Users/DEN173/Projects/GBADS/PPSTheme/output/figurescars.png" width="100%" />

# R Package References

-   Alex Couture-Beil (2022). rjson: JSON for R. R package version
    0.2.21. <https://CRAN.R-project.org/package=rjson>
-   Andy South (2017). rnaturalearth: World Map Data from Natural Earth.
    R package version 0.1.0.
    <https://CRAN.R-project.org/package=rnaturalearth>
-   Andy South (2017). rnaturalearthdata: World Vector Map Data from
    Natural Earth Used in ‘rnaturalearth’. R package version 0.1.0.
    <https://CRAN.R-project.org/package=rnaturalearthdata>
-   Arel-Bundock et al., (2018). countrycode: An R package to convert
    country names and country codes. Journal of Open Source Software,
    3(28), 848, <https://doi.org/10.21105/joss.00848>
-   Christopher Gandrud (2020). imfr: Download Data from the
    International Monetary Fund’s Data API. R package version 0.1.9.1.
    <https://CRAN.R-project.org/package=imfr>
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
-   Matthieu Lesnoff (2021). mmage: A R package for sex-and-age
    population matrix models. R package version 2.4-3.
-   Michael C. J. Kao, Markus Gesmann and Filippo Gheri (2022). FAOSTAT:
    Download Data from the FAOSTAT Database. R package version 2.2.3.
    <https://CRAN.R-project.org/package=FAOSTAT>
-   Neal Richardson, Ian Cook, Nic Crane, Jonathan Keane, Romain
    François, Jeroen Ooms and Apache Arrow (2021). arrow: Integration to
    ‘Apache’ ‘Arrow’. R package version 6.0.1.
    <https://CRAN.R-project.org/package=arrow>
-   Pebesma, E., 2018. Simple Features for R: Standardized Support for
    Spatial Vector Data. The R Journal 10 (1), 439-446,
    <https://doi.org/10.32614/RJ-2018-009>
-   R Core Team (2021). R: A language and environment for statistical
    computing. R Foundation for Statistical Computing, Vienna, Austria.
    URL <https://www.R-project.org/>.
-   Sam Firke (2021). janitor: Simple Tools for Examining and Cleaning
    Dirty Data. R package version 2.1.0.
    <https://CRAN.R-project.org/package=janitor>
-   Sergei Izrailev (2021). tictoc: Functions for Timing R Scripts, as
    Well as Implementations of Stack and List Structures. R package
    version 1.0.1. <https://CRAN.R-project.org/package=tictoc>
-   Stefan Milton Bache and Hadley Wickham (2022). magrittr: A
    Forward-Pipe Operator for R. R package version 2.0.2.
    <https://CRAN.R-project.org/package=magrittr>
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
