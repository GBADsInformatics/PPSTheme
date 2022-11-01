#!/usr/bin/Rscript --vanilla

# ------------------------------------------------------------------------------
#
# Name: inst/figures/figure_7.R
# Project: GBADS
# Author: Gabriel Dennis <gabriel.dennis@csiro.au>
#
# Generates different figures for the livestock value manuscript
#
# For detail on descriptions of each figure
# See:  output/figures/README.md#figure-descriptions
#
# For details on the figure specifications used here
# See: output/figures/README.md#figure-specifications
#
# Figure themes are added based on the figure specifications
#
# -------------------------------------------------------------------------




# Project  ----------------------------------------------------------------
renv::activate(project = ".")

# Libraries ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(ggthemes)
  library(rnaturalearth)
  library(rnaturalearthdata)
  library(sf)
  library(ggtext)
  library(LivestockValueGBADS)
})


# Config ------------------------------------------------------------------

config <- config::get()

# Constants ---------------------------------------------------------------
year_range <- 2005:2018

df_list <- config$data$output[c(
  "crop_values", "aquaculture_values",
  "livestock_values"
)]


# Prep Data ---------------------------------------------------------------

# Load in the data
data <- purrr::map(
  df_list,
  ~ arrow::read_parquet(.x, as_data_frame = TRUE) |>
    dplyr::filter(year %in% year_range) |>
    dplyr::mutate(iso3_code = toupper(iso3_code))
)

# Summarise by Country and produce a total value
data$livestock_outputs <- data$livestock_values |>
  dplyr::filter(
    gross_production_value_constant_2014_2016_thousand_us > 0,
    tonnes > 0
  ) |>
  tidyr::drop_na(gross_production_value_constant_2014_2016_thousand_us) |>
  dplyr::group_by(iso3_code, year) |>
  dplyr::summarise(
    value = sum(gross_production_value_constant_2014_2016_thousand_us,
      na.rm = TRUE
    ) * 1000,
    .groups = "drop"
  )

data$aquaculture_outputs <- data$aquaculture_values |>
  dplyr::filter(
    constant_2014_2016_usd_value > 0,
    tonnes > 0
  ) |>
  dplyr::group_by(iso3_code, year) |>
  dplyr::summarise(
    value = sum(constant_2014_2016_usd_value,
      na.rm = TRUE
    )
  )

# Load the world bank poulation dataset
population <- LivestockValueGBADS::world_bank_population |>
  dplyr::filter(year %in% year_range) |>
  dplyr::rename(iso3_code = country_code)



# Compute Outputs ---------------------------------------------------------
pct_vec <-  c("&lt; -2.5%", "-2.5% - 0%", "0% - 1%", "1% - 2.5%", "2.5% - 5%", "5% - 10%", "10%&lt;")

outputs <- bind_rows(data$livestock_outputs, data$aquaculture_outputs) |>
  dplyr::group_by(iso3_code, year) |>
  dplyr::summarise(
    value = sum(value, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::left_join(population, by = c("iso3_code", "year")) |>
  dplyr::group_by(iso3_code) |>
  dplyr::arrange(year) %>%
  dplyr::mutate(
    value_percap = value / population
  ) |>
  dplyr::mutate(value = 100 * (value - lag(value)) / (lag(value)) / (year - lag(year))) %>%
  dplyr::mutate(value_percap = 100 * (value_percap - lag(value_percap)) / (lag(value_percap)) / (year - lag(year))) %>%
  dplyr::summarise(
    avg_change = mean(value, na.rm = TRUE),
    avg_change_percap = mean(value_percap, na.rm = TRUE), .groups = "drop"
  ) %>%
  dplyr::mutate(
    change_vals = as.factor(
      cut(avg_change,
        breaks = c(-Inf, -2.5, 0, 1, 2.5, 5, 10, Inf),
        labels = pct_vec
      )
    ),
    change_vals_percap = as.factor(
      cut(avg_change_percap,
        breaks = c(-Inf, -2.5, 0, 1, 2.5, 5, 10, Inf),
        labels = pct_vec
      )
    )
  )





# Plots -------------------------------------------------------------------

# World data:
# Imports simple features for all countries in the world
world <- ne_countries(scale = "medium", returnclass = "sf") %>%
  dplyr::rename(iso3_code = iso_a3) |>
  dplyr::left_join(outputs, by = "iso3_code")

# Color map
cmap <- setNames(
    c(
        "#E64B35FF", "#F39B7FFF", "#F7FCF5",
        "#74C476", "#41AB5D", "#238B45", "#005A32", "#808080"
    ),
   c(pct_vec, "NA")
)



p1 <- ggplot(world) +
  geom_sf(fill = "#808080", color = "#D5E4EB") +
  geom_sf(aes(fill = change_vals), color = "#D5E4EB") +
  coord_sf(ylim = c(-55, 78)) +
  scale_fill_manual(
    values = cmap
  ) +
  labs(
    title = "",
    fill = "",
    subtitle = ""
  ) +
  guides(fill = guide_legend(nrow = 1)) +
  world_map_theme()

p2 <- ggplot(world) +
  geom_sf(fill = "#808080", color = "#D5E4EB") +
  geom_sf(aes(fill = change_vals_percap), color = "#D5E4EB") +
  coord_sf(ylim = c(-55, 78)) +
  theme_economist() +
  scale_fill_manual(
    values = cmap
  ) +
  labs(
    title = "",
    fill = "",
    subtitle = ""
  ) +
  guides(fill = guide_legend(nrow = 1)) +
  world_map_theme()



p <- ggpubr::ggarrange(p1,
  p2,
  ncol = 1,
  nrow = 2,
  legend = "bottom",
  labels = c(
    "A - Average Livestock Output Value Change (%) Per Year (2005-2018)",
    "B - Average Livestock Output Value Change per capita (%) Per Year (2005-2018)"
  ),
  hjust = c(-0.8, -0.7),
  font.label = list(
    size = 14,
    color = "black",
    face = "italic",
    family = "sans"
  )
)


# Save  -------------------------------------------------------------------
ggsave(
  plot = p,
  filename = "output/figures/figure_7.png",
  width = 16,
  height = 12,
  dpi = 300
)
