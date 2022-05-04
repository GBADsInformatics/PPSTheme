GBADS - Livestock Value
================

-   [Description](#description)
-   [Repository Structure](#repository-structure)
    -   [Make](#make)
    -   [Data](#data)
    -   [Figures and Tables](#figures-and-tables)
    -   [Codes](#codes)
    -   [Methods Documentation](#methods-documentation)
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
estimation manuscript.  
This manuscript attempts to produce an estimate of the total economic
value of farmed livestock and aquaculture based on
[*FAOSTAT*](https://www.fao.org/faostat/en/) production data.

# Repository Structure

This repository is structured similar to an R package, however, there
are minimal differences which make this package non-conforming to
certain standards.

## Make

The `R` directory contains any common functions which are used across
the entire project. The `inst` directory contains `R` scripts which are
intended to be run via the GNU `Makefile` which specifies the required
processes to build each target. Targets are run using the syntax

    $ make name-of-file-to-make

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

## Methods Documentation

Draft supplementary methods documentation is located in the package
`vignettes` directory. It can be viewed once the package has been
installed.

# Licence

This project is under a creative commons licence.

# R Package References

-   Alboukadel Kassambara (2020). ggpubr: ‘ggplot2’ Based Publication
    Ready Plots. R package version 0.4.0.
    <https://CRAN.R-project.org/package=ggpubr>
-   Alex Couture-Beil (2022). rjson: JSON for R. R package version
    0.2.21. <https://CRAN.R-project.org/package=rjson>
-   Andy South (2017). rnaturalearth: World Map Data from Natural Earth.
    R package version 0.1.0.
    <https://CRAN.R-project.org/package=rnaturalearth>
-   Arel-Bundock et al., (2018). countrycode: An R package to convert
    country names and country codes. Journal of Open Source Software,
    3(28), 848, <https://doi.org/10.21105/joss.00848>
-   Bob Rudis (2020). hrbrthemes: Additional Themes, Theme Components
    and Utilities for ‘ggplot2’. R package version 0.8.0.
    <https://CRAN.R-project.org/package=hrbrthemes>
-   Claus O. Wilke (2020). ggtext: Improved Text Rendering Support for
    ‘ggplot2’. R package version 0.1.1.
    <https://CRAN.R-project.org/package=ggtext>
-   David W. Gerbing. Enhancement of the Command-Line Environment for
    use in the Introductory Statistics Course and Beyond. Journal of
    Statistics and Data Science Education, 2021, 29(3), 251-266,
    <https://www.tandfonline.com/doi/abs/10.1080/26939169.2021.1999871>.
-   Erich Neuwirth (2014). RColorBrewer: ColorBrewer Palettes. R package
    version 1.1-2. <https://CRAN.R-project.org/package=RColorBrewer>
-   First Last (NA). LivestockValueGBADS: Calculating the Total Economic
    Value of Livestock. R package version 0.0.0.9000.
-   Guangchuang Yu (2022). badger: Badge for R Package. R package
    version 0.2.0. <https://CRAN.R-project.org/package=badger>
-   H. Wickham. ggplot2: Elegant Graphics for Data Analysis.
    Springer-Verlag New York, 2016.
-   Hadley Wickham (2011). The Split-Apply-Combine Strategy for Data
    Analysis. Journal of Statistical Software, 40(1), 1-29. URL
    <http://www.jstatsoft.org/v40/i01/>.
-   Hadley Wickham (2019). stringr: Simple, Consistent Wrappers for
    Common String Operations. R package version 1.4.0.
    <https://CRAN.R-project.org/package=stringr>
-   Hadley Wickham (2021). forcats: Tools for Working with Categorical
    Variables (Factors). R package version 0.5.1.
    <https://CRAN.R-project.org/package=forcats>
-   Hadley Wickham and Dana Seidel (2020). scales: Scale Functions for
    Visualization. R package version 1.1.1.
    <https://CRAN.R-project.org/package=scales>
-   Hadley Wickham and Jennifer Bryan (2019). readxl: Read Excel Files.
    R package version 1.3.1. <https://CRAN.R-project.org/package=readxl>
-   Hadley Wickham and Maximilian Girlich (2022). tidyr: Tidy Messy
    Data. R package version 1.2.0.
    <https://CRAN.R-project.org/package=tidyr>
-   Hadley Wickham, Jim Hester and Jennifer Bryan (2022). readr: Read
    Rectangular Text Data. R package version 2.1.2.
    <https://CRAN.R-project.org/package=readr>
-   Hadley Wickham, Romain François, Lionel Henry and Kirill Müller
    (2022). dplyr: A Grammar of Data Manipulation. R package version
    1.0.8. <https://CRAN.R-project.org/package=dplyr>
-   Hadley Wickham. testthat: Get Started with Testing. The R Journal,
    vol. 3, no. 1, pp. 5–10, 2011
-   Hao Zhu (2021). kableExtra: Construct Complex Table with ‘kable’ and
    Pipe Syntax. R package version 1.3.4.
    <https://CRAN.R-project.org/package=kableExtra>
-   Jeffrey B. Arnold (2021). ggthemes: Extra Themes, Scales and Geoms
    for ‘ggplot2’. R package version 4.2.4.
    <https://CRAN.R-project.org/package=ggthemes>
-   Jeroen Ooms and Jim Hester (2020). spelling: Tools for Spell
    Checking in R. R package version 2.2.
    <https://CRAN.R-project.org/package=spelling>
-   Jim Hester and Jennifer Bryan (2022). glue: Interpreted String
    Literals. R package version 1.6.2.
    <https://CRAN.R-project.org/package=glue>
-   JJ Allaire (2020). config: Manage Environment Specific Configuration
    Values. R package version 0.3.1.
    <https://CRAN.R-project.org/package=config>
-   JJ Allaire and Yihui Xie and Jonathan McPherson and Javier Luraschi
    and Kevin Ushey and Aron Atkins and Hadley Wickham and Joe Cheng and
    Winston Chang and Richard Iannone (2022). rmarkdown: Dynamic
    Documents for R. R package version 2.13. URL
    <https://rmarkdown.rstudio.com>.
-   Kamil Slowikowski (2021). ggrepel: Automatically Position
    Non-Overlapping Text Labels with ‘ggplot2’. R package version 0.9.1.
    <https://CRAN.R-project.org/package=ggrepel>
-   Kevin Ushey (2022). renv: Project Environments. R package version
    0.15.4. <https://CRAN.R-project.org/package=renv>
-   Kirill Müller (2020). here: A Simpler Way to Find Your Files. R
    package version 1.0.1. <https://CRAN.R-project.org/package=here>
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
-   Michael C. J. Kao, Markus Gesmann and Filippo Gheri (2022). FAOSTAT:
    Download Data from the FAOSTAT Database. R package version 2.2.3.
    <https://CRAN.R-project.org/package=FAOSTAT>
-   Nan Xiao (2018). ggsci: Scientific Journal and Sci-Fi Themed Color
    Palettes for ‘ggplot2’. R package version 2.9.
    <https://CRAN.R-project.org/package=ggsci>
-   Neal Richardson, Ian Cook, Nic Crane, Jonathan Keane, Romain
    François, Jeroen Ooms and Apache Arrow (2022). arrow: Integration to
    ‘Apache’ ‘Arrow’. R package version 7.0.0.
    <https://CRAN.R-project.org/package=arrow>
-   Pebesma, E., 2018. Simple Features for R: Standardized Support for
    Spatial Vector Data. The R Journal 10 (1), 439-446,
    <https://doi.org/10.32614/RJ-2018-009>
-   Philipp Schauberger and Alexander Walker (2021). openxlsx: Read,
    Write and Edit xlsx Files. R package version 4.2.5.
    <https://CRAN.R-project.org/package=openxlsx>
-   R Core Team (2022). R: A language and environment for statistical
    computing. R Foundation for Statistical Computing, Vienna, Austria.
    URL <https://www.R-project.org/>.
-   Richard Iannone (2022). DiagrammeR: Graph/Network Visualization. R
    package version 1.0.9.
    <https://CRAN.R-project.org/package=DiagrammeR>
-   Sam Firke (2021). janitor: Simple Tools for Examining and Cleaning
    Dirty Data. R package version 2.1.0.
    <https://CRAN.R-project.org/package=janitor>
-   Stefan Milton Bache and Hadley Wickham (2022). magrittr: A
    Forward-Pipe Operator for R. R package version 2.0.2.
    <https://CRAN.R-project.org/package=magrittr>
-   Stefano Meschiari (2022). latex2exp: Use LaTeX Expressions in Plots.
    R package version 0.9.4.
    <https://CRAN.R-project.org/package=latex2exp>
-   Tony Fischetti (2021). assertr: Assertive Programming for R Analysis
    Pipelines. R package version 2.8.
    <https://CRAN.R-project.org/package=assertr>
-   Trevor L Davis (2021). argparse: Command Line Optional and
    Positional Argument Parser. R package version 2.1.3.
    <https://CRAN.R-project.org/package=argparse>
-   Yihui Xie (2021). knitr: A General-Purpose Package for Dynamic
    Report Generation in R. R package version 1.37.

# References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-FAO2021c" class="csl-entry">

FAO. “Crops and Livestock Products.” FAOSTAT, 2021.

</div>

<div id="ref-FAO2021b" class="csl-entry">

———. “Fishery and Aquaculture Statistics. Global Aquaculture Production
1950-2019.” Rome: FAO Fisheries Division, 2021.

</div>

<div id="ref-FAO2021a" class="csl-entry">

———. “Producer Prices.” Rome: FAOSTAT, 2021.

</div>

<div id="ref-faoTechnicalConversionFactors2012" class="csl-entry">

———. “Technical Conversion Factors for Agricultural Commodities.”
*Statistics Division of FAO*, 2012, 1–782.

</div>

<div id="ref-FAO2021" class="csl-entry">

———. “Value of Agricultural Production.” Rome: FAOSTAT, 2021.

</div>

<div id="ref-PPPConversionFactor" class="csl-entry">

“PPP Conversion Factor, GDP (LCU Per International $) \| Data.”
https://data.worldbank.org/indicator/PA.NUS.PPP, n.d.

</div>

</div>
