#!/usr/bin/Rscript --vanilla

# ------------------------------------------------------------------------------
#
# Name: inst/figures/generate-figures.R
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


# Project Library ---------------------------------------------------------
renv::activate(project = ".")

# Libraries ---------------------------------------------------------------
suppressPackageStartupMessages({
  library(dplyr)
  library(magrittr)
  library(ggplot2)
  library(ggthemes)
  library(hrbrthemes)
  library(logging)
  library(tidyr)
  library(rnaturalearth)
  library(sf)
  library(ggtext)
})
# -------------------------------------------------------------------------



# Import output files -----------------------------------------------------
config <- config::get()

# Nature Food Figure Specification
figure_spec <- config$figure_specification$nature_food


# Have to remove this
theme_set(
  panel_plot_theme()
)


# Preparation functions ---------------------------------------------------
config <- config::get()



# Figure 2 ----------------------------------------------------------------

## Figure 2 - Stacked Bar Chart
#'
#' Creates a three pane stacked barplot
#'
#' Current decision is to keep this in constant dollars.
#'
#' @note function should be refactored to be shorter.
#'   currently sections are used to aid with folding
#'
#' Note: Include dots for the population file in the legend
#'
#' @param use_pdf whether to output a pdf plot or not
#' @param data
#' @param add_text
#' @param fig_name
#'
figure_2 <- function(livestock_value,
                     use_pdf = TRUE,
                     fig_name = "figure_2") {


  # Set the seed for reproducibility related to any random text arrangement
  set.seed(0)


  # Global Theme ------------------------------------------------------------
  th <- panel_plot_theme_nature_food()

  # Livestock Assets --------------------------------------------------------
  data$livestock_asset <- data$livestock_value |>
    get_livestock_asset_value(
      stock_value_constant_2014_2016_usd
    )

  # Population Data ---------------------------------------------------------
  population <- LivestockValueGBADS::world_bank_population |>
    dplyr::filter(
      year %in% years,
      country_code %in%
        toupper(unique(data$livestock_values$iso3_code))
    ) |>
    dplyr::group_by(year) |>
    summarise(
      population = sum(population, na.rm = TRUE)
    )



  # Livestock Outputs -------------------------------------------------------
  data$livestock_output <- data$livestock_values |>
    mutate(value = gross_production_value_constant_2014_2016_thousand_us * 1000) |>
    get_livestock_output_value(value)

  # Aquaculture Outputs -----------------------------------------------------
  data$aquaculture_outputs <- data$aquaculture_values |>
    get_aquaculture_value()


  # Crop Outputs ------------------------------------------------------------
  data$crop_outputs <- data$crop_values |>
    mutate(
      value = gross_production_value_constant_2014_2016_thousand_us * 1e3
    ) |>
    get_crop_value(value)


  outputs <- bind_rows(
    data$livestock_output,
    data$crop_outputs,
    data$aquaculture_outputs
  ) |>
    group_by(year) |>
    mutate(
      percentage = value / sum(value, na.rm = TRUE)
    ) |>
    ungroup() |>
    mutate(
      category = forcats::fct_reorder(category,
        value, mean,
        .desc = FALSE
      )
    )

  # Plotting ----------------------------------------------------------------


  # Map the Livestock Outputs to categories
  loginfo("Plotting Output Value")

  output <- outputs |>
    ggplot(aes(x = year, y = value, fill = category)) +
    geom_bar(position = "fill", stat = "identity", color = "white") +
    scale_y_continuous(labels = scales::percent_format()) +
    scale_x_continuous(breaks = years)
  if (add_text) {
    output <- output +
      geom_text(
        aes(
          label = scales::percent(percentage, accuracy = 1)
        ),
        position = position_fill(vjust = 0.5),
        size = 1.5,
        check_overlap = TRUE
      )
  }
  output <- output +
    labs(
      x = "Year",
      y = "",
      fill = " "
    ) +
    theme_clean() +
    scale_fill_manual(values = nature_color_scheme) +
    th


  loginfo("Plotting Asset Value")
  asset <- data$livestock_asset |>
    ggplot(aes(x = year, y = value, fill = category)) +
    geom_bar(position = "fill", stat = "identity", color = "white") +
    scale_y_continuous(labels = scales::percent_format()) +
    scale_x_continuous(breaks = years)
  if (add_text) {
    asset <- asset +
      geom_text(
        aes(
          label = scales::percent(percentage, accuracy = 1)
        ),
        position = position_fill(vjust = 0.5),
        check_overlap = TRUE,
        size = 1.5
      )
  }

  asset <- asset +
    labs(
      x = "Year",
      y = "",
      fill = " "
    ) +
    theme(
      legend.position = NULL
    ) +
    theme_clean() +
    scale_fill_manual(values = nature_color_scheme) +
    th

  total_value <- dplyr::bind_rows(outputs, data$livestock_asset) |>
    dplyr::group_by(year, category) |>
    dplyr::summarise(
      value = sum(value, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::group_by(year) |>
    dplyr::mutate(
      percentage = value / sum(value)
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      category = forcats::fct_reorder(category,
        value, mean,
        .desc = FALSE
      )
    )

  loginfo("Plotting total value")
  coef <- 7.5e9 / 6e12
  total_value <- dplyr::left_join(total_value, population, by = "year")

  legd <- grid::legendGrob(c("Population"),
    nrow = 1, ncol = 1,
    pch = 4,
    gp = grid::gpar(
      col = "black",
      fontfamily = figure_spec$typeface,
      fontsize = figure_spec$font_size
    )
  )


  # Total Sum ---------------------------------------------------------------


  total_sum <- ggplot() +
    geom_bar(
      data = total_value, aes(x = year, y = value, fill = category),
      position = "stack", stat = "identity", color = "white"
    )

  total_sum <- total_sum +
    geom_text(
      data = total_value,
      aes(
        x = year, y = value, fill = category,
        label = scales::dollar(value,
          scale = 1e-9,
          accuracy = 1,
          suffix = "B"
        )
      ),
      position = position_stack(vjust = 0.5),
      check_overlap = TRUE,
      size = 1.5
    )
  total_sum <- total_sum +
    geom_point(
      data = total_value, aes(x = year, y = population / coef),
      size = 1.5, shape = 4, show.legend = F, color = "black"
    ) +
    scale_y_continuous(
      labels = scales::label_dollar(suffix = " T", accuracy = 1, scale = 1e-12),
      n.breaks = 4,
      name = "Value",
      sec.axis = sec_axis(~ . * coef,
        name = "Population",
        labels = scales::label_comma(
          scale = 1e-9,
          suffix = "B",
          accuracy = 1
        )
      )
    ) +
    scale_x_continuous(breaks = years) +
    scale_shape_manual("", values = c("Population" = 4)) +
    theme_clean() +
    labs(
      x = "Year",
      y = "",
      fill = ""
    ) +
    guides(fill = guide_legend(nrow = 1)) +
    scale_fill_manual(values = nature_color_scheme) +
    th +
    annotation_custom(
      grob = legd, xmin = -Inf, xmax = years[2],
      ymax = Inf, ymin = 5e12
    )



  # Total -------------------------------------------------------------------



  total <- total_value |>
    ggplot(aes(x = year, y = value, fill = category)) +
    geom_bar(position = "fill", stat = "identity", color = "white") +
    scale_y_continuous(labels = scales::percent_format()) +
    scale_x_continuous(breaks = years)
  total <- total +
    geom_text(
      aes(
        label = scales::percent(percentage, accuracy = 1)
      ),
      position = position_fill(vjust = 0.5),
      family = figure_spec$family,
      check_overlap = TRUE,
      size = 1.5
    )
  total <- total +
    labs(
      x = "Year",
      y = "",
      fill = ""
    ) +
    theme_clean() +
    scale_fill_manual(values = nature_color_scheme) +
    th


  # Arrange Plot ------------------------------------------------------------


  p <- ggpubr::ggarrange(total_sum,
    total,
    asset,
    output,
    ncol = 2,
    nrow = 2,
    common.legend = TRUE,
    legend = "bottom",
    labels = c(
      "A - Total global farmed animal and crop production.",
      "B - Contribution to the total global farmed production.",
      "C - Contribution to the global asset values.",
      "D - Contribution to the global output values."
    ),
    hjust = -0.2,
    widths = rep(1, 4),
    heights = rep(1, 4),
    font.label = list(
      size = figure_spec$font_size,
      family = figure_spec$typeface,
      face = "italic"
    )
  )
  device <- ifelse(use_pdf, "pdf", "png")
  output_file_name <- here::here(
    "output", "figures",
    paste0(fig_name, ".", device)
  )
  ggsave(
    plot = p,
    filename = output_file_name,
    width = figure_spec$two_column_width,
    height = figure_spec$one_column_width * 2,
    units = figure_spec$units,
    dpi = figure_spec$dpi,
    device = device
  )
}




# Figure 2.a ----------------------------------------------------------------------------------

figure_2a <- function(df_list,
                      population_file,
                      years = seq(1998, 2018, by = 5),
                      use_pdf = TRUE) {
  set.seed(0)

  # Global Themes
  th <- panel_plot_theme_nature_food()


  data <- purrr::map(
    df_list,
    ~ arrow::read_parquet(.x, as_data_frame = TRUE) |>
      filter(year %in% years)
  )

  # Livestock Assets
  data$livestock_asset <- data$livestock_value |>
    dplyr::filter(
      (head > 0 | tonnes > 0),
      stock_value_constant_2014_2016_usd > 0
    ) |>
    dplyr::mutate(value = stock_value_constant_2014_2016_usd) |>
    mutate(
      category = case_when(
        !(animal %in% c("cattle", "sheep", "chicken", "pig")) ~ "Other Livestock",
        TRUE ~ tools::toTitleCase(animal)
      )
    ) |>
    group_by(year, category) |>
    summarise(
      value = sum(value, na.rm = TRUE),
      .groups = "drop"
    ) |>
    group_by(year) |>
    mutate(
      percentage = value / sum(value, na.rm = TRUE)
    ) |>
    ungroup() |>
    mutate(
      category = forcats::fct_reorder(category, value, mean, .desc = FALSE)
    )

  population <- LivestockValueGBADS::world_bank_population |>
    dplyr::filter(
      year %in% years,
      country_code %in%
        toupper(unique(data$livestock_values$iso3_code))
    ) |>
    dplyr::group_by(year) |>
    summarise(
      population = sum(population, na.rm = TRUE)
    )


  nature_color_scheme <- c(
    "Cattle" = "#E64B35FF",
    "Chicken" = "#F39B7FFF",
    "Pig" = "#4DBBD5FF",
    # "Aquaculture" = "#3C5488FF",
    "Sheep" = "#00A087FF",
    "Other Livestock" = "#8491B4FF"
  )



  # Livestock Outputs
  data$livestock_output <- data$livestock_values |>
    filter(gross_production_value_constant_2014_2016_thousand_us > 0) |>
    mutate(value = gross_production_value_constant_2014_2016_thousand_us * 1000) |>
    mutate(
      category = case_when(
        !(animal %in% c(
          "cattle", "sheep",
          "chicken", "pig"
        )) ~ "Other Livestock",
        TRUE ~ tools::toTitleCase(animal)
      )
    ) |>
    group_by(year, category) |>
    summarise(
      value = sum(value, na.rm = TRUE),
      .groups = "drop"
    )

  # Aquaculture Outputs
  data$aquaculture_outputs <- data$aquaculture_values |>
    filter(constant_2014_2016_usd_value > 0) |>
    mutate(value = constant_2014_2016_usd_value) |>
    group_by(year) |>
    summarise(
      value = sum(value, na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(
      category = "Aquaculture"
    )


  outputs <- bind_rows(
    data$livestock_output,
    data$aquaculture_outputs
  ) |>
    group_by(year) |>
    mutate(
      percentage = value / sum(value, na.rm = TRUE)
    ) |>
    ungroup() |>
    mutate(
      category = forcats::fct_reorder(category,
        value, mean,
        .desc = FALSE
      )
    )

  # Map the Livestock Outputs to categories
  loginfo("Plotting Output Value")

  # Get the yearly sums
  yearly_output_sums <- outputs |>
    filter(category != "Aquaculture") |>
    group_by(year) |>
    summarise(
      value = sum(value) + 7e10,
      value_label = scales::dollar(sum(value), suffix = "T", scale = 1e-12, accuracy = 0.01)
    )


  coef <- 8e9 / 2e12



  output <- outputs |>
    filter(category != "Aquaculture") |>
    ggplot(aes(x = year, y = value, fill = category)) +
    geom_bar(
      position = "stack",
      stat = "identity",
      color = "white"
    ) +
    geom_point(
      data = population, aes(x = year, y = population / coef),
      size = 1.5, shape = 4, show.legend = F, color = "black",
      inherit.aes = FALSE
    ) +
    scale_y_continuous(
      labels = scales::dollar_format(
        scale = 1e-12,
        suffix = "T",
        accuracy = 0.5,
      ),
      limits = c(0, 2e12),
      sec.axis = sec_axis(~ . * coef,
        name = "Population",
        labels = scales::label_comma(
          scale = 1e-9,
          suffix = "B",
          accuracy = 1
        )
      )
    ) +
    scale_x_continuous(breaks = years) +
    scale_fill_manual(values = nature_color_scheme) +
    labs(
      x = "Year",
      y = "",
      fill = " "
    ) +
    guides(fill = guide_legend(nrow = 1)) +
    theme_clean() +
    th


  loginfo("Plotting Asset Value")

  # Get the yearly sums of asset values
  yearly_asset_sums <- data$livestock_asset |>
    group_by(year) |>
    summarise(
      value = sum(value) + 7e10,
      value_label = scales::dollar(sum(value), suffix = "T", scale = 1e-12, accuracy = 0.01)
    )


  asset <- data$livestock_asset |>
    ggplot(aes(x = year, y = value, fill = category)) +
    geom_bar(position = "stack", stat = "identity", color = "white") +
    geom_point(
      data = population, aes(x = year, y = population / coef),
      size = 1.5, shape = 4, show.legend = F, color = "black",
      inherit.aes = FALSE
    ) +
    scale_y_continuous(
      labels = scales::dollar_format(
        scale = 1e-12,
        suffix = "T",
        accuracy = 0.5,
      ),
      limits = c(0, 2e12),
      sec.axis = sec_axis(~ . * coef,
        name = "Population",
        labels = scales::label_comma(
          scale = 1e-9,
          suffix = "B",
          accuracy = 1
        )
      )
    ) +
    scale_x_continuous(breaks = years) +
    labs(
      x = "Year",
      y = "",
      fill = " "
    ) +
    theme(
      legend.position = NULL
    ) +
    theme_clean() +
    guides(fill = guide_legend(nrow = 1)) +
    scale_fill_manual(values = nature_color_scheme) +
    th


  legd <- grid::legendGrob(c("Population"),
    nrow = 1, ncol = 1,
    pch = 4,
    gp = grid::gpar(
      col = "black",
      fontfamily = figure_spec$typeface,
      fontsize = figure_spec$font_size
    )
  )

  asset <- asset + annotation_custom(
    grob = legd, xmin = years[1], xmax = years[1],
    ymax = Inf, ymin = 1.6e12
  )


  p <- ggpubr::ggarrange(asset,
    output,
    ncol = 2,
    nrow = 1,
    common.legend = TRUE,
    legend = "bottom",
    labels = c(
      "A - Absolute contribution to global asset values.",
      "B - Absolute contribution to global output values."
    ),
    hjust = -0.2,
    widths = rep(1, 2),
    heights = rep(1, 2),
    font.label = list(
      size = figure_spec$font_size,
      family = figure_spec$typeface,
      face = "italic"
    )
  )

  device <- ifelse(use_pdf, "pdf", "png")


  output_file_name <- here::here(
    "output", "figures",
    paste0("figure_2a_no_aquaculture_no_text.", device)
  )

  ggsave(
    plot = p,
    filename = output_file_name,
    width = figure_spec$two_column_width,
    height = figure_spec$one_column_width,
    units = figure_spec$units,
    dpi = figure_spec$dpi,
    device = device
  )
}

df_list <- purrr::keep(
  config$data$output,
  ~ grepl("values", .x, ignore.case = TRUE)
)



# figure_2b ---------------------------------------------------------------

figure_2b <- function(livestock_value,
                      years = seq(1998, 2018, by = 5),
                      use_pdf = TRUE) {

  # For any random text arrangement
  set.seed(0)

  # Global Plotting Themes
  th <- panel_plot_theme_nature_food()

  data <- list()

  # Livestock Assets
  data$livestock_asset <- livestock_value |>
    get_livestock_asset_value() |>
    ungroup()

  # Livestock Outputs
  data$livestock_output <- livestock_value |>
    get_livestock_output_value() |>
    ungroup()

  df_outputs <- data$livestock_output |>
    dplyr::group_by(year) |>
    dplyr::summarise(
      value = sum(value, na.rm = TRUE)
    )

  df_crops <- "data/output/faostat/faostat_crop_values.parquet" |>
    arrow::read_parquet() |>
    dplyr::mutate(
      gross_production_value_constant_2014_2016_usd = gross_production_value_constant_2014_2016_thousand_us * 1e3
    ) |>
    get_crop_value()



  df <- bind_rows(data) |>
    dplyr::group_by(year) |>
    dplyr::summarise(
      value = sum(value, na.rm = TRUE)
    ) |>
    dplyr::mutate(
      type = "direct+market"
    )
  df <- df |>
    dplyr::bind_rows(
      data$livestock_asset |>
        dplyr::group_by(year) |>
        dplyr::summarise(
          value = sum(value, na.rm = TRUE)
        ) |>
        dplyr::mutate(type = "market")
    )

  # Generate the arrow location plot
  arrow_locations <- df |>
    group_by(year) |>
    mutate(
      x = year,
      xend = year,
      y = min(value) + 1.5e11,
      yend = max(value) - 1.5e11
    ) |>
    ungroup() |>
    filter(year != 2008)

  # Text location
  text_locations <- df |>
    mutate(
      x = year,
      y = ifelse(type == "market", value + 1e11, value + 1e11),
      label = scales::dollar(value, accuracy = 0.01, scale = 1e-12, suffix = "T", prefix = "$ ")
    )


  # Colors for both
  nat_pal <- setNames(c("black", "black"), c("direct+market", "market"))
  csiro_blue <- "#0989B2"
  annotate_size <- 3.5

  (p <- df |>
    ggplot(aes(x = year, y = value, color = type)) +
    geom_point(size = 2) +
    geom_line(size = 1.5) +
    scale_color_manual(values = nat_pal) +
    scale_y_continuous(
      labels = scales::dollar_format(
        scale = 1e-12,
        suffix = "T",
        accuracy = 0.1,
      ),
      limits = c(9e11, 3.2e12)
    ) +
    scale_x_continuous(breaks = years) +
    geom_text(
      data = text_locations,
      aes(x = x, y = y, label = label), size = annotate_size, inherit.aes = FALSE
    ) +
    geom_segment(
      data = arrow_locations,
      aes(x = x, y = y, xend = xend, yend = yend), size = 1.2, color = csiro_blue,
      arrow = arrow(
        ends = "both", type = "open",
        length = unit(0.1, "inches")
      )
    ) +
    geom_point(
      data = df_outputs,
      aes(x = year, y = value),
      inherit.aes = FALSE
    ) +
    geom_line(
      data = df_outputs,
      aes(x = year, y = value),
      inherit.aes = FALSE,
      linetype = "dashed"
    ) +
    geom_point(
      data = df_crops,
      aes(x = year, y = value),
      inherit.aes = FALSE
    ) +
    geom_line(
      data = df_crops,
      aes(x = year, y = value),
      inherit.aes = FALSE,
      linetype = "dashed"
    ) +
    annotate("text",
      x = 2008, y = 1.1e12, label = "atop(bold('Value of Live Animals'))",
      parse = TRUE, size = annotate_size
    ) +
    annotate("text",
      x = 2008, y = 2e12,
      label = "atop(bold('True Direct Use/Market Value'))",
      angle = 0, size = annotate_size, color = csiro_blue,
      parse = T
    ) +
    annotate("text",
      x = 2008,
      y = 2.8e12,
      label = "atop(bold('Value of Live Animals +\n Actual Output Value'))",
      size = annotate_size,
      parse = TRUE
    ) +
    labs(
      x = "Year",
      y = "",
      fill = " "
    ) +
    guides(fill = guide_legend(nrow = 1)) +
    th +
    theme(
      legend.position = "none"
    )

  )


  device <- ifelse(use_pdf, "pdf", "png")


  output_file_name <- here::here(
    "output", "figures",
    paste0("figure_2b_no_text.", device)
  )

  # ggsave(
  #   plot = p,
  #   filename = output_file_name,
  #   width = figure_spec$two_column_width,
  #   height = figure_spec$one_column_width,
  #   units = figure_spec$units,
  #   dpi = figure_spec$dpi,
  #   device = device
  # )
  p
}








# Appendix A1 -------------------------------------------------------------


## Figure A.1 Pie Chart of Asset + Output Values (2018)
figure_a1 <- function(df_list, date = 2018, use_pdf = TRUE) {
  library(lessR)

  # Load in the data
  data <- purrr::map(
    df_list,
    ~ arrow::read_parquet(.x, as_data_frame = TRUE) |>
      dplyr::filter(year == date) |>
      dplyr::mutate(iso3_code = toupper(iso3_code))
  )

  # Summarise by Country and produce a total value
  data$livestock_outputs <- data$livestock_values |>
    filter(
      gross_production_value_constant_2014_2016_thousand_us > 0,
      tonnes > 0
    ) |>
    tidyr::drop_na(gross_production_value_constant_2014_2016_thousand_us) |>
    group_by(animal) |>
    summarise(
      value = sum(gross_production_value_constant_2014_2016_thousand_us,
        na.rm = TRUE
      ) * 1000,
      .groups = "drop"
    )


  data$livestock_assets <- data$livestock_values |>
    filter(
      head > 0,
      stock_value_constant_2014_2016_usd > 0,
      item == "stock"
    ) |>
    group_by(animal) |>
    summarise(
      value = sum(stock_value_constant_2014_2016_usd, na.rm = TRUE)
    )

  data$aquaculture_outputs <- data$aquaculture_values |>
    filter(
      constant_2014_2016_usd_value > 0,
      tonnes > 0
    ) |>
    group_by(iso3_code) |>
    summarise(
      value = sum(constant_2014_2016_usd_value,
        na.rm = TRUE
      )
    ) |>
    dplyr::mutate(
      animal = "Aquaculture"
    )

  # Join the data and ensure the iso3_code matches before summarising
  df <- bind_rows(
    data$livestock_outputs,
    data$livestock_assets,
    data$aquaculture_outputs
  ) |>
    dplyr::mutate(
      iso3_code = toupper(iso3_code),
      animal = case_when(
        !(animal %in% c(
          "cattle", "chicken",
          "goat", "sheep", "pig",
          "Aquaculture"
        )) ~ "Other Livestock",
        TRUE ~ animal
      )
    ) |>
    dplyr::group_by(animal) |>
    dplyr::summarise(
      value = sum(value, na.rm = TRUE)
    ) |>
    dplyr::mutate(animal = stringr::str_to_sentence(animal)) |>
    dplyr::mutate(value_label = scales::dollar(value,
      scale = 1e-9, suffix = "B",
      largest_with_cents = 0
    ), value_pct = value / sum(value, na.rm = TRUE)) %>%
    mutate(animal = forcats::fct_reorder(animal, value, sum)) %>%
    arrange(desc(animal))




  nature_color_scheme <- c(
    "Cattle" = "#E64B35FF",
    "Chicken" = "#F39B7FFF",
    "Pig" = "#4DBBD5FF",
    "Aquaculture" = "#3C5488FF",
    "Other Livestock" = "#8491B4FF",
    "Goat" = "#91D1C2FF",
    "Sheep" = "#00A087FF"
  )

  tbl_data <- df |>
    dplyr::select(animal, value) |>
    dplyr::mutate(
      value_str = glue::glue("{animal} ({scales::dollar(value, scale=1e-9, suffix='B', accuracy=1)})")
    )
  names(nature_color_scheme) <- tbl_data$value_str

  total <- scales::dollar(sum(df$value, na.rm = TRUE), scale = 1e-12, suffix = "T")

  if (use_pdf) {
    pdf(here::here("output", "figures", "figure_a1.pdf"),
      width = figure_spec$two_column_width / 25.4, height = (figure_spec$two_column_width / 25.4) * 0.7,
      family = figure_spec$family
    )

    PieChart(
      x = value_str,
      y = value,
      hole = 0,
      data = tbl_data,
      values = "%",
      fill = nature_color_scheme,
      color = nature_color_scheme,
      values_size = 0.4,
      clockwise = FALSE,
      main = "",
      width = figure_spec$two_column_width / 25.4,
      height = figure_spec$two_column_width / 25.4,
      init_angle = 90,
      values_color = "white",
      labels_cex = 0.4,
      quite = TRUE,
      main_cex = 0.1
    )

    title(
      main = glue::glue("Global Value of Livestock - {date} (Total: {total})"),
      sub = "All Values in Constant 2014-2016 USD ($)",
      adj = 0.5, line = 3,
      cex.main = 0.6,
      cex.sub = 0.6
    )

    dev.off()
  } else {
    png(here::here("output", "figures", "figure_a1.png"),
      family = figure_spec$family,
      height = 600, width = 750
    )

    PieChart(
      x = value_str,
      y = value,
      hole = 0,
      data = tbl_data,
      values = "%",
      fill = nature_color_scheme,
      color = nature_color_scheme,
      values_size = 0.8,
      clockwise = FALSE,
      main = "",
      width = figure_spec$two_column_width / 25.4,
      height = figure_spec$two_column_width / 25.4,
      init_angle = 90,
      values_color = "white",
      labels_cex = 0.8,
      quite = TRUE,
      main_cex = 0.1
    )

    title(
      main = glue::glue("Global Value of Livestock - {date} (Total: {total})"),
      sub = "All Values in Constant 2014-2016 USD ($)",
      adj = 0.5, line = 3,
      cex.main = 0.8,
      cex.sub = 0.8
    )

    dev.off()
  }
}





# ISVEE Plots  ------------------------------------------------------------



#' figure_asset_map
#'
#' Generates a map a global map of Asset/Output Values
#'
#' FIXME: this needs to be refactored
#'
#' @param df_file aggregated dataframe with columns "iso3_code", "year", "value
#' @param date integer year to plot (defaults to 2018)
#' @param use_pdf whether to use a pdf or not
#'
figure_year_map <- function(df,
                            .title,
                            .fig_name,
                            date = 2018,
                            use_pdf = TRUE) {



  # Imports simple features for all countries in the world
  world <-
    rnaturalearth::ne_countries(scale = "medium", returnclass = "sf") %>%
    dplyr::rename(iso3_code = iso_a3)


  world_value <- world |>
    dplyr::left_join(df, by = "iso3_code") |>
    tidyr::drop_na(value)



  # Bin the data into appropriate bins
  cut_labels <- c(
    "NA" = "#808080",
    "&lt;500M" = "#FFFFCC",
    "500M-2.5B" = "#A1DAB4",
    "2.5B-10B" = "#41B6C4",
    "10B-40B" = "#225EA8",
    "&gt;40B" = "#00008b"
  )

  world_value <- dplyr::select(world_value, name, iso3_code, value, geometry) %>%
    dplyr::mutate(
      value_bins = cut(value,
        breaks = c(0, 5e8, 2.5e9, 10e9, 40e9, Inf),
        labels = names(cut_labels)[2:length(cut_labels)],
        ordered_result = TRUE
      )
    )

  p <- ggplot(data = world) +
    geom_sf(fill = "#808080", color = "#D5E4EB", size = 0.1) +
    geom_sf(data = world_value, aes(fill = value_bins), color = "#D5E4EB", size = 0.1) +
    coord_sf(ylim = c(-55, 78)) +
    scale_fill_manual(
      values = cut_labels
    ) +
    labs(
      title = .title,
      fill = "USD ($)",
      subtitle = "",
      caption = "All values in constant 2014-2016 USD ($)"
    ) +
    guides(fill = guide_legend(nrow = 1)) +
    world_map_theme()



  device <- ifelse(use_pdf, "pdf", "png")
  output_file_name <- here::here("output", "figures", glue::glue("{.fig_name}.{device}"))

  ggsave(
    plot = p,
    filename = output_file_name,
    width = figure_spec$two_column_width,
    height = figure_spec$two_column_width * (1 / 1.6),
    units = figure_spec$units,
    dpi = figure_spec$dpi,
    device = device
  )
}


config$data$output$livestock_value |>
  arrow::read_parquet() |>
  dplyr::filter(item == "stock", year == 2018) |>
  filter(
    !is.nan(stock_value_constant_2014_2016_usd),
    !is.na(stock_value_constant_2014_2016_usd)
  ) |>
  group_by(iso3_code) |>
  summarise(
    value = sum(stock_value_constant_2014_2016_usd, rm.na = TRUE)
  ) -> asset_df

config$data$output$livestock_value |>
  arrow::read_parquet() |>
  dplyr::filter(item != "stock", year == 2018) |>
  group_by(iso3_code) |>
  summarise(
    value = sum(gross_production_value_constant_2014_2016_thousand_us, na.rm = TRUE) * 1e3
  ) |>
  filter(value > 0) -> output_df


config$data$output$aquaculture_values |>
  arrow::read_parquet() |>
  filter(year == 2018) |>
  group_by(iso3_code) |>
  summarise(value = sum(constant_2014_2016_usd_value, na.rm = TRUE)) -> aqua_df

output_aqua_df <- rbind(output_df, aqua_df) |>
  group_by(iso3_code) |>
  summarise(value = sum(value, na.rm = TRUE))



# Asset parameters
asset_map_params <- list(
  df = asset_df,
  .title = "Global Value of Livestock Assets (2018)",
  .fig_name = "figure_a_asset_map_2018",
  date = 2018,
  use_pdf = FALSE
)

do.call(figure_year_map, asset_map_params)

# Asset parameters
output_map_params <- list(
  df = output_df,
  .title = "Global Value of Livestock Outputs (2018)",
  .fig_name = "figure_a_output_map_no_aquaculture_2018",
  date = 2018,
  use_pdf = FALSE
)

do.call(figure_year_map, output_map_params)

output_aqua_map_params <- list(
  df = output_aqua_df,
  .title = "Global Value of Livestock and Aquaculture Outputs (2018)",
  .fig_name = "figure_a_output_map_2018",
  date = 2018,
  use_pdf = FALSE
)

do.call(figure_year_map, output_aqua_map_params)
