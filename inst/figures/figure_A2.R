#!/usr/bin/Rscript --vanilla

# ------------------------------------------------------------------------------
#
# Name: inst/figures/figure_A2.R
# Project: GBADS
# Author: Gabriel Dennis <gabriel.dennis@csiro.au>
#
# Generates  Figure A2 for the livestock value manuscript
#
# For detail on descriptions of each figure
# See:  output/figures/README.md#figure-descriptions
#
# For details on the figure specifications used here
# See: output/figures/README.md#figure-specifications
# -------------------------------------------------------------------------


# Project Library ---------------------------------------------------------
renv::activate(project = ".")

# Libraries ---------------------------------------------------------------
suppressPackageStartupMessages({
  library(dplyr)
  library(magrittr)
  library(ggplot2)
  library(ggthemes)
  library(hrbrthemes)
  library(tidyr)
  library(rnaturalearth)
  library(rnaturalearthdata)
  library(LivestockValueGBADS)
})
# -------------------------------------------------------------------------



# Import output files -----------------------------------------------------
config <- config::get()



# Constants ---------------------------------------------------------------
date <- 2018
animals <- c("Cattle", "Sheep", "Goat", "Chicken", "Pig")




# Prep data ---------------------------------------------------------------


# Load in the data
data <- arrow::read_parquet(
  config$data$output$livestock_values,
  as_data_frame = TRUE
) |>
  dplyr::filter(
    year == date,
    item == "stock",
    stock_value_constant_2014_2016_usd > 0
  ) |>
  dplyr::mutate(iso3_code = toupper(iso3_code)) |>
  dplyr::mutate(
    category = case_when(
      animal %in% tolower(animals) ~ stringr::str_to_title(animal),
      TRUE ~ "Other Livestock"
    )
  ) |>
  dplyr::group_by(iso3_code, category) |>
  dplyr::summarise(
    value = sum(stock_value_constant_2014_2016_usd, na.rm = TRUE),
    .groups = "drop"
  )


# World data:
# Imports simple features for all countries in the world
world <- ne_countries(scale = "medium", returnclass = "sf") %>%
  dplyr::rename(iso3_code = iso_a3)

world_value <- world |>
  dplyr::left_join(data, by = "iso3_code") |>
  tidyr::drop_na(value)



# Bin the data into appropriate bins
cut_labels <- c(
  "NA" = "#808080",
  "&lt;50M" = "#FFFFCC",
  "50M-500M" = "#A1DAB4",
  "500M-10B" = "#41B6C4",
  "&gt;10B" = "#225EA8"
)


world_value <- dplyr::select(world_value, name, iso3_code, category, value, geometry) %>%
  dplyr::mutate(
    value_bins = cut(value,
      breaks = c(0, 50e6, 500e6, 10e9, Inf),
      labels = names(cut_labels)[2:length(cut_labels)],
      ordered_result = TRUE
    ),
    category = forcats::fct_reorder(category, value, sum, .desc = TRUE)
  )


p <- ggplot(data = world) +
  geom_sf(fill = "#808080", color = "#D5E4EB", size = 0.1) +
  geom_sf(data = world_value, aes(fill = value_bins), color = "#D5E4EB", size = 0.1) +
  coord_sf(ylim = c(-55, 78)) +
  scale_fill_manual(
    values = cut_labels
  ) +
  facet_wrap(~category) +
  labs(
    title = paste0("Global Value of Live Animals (", date, ")"),
    fill = "USD ($)",
    subtitle = "",
    caption = "All values in constant 2014-2016 USD ($)"
  ) +
  guides(fill = guide_legend(nrow = 1)) +
  world_map_theme() +
  theme(
    plot.margin = margin(t = 25, r = 25, b = 25, l = 25)
  )


# Save  -------------------------------------------------------------------
ggsave(
  plot = p,
  filename = "output/figures/figure_A2.png",
  width = 20,
  height = 12
)
