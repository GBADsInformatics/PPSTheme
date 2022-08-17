GBADS - Livestock Value
================

-   [Description](#description)
-   [Installation](#installation)
-   [Repository Structure](#repository-structure)
    -   [Make](#make)
    -   [Data](#data)
        -   [Metadata](#metadata)
    -   [Figures and Tables](#figures-and-tables)
    -   [Codes](#codes)
    -   [Documentation](#documentation)
-   [Licence](#licence)
-   [Package Reference](#package-reference)
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
  repo = "GBADsInformatics/PPSTheme",
  ref = "livestock-value"
)
```

although the base package is currently named `LivestockValueGBADS`.

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

Currently, not all the dependencies for the targets which download data
are specified in subsequent targets, due to some side effects of the
download process, however, all files in the `data/processed` and
`data/output` directories should be targets which can be recreated by
the project `Makefile`.

Project locations and directory structure are outlined in the project
configuration file `conf/config.yml`, in accessing these parameters in
code is managed by the `R` package `config`. The location of the
configuration file can be modified, however, if this is done, then one
must also modify the environment variable `R_CONFIG_FILE` to match this
new location.

Environment and package management is done using `renv`, `renv.lock`
specifies the hashes for each package used. Package imports are also
listed in the package `DESCRIPTION` file.

## Data

Currently the processed and output data is located in `data/processed/`
and `data/output`. Source data is located in `data/source` and is not
included in this repository due to its size. Data was originally tracked
using [***DVC***](https://dvc.org/) but has been removed due to issues
with the cloud storage configuration. The versions of the source data
which was downloaded for this project is backed up on a internal *CSIRO*
cloud storage platform.

Output data is primarily stored in `parquet` files in the `data/output`
directory.

*(Note: These locations are specified in the project configuration yaml
file)*

### Metadata

Metadata for this project in JSON format for the GBADS Knowledge Engine
is stored in the directory `data/metadata` and can be generated using
the Makefile target `make data/metadata`.

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

# Package Reference

-   Makowski, D., Ben-Shachar, M.S., Patil, I. & Lüdecke, D. (2020).
    Automated Results Reporting as a Practical Tool to Improve
    Reproducibility and Methodological Best Practices Adoption. CRAN.
    Available from <https://github.com/easystats/report>. doi: .
-   R Core Team (2022). R: A language and environment for statistical
    computing. R Foundation for Statistical Computing, Vienna, Austria.
    URL <https://www.R-project.org/>.
-   Yihui Xie (2022). knitr: A General-Purpose Package for Dynamic
    Report Generation in R. R package version 1.39.
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
