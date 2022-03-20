#!/usr/bin/Rscript --vanilla

###################################################
# Project: GBADS: Global Burden of Animal Disease
#
# Author: Gabriel Dennis
#
# Position: Research Technician, CSIRO
#
# Email: gabriel.dennis@csiro.au
#
# CSIRO ID: den173
#
# GitHub ID: denn173
#
# Date Created:  20220307
#
# Description:  This script downloads faostat and fao livestock and aquaculture
# datasets as bulk zip files, and extracts them into the data directory  as
# parquet files for easier storage.
#
# This uses the URLs and locations specified for both the input and output
# data are in the project configuration file: config.yml
####################################

if (!require(renv)) {
    install.packages(
        'renv',
        repos='http://cran.us.r-project.org'
    )
}

# Load Libraries ----------------------------------------------------------
renv::activate(project = '.')


# Project Configurations --------------------------------------------------
config <- config::get()
data_urls <- c(config$data$source$urls$faostat,
               config$data$source$urls$fao)


# Parse Command Line Arguments for different data sources -----------------
parser <- argparse::ArgumentParser(
    description = paste('Downloads new versions of the FAOSTAT and FAO datasets',
                        'used in this manuscript.')
)

parser$add_argument('-d', '--data',
                    help = 'Name of which dataset to download.',
                    choices = names(data_urls),
                    required = TRUE)

args <- parser$parse_args()



# Download the data -------------------------------------------------------
data_dir <-  ifelse(args$data != 'global_aquaculture_production',
                    config$data$source$faostat, config$data$source$fao)

destdir <- here::here(data_dir, args$data)

if (!dir.exists(destdir)) {
    dir.create(destdir, recursive = TRUE)
}

destfile <-  here::here(destdir, paste0(config$date,'_',  args$data,'.zip'))

download.file(
    data_urls[[args$data]],
    destfile = destfile
)




# Unzip and save to the data directory ------------------------------------
unzip(destfile, exdir = tools::file_path_sans_ext(destfile))


# If Faostat File - Read in and place in a Parquet File -------------------
if (args$data != 'global_aquaculture_production') {
    # Data file should have normalized in the file path
    csv_file <- grep("Normalized", list.files(
        tools::file_path_sans_ext(destfile),
        full.names = TRUE), value = TRUE)

    data <- readr::read_csv(csv_file) |>
        janitor::clean_names()

    arrow::write_parquet(data, here::here(config$data$processsed$faostat,
                                          pasteO(args$data, ".parquet")) )
}



# Exit --------------------------------------------------------------------
quit(status = 0)
