GBADS - Livestock Value
================

-   [Description](#description)
-   [Installation](#installation)
-   [Repository Structure](#repository-structure)
    -   [Make](#make)
    -   [Data](#data)
    -   [Figures and Tables](#figures-and-tables)
    -   [Codes](#codes)
    -   [Documentation](#documentation)
-   [Licence](#licence)
-   [R Package References](#r-package-references)
-   [References](#references)

<!-- README.md is generated from README.Rmd. Please edit that file -->

[![License: CC BY-SA
4.0](https://img.shields.io/badge/license-CC%20BY--SA%204.0-blue.svg)](https://cran.r-project.org/web/licenses/CC%20BY-SA%204.0)
[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

# Description

This repository contains all `R` code and output data for the
[*GBADS*](https://animalhealthmetrics.org/) Global Livestock value
estimation manuscript. This manuscript attempts to produce an estimate
of the total economic value of farmed livestock and aquaculture based on
[*FAOSTAT*](https://www.fao.org/faostat/en/) production data.

# Installation

To install this package run the following code

``` r
if (!require(remotes)) {
  install.packages("remotes")
}

remotes::install_github(
  repo = "GBADsInformatics/PPSTheme/",
  ref = "livestock-value"
)
```

***Note:*** In the future the location of where this code is stored will
no doubt change.

# Repository Structure

This repository is structured similar to an R package, however, there
are minimal differences which make this package non-conforming to
certain standards.

## Make

The `R` directory contains any common functions which are used across
the entire project. The `inst` directory contains `R` scripts which are
intended to be run via the GNU `Makefile` which specifies the required
processes to build each target. Targets are run using the syntax

``` bash
make name-of-file-to-make
```

Project locations and directory structure are outlined in the project
configuration file `conf/config.yml`, in accessing these parameters in
code is managed by the `R` package `config`.

Environment and package management is done using `renv`, `renv.lock`
specifies the hashes for each package used. Package imports are also
listed in the package `DESCRIPTION` file.

## Data

Currently the processed and output data is located in `data/processed/`
and `data/output`. Source data is located in `data/source` and is not
included in this repository due to its size. Data was originally tracked
using [***DVC***](https://dvc.org/) but has been removed due to issues
with the cloud storage configuration. Output data is primarily stored in
`parquet` files.

## Figures and Tables

Output figures and tables are located in `output/figures/`,
`output/tables/`.

*(Note: This is specified in the project configuration yaml file)*

## Codes

FAOSTAT item codes and country codes are located in `data/codes`.

*(Note: This is specified in the project configuration yaml file)*

## Documentation

[pkgdown](https://pkgdown.r-lib.org/) Documentation is available in the
in the `docs/` directory and can be accessed locally.

# Licence

This project is under a creative commons licence.

# R Package References

-   Arel-Bundock et al., (2018). countrycode: An R package to convert
    country names and country codes. Journal of Open Source Software,
    3(28), 848, <https://doi.org/10.21105/joss.00848>
-   H. Wickham. ggplot2: Elegant Graphics for Data Analysis.
    Springer-Verlag New York, 2016.
-   Hadley Wickham (2011). The Split-Apply-Combine Strategy for Data
    Analysis. Journal of Statistical Software, 40(1), 1-29. URL
    <https://www.jstatsoft.org/v40/i01/>.
-   Hadley Wickham. testthat: Get Started with Testing. The R Journal,
    vol. 3, no. 1, pp. 5–10, 2011
-   JJ Allaire and Yihui Xie and Jonathan McPherson and Javier Luraschi
    and Kevin Ushey and Aron Atkins and Hadley Wickham and Joe Cheng and
    Winston Chang and Richard Iannone (2022). rmarkdown: Dynamic
    Documents for R. R package version 2.14. URL
    <https://rmarkdown.rstudio.com>.
-   Makowski, D., Ben-Shachar, M.S., Patil, I. & Lüdecke, D. (2020).
    Automated Results Reporting as a Practical Tool to Improve
    Reproducibility and Methodological Best Practices Adoption. CRAN.
    Available from <https://github.com/easystats/report>. doi: .
-   Pebesma, E., 2018. Simple Features for R: Standardized Support for
    Spatial Vector Data. The R Journal 10 (1), 439-446,
    <https://doi.org/10.32614/RJ-2018-009>
-   R Core Team (2022). R: A language and environment for statistical
    computing. R Foundation for Statistical Computing, Vienna, Austria.
    URL <https://www.R-project.org/>.
-   Yihui Xie (2022). knitr: A General-Purpose Package for Dynamic
    Report Generation in R. R package version 1.39.
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA
-   NA

# References

<div id="refs" class="references csl-bib-body">

<div id="ref-FAO2021" class="csl-entry">

<span class="csl-left-margin">1. </span><span
class="csl-right-inline">FAO, Value of Agricultural Production.
(2021).</span>

</div>

<div id="ref-FAO2021a" class="csl-entry">

<span class="csl-left-margin">2. </span><span
class="csl-right-inline">FAO, Producer Prices. (2021).</span>

</div>

<div id="ref-FAO2021b" class="csl-entry">

<span class="csl-left-margin">3. </span><span
class="csl-right-inline">FAO, Fishery and Aquaculture Statistics. Global
aquaculture production 1950-2019. (2021).</span>

</div>

<div id="ref-FAO2021c" class="csl-entry">

<span class="csl-left-margin">4. </span><span
class="csl-right-inline">FAO, Crops and livestock products.
(2021).</span>

</div>

<div id="ref-faoTechnicalConversionFactors2012" class="csl-entry">

<span class="csl-left-margin">5. </span><span
class="csl-right-inline">FAO, Technical Conversion Factors for
Agricultural Commodities. *Statistics Division of FAO*, (2012)
1–782.</span>

</div>

<div id="ref-PPPConversionFactor" class="csl-entry">

<span class="csl-left-margin">6. </span><span
class="csl-right-inline">PPP conversion factor, GDP (LCU per
international $) \| Data. (n.d.).</span>

</div>

</div>
