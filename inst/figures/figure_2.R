#!/usr/bin/Rscript --vanilla

# ------------------------------------------------------------------------------
#
# Name: inst/figures/generate-figures.R
# Project: GBADS
# Author: Gabriel Dennis <gabriel.dennis@csiro.au>
#
# Generates  Figure 2 for the livestock value manuscript
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
    library(LivestockValueGBADS)
})
# -------------------------------------------------------------------------



# Import output files -----------------------------------------------------
config <- config::get()


# Have to remove this
theme_set(
    panel_plot_theme()
)


# Preparation functions ---------------------------------------------------
config <- config::get()

# Function to prepare data for initial plots
prep_data <- function() {
    df_list <- purrr::keep(config$data$output, ~ grepl("values", .x, ignore.case = TRUE))
    data <- list()
    livestock_value <- df_list$livestock_values |>
        arrow::read_parquet() |>
        dplyr::mutate(
            gross_production_value_constant_2014_2016_usd = gross_production_value_constant_2014_2016_thousand_us * 1e3
        )

    livestock_value <- df_list$livestock_values |>
        arrow::read_parquet() |>
        dplyr::mutate(
            gross_production_value_constant_2014_2016_usd = gross_production_value_constant_2014_2016_thousand_us * 1e3
        )

    data$livestock_asset <- get_livestock_asset_output_value(livestock_value)

    data$livestock_output <- get_livestock_asset_output_value(
        livestock_value,
        gross_production_value_constant_2014_2016_usd
    )

    data$aquaculture_value <- df_list$aquaculture_values |>
        arrow::read_parquet() |>
        get_aquaculture_value()


    data$crop_value <- df_list$crop_values |>
        arrow::read_parquet() |>
        dplyr::mutate(
            gross_production_value_constant_2014_2016_usd = gross_production_value_constant_2014_2016_thousand_us * 1e3
        ) |>
        get_crop_value()


    data$population <- LivestockValueGBADS::world_bank_population |>
        dplyr::filter(
            year %in% seq(1998, 2018, by = 5),
            country_code %in%
                toupper(unique(livestock_value$iso3_code))
        ) |>
        dplyr::group_by(year) |>
        dplyr::summarise(
            population = sum(population, na.rm = TRUE)
        )
    data
}

# -------------------------------------------------------------------------

# Get data for initial plots
data <- prep_data()

# Figure 2 ----------------------------------------------------------------
#
# Figure 2 is a 3 x 2 plot showing
# a comparison of the following

# Function to get the total value
get_total_df <- function(df, value_col, scale_fun) {
    df |>
        dplyr::group_by(year) |>
        dplyr::summarise(
            total = sum({{ value_col }}, na.rm = TRUE),
            total_label = scale_fun(total),
            .groups = "drop"
        )
}

# Function to get the positions of the values in the
# stacked bar chart
get_position_df <- function(df, value_col) {
    df |>
        dplyr::group_by(year) |>
        dplyr::arrange(year, desc(category)) |>
        dplyr::mutate(
            pos = cumsum({{ value_col }}) - 0.5 * {{ value_col }}
        ) |>
        dplyr::ungroup()
}


# -------------------------------------------------------------------------

# Years to be plotted
years <- seq(1998, 2018, by = 5)

# Create a list of data frames of the totals for all plots shown in column 1
total_value_dfs <- list(
    asset = get_total_df(data$livestock_asset, value, \(x) scale_trill(x, .01)),
    output = get_total_df(data$livestock_output, value, \(x) scale_trill(x, .01)),
    crop = get_total_df(data$crop_value, value, \(x) scale_trill(x, .01))
)

# Create a list of data frames of the totals for all plots shown in column 2
# Scaling function
weight_scale <- scales::comma_format(scale = 1e-6, suffix = " M", accuracy = 1)

# Dataframes
total_weight_dfs <- list(
    asset = get_total_df(data$livestock_asset, tonnes, weight_scale),
    output = get_total_df(data$livestock_output, tonnes, weight_scale),
    crops = get_total_df(data$crop_value, tonnes, weight_scale)
)

# Get the positions of each % text location
position_dfs <- list(
    asset = with(data, get_position_df(livestock_asset, value)),
    asset_weight = with(data, get_position_df(livestock_asset, tonnes)),
    output = with(data, get_position_df(livestock_output, value)),
    output_weight = with(data, get_position_df(livestock_output, tonnes)),
    crops = with(data, get_position_df(crop_value, value)),
    crop_weight = with(data, get_position_df(crop_value, tonnes))
)

# Function to format percentages
pct_format <- function(x, accuracy = 1) {
    scales::percent(
        x,
        accuracy = accuracy
    )
}

# Function to get the manuals scale fill values
get_fill_values <- function(fct) {
    if (!is.factor(fct)) {
        fct <- as.factor(fct)
    }
    rev(nature_color_scheme()[levels(fct)])
}

# Plotting function

# Left Column
plot_panel_col_1 <- function(df,
                             value_col,
                             fill_values,
                             total_df,
                             position_df = NULL,
                             total_offset = 0.05,
                             pct_text_size = 2,
                             total_text_size = 2.5,
                             scale_fun = scale_trill,
                             y_axis_title = NULL) {
    years <- sort(unique(df$year))

    p <- df |>
        ggplot(aes(x = year, y = {{ value_col }}, fill = category, group = category)) +
        geom_bar(
            position = "stack", stat = "identity", color = "white",
            width = 1.5
        ) +
        scale_x_continuous(breaks = years) +
        scale_y_continuous(labels = scale_fun) +
        scale_fill_manual(
            values = fill_values
        ) +
        geom_text(
            data = total_df,
            aes(
                x = year,
                y = total * (1 + total_offset),
                label = total_label
            ),
            inherit.aes = F,
            fontface = "italic",
            size = total_text_size
        )

    if (!is.null(position_df)) {
        p <- p +
            geom_text(
                data = position_df,
                aes(
                    x = year,
                    y = pos,
                    label = pct_format(percentage)
                ), inherit.aes = F,
                size = pct_text_size,
                fontface = "italic"
            )
    }

    p +
        labs(
            x = NULL,
            y = y_axis_title
        ) +
        panel_plot_theme() +
        theme(
            legend.title = element_blank()
        )
}

# Right Column
plot_panel_col_2 <- function(df,
                             value_col,
                             fill_values,
                             total_df,
                             position_df = NULL,
                             population_df = data$population,
                             y1_axis_title = NULL,
                             y2_axis_title = "Population",
                             coef = 1,
                             total_offset = 0.05,
                             total_text_size = 2.5,
                             pct_text_size = 2,
                             scale_fun = scale_trill) {
    years <- sort(unique(df$year))
    p <- df |>
        ggplot(aes(x = year, y = {{ value_col }}, fill = category, group = category)) +
        geom_bar(
            position = "stack", stat = "identity", color = "white",
            width = 1.5
        ) +
        scale_x_continuous(breaks = years) +
        scale_y_continuous(
            labels = scale_fun,
            name = y1_axis_title,
            sec.axis = sec_axis(~ . * coef,
                                name = y2_axis_title,
                                labels = scales::label_comma(scale = 1e-9, suffix = "B", accuracy = 1)
            )
        ) +
        geom_point(
            data = population_df,
            aes(x = year, y = population / coef),
            size = 1,
            shape = 4,
            show.legend = F,
            color = "black",
            inherit.aes = F
        ) +
        geom_label(
            data = population_df, aes(
                x = year, y = (population / coef) * (1 + 2 * total_offset),
                label =
                    scales::comma(population,
                                  suffix = " B",
                                  accuracy = .1,
                                  scale = 1e-9
                    )
            ),
            fill = "black",
            color = "white",
            size = 3, inherit.aes = F
        ) +
        scale_fill_manual(
            values = fill_values
        ) +
        geom_text(
            data = total_df,
            aes(
                x = year,
                y = total * (1 + total_offset),
                label = total_label
            ),
            inherit.aes = F,
            size = total_text_size,
            fontface = "italic"
        )

    if (!is.null(position_df)) {
        p <- p +
            geom_text(
                data = position_df,
                aes(
                    x = year,
                    y = pos,
                    label = pct_format(percentage)
                ),
                inherit.aes = F,
                size = pct_text_size
            )
    }

    p +
        labs(
            x = NULL
        ) +
        panel_plot_theme() +
        theme(
            legend.title = element_blank()
        )
}

# Value
p11 <- plot_panel_col_1(
    df = data$livestock_asset,
    value_col = value,
    fill_values = get_fill_values(data$livestock_asset$category),
    total_df = total_value_dfs$asset,
    position_df = position_dfs$asset,
    y_axis_title = "Market value in constant USD (Trillion)"
)

p21 <- plot_panel_col_1(
    df = data$livestock_output,
    value_col = value,
    fill_values = get_fill_values(data$livestock_output$category),
    total_df = total_value_dfs$output,
    position_df = position_dfs$output,
    y_axis_title = "Direct value in constant USD (Trillion)"
)

p31 <- plot_panel_col_1(
    df = data$crop_value,
    value_col = value,
    fill_values = get_fill_values(data$crop_value$category),
    total_df = total_value_dfs$crop,
    position_df = position_dfs$crop,
    y_axis_title = "Direct Value in constant USD (Trillion)"
)

# Weight
p12 <- plot_panel_col_2(
    df = data$livestock_asset,
    value_col = tonnes,
    fill_values = get_fill_values(data$livestock_asset$category),
    total_df = total_weight_dfs$asset,
    position_df = position_dfs$asset_weight,
    coef = 10,
    scale_fun = scales::comma_format(scale = 1e-9, accuracy = .1, suffix = " B"),
    y1_axis_title = "Live Animals (Tonnes)"
)

p22 <- plot_panel_col_2(
    df = data$livestock_output,
    value_col = tonnes,
    fill_values = get_fill_values(data$livestock_output$category),
    total_df = total_weight_dfs$output,
    position_df = position_dfs$output_weight |>
        dplyr::filter(
            percentage > 0.05
        ),
    scale_fun = scales::comma_format(scale = 1e-9, accuracy = .1, suffix = " B"),
    coef = 5.9,
    y1_axis_title = "Direct Outputs (Tonnes)"
)

p32 <- plot_panel_col_2(
    df = data$crop_value,
    value_col = tonnes,
    fill_values = get_fill_values(data$crop_value$category),
    total_df = total_weight_dfs$crop,
    position_df = position_dfs$crop,
    coef = .7,
    scale_fun = scales::comma_format(scale = 1e-9, accuracy = .1, suffix = " B"),
    y1_axis_title = "Crops (Tonnes)"
)


# Use GGarange to create the Figure ---------------------------------------

fig2 <- ggpubr::ggarrange(
    p11, p12, p21, p22, p31, p32,
    nrow = 3, ncol = 2,
    legend = "bottom",
    common.legend = TRUE,
    font.label = list(
        size = 14,
        color = "black",
        face = "italic",
        family = "sans"),
    hjust = -2.5,
    vjust = 2,
    labels = c(
        "A - ",
        "B - ",
        "C - ",
        "D - ",
        "E - ",
        "F - "
    )
)

# Save Output -------------------------------------------------------------
ggsave(
    plot = fig2,
    filename = "output/figures/figure_2.png",
    width = 16,
    height = 10,
    dpi = 300,
    device = "png"
)
