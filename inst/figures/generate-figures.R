#! /usr/bin/Rscript --vanilla


# Description -------------------------------------------------------------
# Generates different figures for the
# livestock value manuscript



# Figure Specifications ---------------------------------------------------

# Currently, the manuscript authors have initially targetted the following
# journals for publication


## Nature Food
#
# Specifications are identified in the fullowing urls:
# https://www.nature.com/natfood/submission-guidelines/aip-and-formatting
# https://www.nature.com/documents/NRJs-guide-to-preparing-final-artwork.pdf
#
# Specifications:
#
#   Images:
# - Image Citations: Fig.1
# - Figures have minumim resolution of 300 dpi and saved at maximum width of 180 mm
# - Use a 5–7 pt san serif font for standard text labelling and Symbol font
#   for Greek characters.
# - Use scale bars, not magnification factors, and include error bars where appropriate.
# - Do not flatten labelling or scale/error bars onto images – uneditable
#   or low-resolution images are two of the most common reasons for delay
#   in manuscript preparation.
#
# Figure legends
# - Include a brief title for each figure with a short description of
#    each panel cited in sequence.
# - Ensure the legend does not exceed the word limit of the article type.
#
# These specifications are found in the configuration file under figures




# Project Library ---------------------------------------------------------
# Activate project library
renv::activate(project = '.')



# Libraries ---------------------------------------------------------------
require(dplyr)
require(magrittr)
require(ggplot2)
require(ggthemes)
require(hrbrthemes)
require(logging)

# Command Line Arguments --------------------------------------------------
parser <-
    argparse::ArgumentParser(
        description = paste0(
            "Parses command line arguments to",
            "generate manuscript figures"
        )
    )

parser$add_argument(
    '-f',
    '--figure',
    help = 'Number of the figure to generate',
    required = TRUE
)
args <- parser$parse_args()


loginfo(args$figure)

# Import output files -----------------------------------------------------
config <- config::get()

# Nature Food Figure Specification
figure_spec <- config$figure_specification$nature_food



# Plotting Helper Functions -----------------------------------------------
scale_trill <- function(x) {
    scales::dollar(x,
                   accuracy = 1,
                   scale = 1e-12,
                   suffix = " T")
}

# Generate Figures --------------------------------------------------------

write_data <- function(df, df_name, data_path) {
    if (!dir.exists(data_path)) {
        dir.create(data_path)
    }
    df |>
        write.csv(
            file = here::here(data_path,
                              paste0(df_name, ".csv")
            ),
            row.names = FALSE

        )
    df |>
        kableExtra::kbl('html') |>
        kableExtra::save_kable(
            file = here::here(data_path,
                              paste0(
                                  df_name, ".html"
                              ))
        )
}

zip_figure_data <- function(data_path) {
    zip(
        here::here(data_path,
                   paste0(format(Sys.time(),
                                 format = "%Y%m%d_%H%M%S"),
                          ".zip")),
        files =  list.files(data_path,
                            full.names = TRUE,
                            pattern = ".csv$|.html$|.rds$"),
        flags = "-j"
    )
}

compute_spearman_rank <- function(data, colx, coly, R=1e3, extra_str="") {
    set.seed(0)
    spearman_boot <- sapply(1:R,
                            function(i) {
                                data <- dplyr::slice_sample(
                                    data,
                                    prop = 1,
                                    replace = TRUE
                                )
                                cor.test(as.numeric(data[[colx]]),
                                         as.numeric(data[[coly]]),
                                         method = 'spearman')$estimate
                                })

    CI <- quantile(spearman_boot, c(0.025, 0.975))

    rho <- cor.test(as.numeric(data[[colx]]),
                    as.numeric(data[[coly]]),
                    method = 'spearman')$estimate


    latex2exp::TeX(
        sprintf(
            r'(%s $\hat{\rho} = %.2f, 95 \%% CI \ \[ %.2f, %.2f\] $)',
            extra_str, rho, CI[1], CI[2]
        )
    )
}



## Figure 2 - Stacked Bar Chart
#'
#' Creates a three pane stacked barplot
#'
#' @param df_list locations of output parquet dataframe
#' @param years years to subset the data
#'
figure_2 <- function(df_list,
                     population_file,
                     years = seq(1996, 2018, by = 5)) {

    set.seed(0)

    # Global Themes
    th <- theme(
        legend.position = "bottom",
        legend.title = element_text(family = figure_spec$typeface,
                                    size = figure_spec$font_size),
        legend.text = element_text(family = figure_spec$typeface,
                                   size = figure_spec$font_size),
        plot.title = element_text(family = figure_spec$typeface,
                                  size = figure_spec$font_size),
        plot.subtitle = element_text(family = figure_spec$typeface,
                                     size = figure_spec$font_size),
        axis.text.y = element_text(family = figure_spec$typeface,
                                   size = figure_spec$font_size),
        axis.title = element_text(family = figure_spec$typeface,
                                  size = figure_spec$font_size),
        axis.text.x = element_text(family = figure_spec$typeface,
                                   size = figure_spec$font_size),
        axis.title.x = element_text(family = figure_spec$typeface,
                                    size = figure_spec$font_size),
        panel.border = element_blank(),
        legend.background = element_blank(),
        plot.background = element_blank(),
        axis.line.y = element_blank(),
        axis.line.x = element_blank(),
        axis.ticks = element_blank(),
        axis.title.x.bottom = element_blank(),
    )

    data <- purrr::map(
        df_list,
        ~arrow::read_parquet(.x, as_data_frame = TRUE) |>
            filter(year %in% years)
    )

    # Livestock Assets
    data$livestock_asset <- data$livestock_value |>
        dplyr::filter((head > 0 || tonnes > 0),
                      stock_value_constant_2014_2016_usd > 0) |>
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
            .groups = 'drop'
        ) |>
        group_by(year) |>
        mutate(
            percentage = value/sum(value, na.rm = TRUE)
        ) |>
        ungroup() |>
        mutate(
            category = forcats::fct_reorder(category, value, mean, .desc = FALSE)
        )

    # Population data
    # TODO: move this into a helper function
    population <- arrow::read_parquet(population_file) |>
        dplyr::select(country_code, contains('x')) |>
        tidyr::gather(key = "year", value = "population", -country_code) |>
        dplyr::mutate(
            year = as.numeric(substr(year, 2, length(year)))
        ) |>
        dplyr::filter(year %in% years,
                      country_code %in%
                          toupper(unique(data$livestock_values$iso3_code))) |>
        dplyr::group_by(year) |>
        summarise(
            population = sum(population, na.rm = TRUE)
        )

    # Global Color Scheme
    # Obtained from ggsci::pal_npg()(7)
    #> [1] "#E64B35FF" "#4DBBD5FF" "#00A087FF" "#3C5488FF"
    #>  "#F39B7FFF" "#8491B4FF" "#91D1C2FF"
    # Visualis through scales::show_col(ggsci::pal_npg()(7))
    # Here npg are nature inspired themes

    nature_color_scheme <- c(
        "Crops" = "#91D1C2FF",
        "Cattle" = "#E64B35FF",
        "Chicken" = "#F39B7FFF",
        "Pig" = "#4DBBD5FF",
        "Aquaculture" = "#3C5488FF",
        "Sheep" =  "#00A087FF",
        "Other Livestock" = "#8491B4FF"
    )



    # Livestock Outputs
    data$livestock_output <- data$livestock_values |>
        filter(gross_production_value_constant_2014_2016_thousand_us > 0) |>
        mutate(value = gross_production_value_constant_2014_2016_thousand_us * 1000) |>
        mutate(
            category = case_when(
                !(animal %in% c("cattle", "sheep",
                                "chicken", "pig")) ~ "Other Livestock",
                TRUE ~ tools::toTitleCase(animal)
            )
        ) |>
        group_by(year, category) |>
        summarise(
            value = sum(value, na.rm = TRUE),
            .groups = 'drop'
        )

    # Aquaculture Outputs
    data$aquaculture_outputs <- data$aquaculture_values |>
        filter(aquaculture_constant_2014_2016_constant_usd_value > 0) |>
        mutate(value = aquaculture_constant_2014_2016_constant_usd_value) |>
        group_by(year) |>
        summarise(
            value = sum(value, na.rm = TRUE),
            .groups = 'drop'
        )  |>
        mutate(
            category = "Aquaculture"
        )

    # Crop Outputs
    data$crop_outputs <- data$crop_values |>
        filter(gross_production_value_constant_2014_2016_thousand_us > 0) |>
        mutate(
            value = gross_production_value_constant_2014_2016_thousand_us * 1e3
        ) |>
        group_by(year) |>
        summarise(
            value = sum(value, na.rm = TRUE),
            .groups = 'drop'
        )  |>
        mutate(
            category = "Crops"
        )

    outputs <- bind_rows(data$livestock_output,
                         data$crop_outputs,
                         data$aquaculture_outputs) |>
        group_by(year) |>
        mutate(
            percentage = value/sum(value, na.rm = TRUE)
        ) |>
        ungroup()  |>
        mutate(
            category = forcats::fct_reorder(category,
                                            value, mean, .desc = FALSE)
        )

    # Map the Livestock Outputs to categories
    loginfo("Plotting Output Value")
    output <- outputs |>
        ggplot(aes(x = year, y = value, fill = category))  +
        geom_bar(position = "fill", stat = "identity", color = "white") +
        scale_y_continuous(labels = scales::percent_format()) +
        scale_x_continuous(breaks = years) +
        geom_text(
            aes(
                label = scales::percent(percentage, accuracy = 1)),
            position = position_fill(vjust = 0.5),
            size = 1.5,
            check_overlap = TRUE) +
        labs(
            x = 'Year',
            y = '',
            fill = " "
        ) +
        theme_clean() +
        scale_fill_manual(values = nature_color_scheme) +
        th
    loginfo("Plotting Asset Value")
    asset <-  data$livestock_asset |>
        ggplot(aes(x = year, y = value, fill = category))  +
        geom_bar(position = "fill", stat = "identity",  color = "white" ) +
        scale_y_continuous(labels = scales::percent_format()) +
        scale_x_continuous(breaks = years) +
        geom_text(
            aes(
                label =   scales::percent(percentage, accuracy = 1)),
            position = position_fill(vjust = 0.5),
            check_overlap = TRUE,
            size = 1.5) +
        labs(
            x = 'Year',
            y = '',
            fill = " "
        ) +
        theme(
            legend.position = NULL
        )  +
        theme_clean() +
        scale_fill_manual(values = nature_color_scheme) +
        th

    total_value <- dplyr::bind_rows(outputs, data$livestock_asset ) |>
        dplyr::group_by(year, category) |>
        dplyr::summarise(
            value = sum(value, na.rm = TRUE),
            .groups = 'drop'
        ) |>
        dplyr::group_by(year) |>
        dplyr::mutate(
            percentage = value/sum(value)
        ) |>
        dplyr::ungroup() |>
        dplyr::mutate(
            category = forcats::fct_reorder(category,
                                            value, mean, .desc = FALSE)
        )

    loginfo("Plotting total value")
    coef <- 8e9/6e12
    total_value <- dplyr::left_join(total_value, population, by = "year")
    total_sum <- total_value |>
        ggplot(aes(x = year, y = value, fill = category)) +
        geom_bar(position = "stack", stat = "identity", color = "white") +
        geom_text(
            aes(
                label = scales::dollar(value, scale = 1e-9,
                                              accuracy = 1,
                                              suffix = " B")),
            position = position_stack(vjust = 0.5),
            check_overlap = TRUE,
            size = 1.5) +
        geom_point(data = total_value, aes(x = year, y = population/coef),
                   color = "black", size =0.5, show.legend = FALSE) +
        scale_y_continuous(labels = scales::label_dollar(suffix = ' T', accuracy = 1, scale = 1e-12),
                           n.breaks = 4,
                           name = "Value",
                           sec.axis = sec_axis(~.*coef, name = "Population",
                         labels = scales::label_comma(scale=1e-9, suffix = ' B')) ) +
        scale_x_continuous(breaks = years) +
        labs(
            x = 'Year',
            y = '',
            fill = ""
        )  +
        theme_clean() +
        scale_fill_manual(values = nature_color_scheme) +
        th


    total <- total_value |>
        ggplot(aes(x = year, y = value, fill = category)) +
        geom_bar(position = "fill", stat = "identity", color = "white") +
        scale_y_continuous(labels = scales::percent_format()) +
        scale_x_continuous(breaks = years) +
        geom_text(
            aes(
                label =  scales::percent(percentage, accuracy = 1)),
            position = position_fill(vjust = 0.5),
            family = figure_spec$family,
            check_overlap = TRUE,
            size = 1.5) +
        labs(
            x = 'Year',
            y = '',
            fill = ""
        )  +
        theme_clean() +
        scale_fill_manual(values = nature_color_scheme) +
        th


    p <- ggpubr::ggarrange(total_sum,
                           total,
                           asset,
                           output,
                           ncol = 2,
                           nrow = 2,
                           common.legend = TRUE,
                           legend = 'bottom',
                           labels = c("A - Total global farmed animal and crop production.",
                                      "B - Contribution to the total global farmed production.",
                                      "C - Contribution to the global asset values.",
                                      "D - Contribution to the global output values."),
                           hjust = -0.2,
                           widths = rep(1, 4),
                           heights = rep(1, 4),
                           font.label = list(size = figure_spec$font_size,
                                             family = figure_spec$typeface,
                                             face = "italic")
    )
    ggsave(plot = p,
           filename = here::here('output', 'figures', "figure_2.pdf"),
           width = figure_spec$two_column_width,
           height = figure_spec$one_column_width * 2,
           units = figure_spec$units,
           dpi = figure_spec$dpi,
           device = figure_spec$format)

    # Also Save the data which created each figure exactly
    # to both a csv file and a kable and zip them together
    data_path <- here::here('output', 'figures', 'figure_2_data')



    data$livestock_asset |>
        write_data("figure_2_assets", data_path)

    outputs |>
        write_data("figure_2_outputs", data_path)

    total_value |>
        write_data("figure_2_total", data_path)


    zip_figure_data(data_path)



}



# Match the Command Line Args ---------------------------------------------
switch(
    as.character(args$figure),
    "2" = figure_2(df_list = config$data$output,
                   population_file = config$data$processed$tables$population)
)



stop()


# -------------------------------------------------------------------------



#' Figure 3 - World Maps of Asset + Output Values
#'
#' Global World map showing the total value of livestock assets + outputs
#' in each country
#'
#' @param df_list list containing the livestock and aquaculture files
#' @param year which year to plot (defaults to 2018)
#'
figure_3 <- function(df_list,
                     date = 2018,
                     fig_title = "Global Value of Livestock and Aquaculture (2018)",
                     fig_subtitle = "All values in constant 2014-2016 US Dollars.") {

    require(dplyr)
    require(tidyr)
    require(ggplot2)
    require(ggthemes)
    require(rnaturalearth)
    require(rnaturaleathdata)
    require(sf)


    # Load in the data
    data <- purrr::map(
        df_list,
        ~arrow::read_parquet(.x, as_data_frame = TRUE) |>
            dplyr::filter(year == date)
    )

    # Summarise by Country and produce a total value
    data$livestock_outputs <- data$livestock_values |>
        filter(gross_production_value_constant_2014_2016_thousand_us > 0,
                tonnes > 0) |>
        drop_na(gross_production_value_constant_2014_2016_thousand_us) |>
        group_by(iso3_code) |>
        summarise(
            value = sum(gross_production_value_constant_2014_2016_thousand_us,
                        na.rm = TRUE) * 1000,
            .groups = 'drop'
        )


    data$livestock_assets <- data$livestock_values |>
        filter(head > 0,
               stock_value_constant_2014_2016_usd > 0,
               item == "stock") |>
        group_by(iso3_code) |>
        summarise(
            value = sum(stock_value_constant_2014_2016_usd, na.rm = TRUE)
        )

    data$aquaculture_outputs <- data$aquaculture_values |>
        filter(
            aquaculture_constant_2014_2016_constant_usd_value > 0,
            tonnes > 0
        ) |>
        group_by(iso3_code) |>
        summarise(
            value = sum(aquaculture_constant_2014_2016_constant_usd_value,
                        na.rm = TRUE)
        )

    # Join the data and ensure the iso3_code matches before summarising
    data_tev <- bind_rows(
        data$livestock_outputs,
        data$livestock_assets,
        data$aquaculture_outputs
    ) |>
        mutate(
            iso3_code = toupper(iso3_code)
        ) |>
        group_by(iso3_code) |>
        summarise(
            value = sum(value, na.rm = TRUE)
        )


    # World data:
    # Imports simple features for all countries in the world
    world <- ne_countries(scale = "medium", returnclass = "sf") %>%
        rename(iso3_code = iso_a3)

    # Summarise data
    data <- data_tev %>%
        filter(iso3_code %in% world$iso3_code)


    world_value <- left_join(world, data, by = c("iso3_code"))


    # Bin the data into appropriate bins
    world_value <- select(world_value, name, iso3_code, value, geometry) %>%
        mutate(
            value_bins = factor(case_when(
                value < 10e9 ~ "<10B",
                value < 50e9 ~ "10-50B",
                value < 100e9 ~ "50-100B",
                value >= 100e9 ~ "> 100B",
                TRUE ~ "NA"
            ),
            levels = rev(c(
                "NA", "<10B",
                "10-50B",
                "50-100B",
                "> 100B"
            ))
            )
        )

    p <- ggplot(data = world) +
        geom_sf(fill = "#808080", color = "#D5E4EB") +
        geom_sf(data = world_value, aes(fill = value_bins), color = "#D5E4EB") +
        coord_sf(ylim = c(-55, 78)) +
        scale_fill_manual(
            values = rev(list(
                "NA" = "#808080",
                "<10B" = "#FFFFCC",
                "10-50B" = "#A1DAB4",
                "50-100B" = "#41B6C4",
                "> 100B" = "#225EA8"
            ))
        ) +
        labs(
            title = fig_title,
            fill = "USD ($)",
            subtitle = fig_subtitle,
            caption = ""
        ) +
        theme(
            legend.position = "right",
            axis.text.x = element_blank(),
            axis.ticks.x = element_blank(),
            panel.border = element_blank(),
            legend.text = element_text(size = 14, face = "italic"),
            legend.title = element_text(face = "bold.italic", size = 18),
            panel.grid.major = element_blank(),
            axis.line.x = element_blank(),
            plot.subtitle = element_text(size = 18, hjust = 0, face = "italic"),
            plot.title.position = "plot",
            plot.title = element_text(size = 25, face = "bold.italic"),
            plot.caption = element_text(size = 13, face = "italic")
        )
        ggsave(plot = p,
               filename = here::here('output', 'figures', "figure_3.pdf"),
               width = figure_spec$two_column_width,
               height = figure_spec$one_column_width,
               units = figure_spec$units,
               dpi = figure_spec$dpi,
               device = figure_spec$format)
}


#' Figure 4 - Livestock Productivity vs GDP per capita
#'
#' Plots Livestock Productivity vs GDP per capita
#' Countries are colored by income levels and certain countries are
#' highlighted based either on income level, or if they should be
#' selected.
#'
#'
#'
#' @param year year to be plotted
#' @param df_file  location of the livestock data
#' @param gdp_percap_file location of the World Bank GDP per capita data
#' @param add_spearman boolean value indicating wether to add a spearman
#' rank coefficient to each plot
#'
figure_4 <- function(df_file,
                     gdp_percap_file,
                     income_classification_file,
                     date = 2015,
                     use_spearman = TRUE,
                     selected_countries =  c("ETH", "BRA", "AUS",
                                             "TZA", "IND", "CHN",
                                             "IDN", "GBR", "USA")) {

    set.seed(0)

    data <- arrow::read_parquet(df_file, as_data_frame = TRUE)
    gdp_percap <- arrow::read_parquet(gdp_percap_file, as_data_frame = TRUE)

    # Read in the GDP percapita data and match it to income levels
    # Income lev
    gdp_percap <- arrow::read_parquet(gdp_percap_file, as_data_frame = TRUE) |>
        dplyr::select(country_code, contains("x")) |>
        tidyr::gather(key = "year", value = "gdp_per_capita_int_ppp",
                      -country_code) |>
        dplyr::mutate(
            year = as.numeric(substr(year, 2,length(year)))
        ) |>
        dplyr::filter(year == date) |>
        tidyr::drop_na(gdp_per_capita_int_ppp) |>
        dplyr::rename(
            iso3_code = country_code
        ) |>
        dplyr::select(-year)


    # Summarise livestock values to productivity
    productivity <- data |>
        dplyr::select(
            iso3_code, area,year,  item, animal,
            gross_production_value_constant_2014_2016_thousand_us,
            stock_value_constant_2014_2016_usd
        ) |>
        dplyr::filter(
            year == date,
            (gross_production_value_constant_2014_2016_thousand_us > 0) |
                (stock_value_constant_2014_2016_usd > 0) ) |>
        dplyr::group_by(
            iso3_code, area, year, animal
        ) |>
        dplyr::summarise(
            output_value = sum(gross_production_value_constant_2014_2016_thousand_us,
                               na.rm = TRUE) * 1000,

            asset_value = sum(stock_value_constant_2014_2016_usd ,
                              na.rm = TRUE),
            .groups = 'drop'
        ) |>
        dplyr::filter(
            (output_value > 0),
            (asset_value > 0) ) |>
        dplyr::group_by(iso3_code) |>
        dplyr::summarise(
            livestock_productivity = sum(output_value) / (sum(output_value) + sum(asset_value)),
            .groups = 'drop'
        )  |>
        dplyr::mutate(
            iso3_code = toupper(iso3_code)
        )

    # Join to World Bank Income Classifications
    # and categorize each country
    # TODO: Extract into processed data
    income_classification <- readxl::read_xlsx(income_classification_file,
                                               sheet = 3,
                                               skip = 11,
                                               col_names = c("iso3_code",
                                                             "country",
                                                             as.character(1987:2020)))  |>
        tidyr::gather(
            key = "year", value = "gini_income_cl", -iso3_code, -country
        ) |>
        dplyr::mutate(year = as.numeric(year),
                      gini_income_cl = factor(gini_income_cl,
                                              levels = c("L", "LM", "UM", "H"),
                                              labels = c("Low Income",
                                                         "Low Middle Income",
                                                         "Upper Middle Income",
                                                         "High Income"))) |>
        dplyr::filter(year == date) |>
        dplyr::select(-year)


    # Join to the data
    data <- productivity |>
        dplyr::left_join(gdp_percap, by = c("iso3_code")) |>
        dplyr::left_join(income_classification, by = c("iso3_code"))


    if (use_spearman) {
        spearman_str <- compute_spearman_rank(data,
                         "livestock_productivity",
                         "gdp_per_capita_int_ppp")$spearman_string
    } else {
        spearman_str <- ''
    }

    nature_color_scheme <- c(
        "Low Income" = "#DC0000FF" ,
        "Low Middle Income" = "#F39B7FFF",
        "Upper Middle Income" = "#00A087FF",
        "High Income" =  "#4DBBD5FF"
    )

    # Max and Min Countries by Group
    max_countries <- data |>
        dplyr::group_by(gini_income_cl) |>
        dplyr::slice_max(livestock_productivity, n = 1) |>
        dplyr::ungroup()

    min_countries <- data |>
        dplyr::group_by(gini_income_cl) |>
        dplyr::slice_min(livestock_productivity, n = 1) |>
        dplyr::ungroup()

    # Select gates countries to identify
    gates_countries <- data %>%
        filter(iso3_code %in% selected_countries)

    labelled_countries <- dplyr::bind_rows(gates_countries,
                                    max_countries,
                                    min_countries) |>
        dplyr::distinct()

    p <- ggplot(data) +
        geom_point(
            aes(x = gdp_per_capita_int_ppp,
                y = livestock_productivity,
                color = gini_income_cl),
            size = 1,
            alpha = 1
        ) +
        scale_y_percent(breaks = c(.5, .10, .25, .75, 1)) +
        scale_x_continuous(
            labels = scales::dollar_format(),
            breaks = c(5, 10, 25, 50, 75, 100) * 1e3
        ) +
        ggrepel::geom_label_repel(data = labelled_countries,
            aes(x = gdp_per_capita_int_ppp,
                y =  livestock_productivity, label = country,
                color =  gini_income_cl),
            size = 2,
            label.padding = 0.1,
            alpha = 1,
            force = 10,
            seed = 0,
            show.legend = FALSE,
            max.overlaps = getOption("ggrepel.max.overlaps", default = 4)
        ) +
        scale_color_manual(values = nature_color_scheme) +
        labs(
            title = "GDP Per Capita  vs Livestock Productivity (2015)",
            # subtitle = paste("Values are in current GDP Per Capita (International $) ",
            #                  ifelse(use_spearman, spearman_str,  " "), sep = "\n"),
            subtitle = spearman_str,
            x = "GDP per capita (Int $)",
            y = "Livestock Productivity (%)",
            color = " ",
            size = "",
            caption = paste0("1. GDP Per Capita Source: ", config$data$source$tables$gdp_per_capita_ppp$url,
                             "\n",
                             "2. Income Classifications Source: ",
                             config$data$source$tables$income_classification_history$url)
        ) +
        theme_clean() +
        theme(
            legend.position = "bottom",
            legend.title = element_text(family = figure_spec$typeface,
                                        size = figure_spec$font_size,
                                        face = NULL),
            legend.text = element_text(family = figure_spec$typeface,
                                       size = figure_spec$font_size),
            axis.title.y = element_text(family = figure_spec$typeface,
                                        size = figure_spec$font_size),
            axis.title.x = element_text(family = figure_spec$typeface,
                                        size = figure_spec$font_size),
            plot.title = element_text(family = figure_spec$typeface,
                                      size = figure_spec$font_size,
                                      face = NULL),
            plot.subtitle = element_text(family = figure_spec$typeface,
                                        size = figure_spec$font_size,
                                        face = NULL),
            axis.text.y = element_text(family = figure_spec$typeface,
                                       size = figure_spec$font_size - 1),
            axis.text.x = element_text(family = figure_spec$typeface,
                                       size = figure_spec$font_size - 1),
            plot.caption = element_text(family = figure_spec$typeface,
                                       size = figure_spec$font_size)
        )

    ggsave(plot = p,
           filename = here::here('output', 'figures', "figure_4.pdf"),
           width = figure_spec$two_column_width,
           height = figure_spec$two_column_width * (1 / 1.6),
           units = figure_spec$units,
           dpi = figure_spec$dpi,
           device = figure_spec$format)

    data_path <- here::here('output', 'figures', 'figure_4_data')

    data |>
        write_data("figure_4_livestock_productivity",  data_path)

    zip_figure_data(data_path)


}

## Testing
args <- list()
args$figure <- 4

if (args$figure  == 4) {
    figure_4(
        df_file = config$data$output$livestock_values,
        gdp_percap_file = config$data$processed$tables$gdp_per_capita_ppp,
        income_classification_file = file.path(
            config$data$source$tables$income_classification_history$dir,
            config$data$source$tables$income_classification_history$file_name
        )
    )
}


#' Figure 5
#' Livestock Productivity vs GDP Per Capita split by animal types
#'
#' @param df livestock values
#' @param year year to plot
#' @param add_spearman boolean value to indicate weather the spearman
#' rank correlation test should be added
#'
figure_5 <- function(df_file,
                     gdp_percap_file,
                     income_classification_file,
                     date = 2015,
                     use_spearman = TRUE) {


    data <- arrow::read_parquet(df_file, as_data_frame = TRUE)
    gdp_percap <- arrow::read_parquet(gdp_percap_file, as_data_frame = TRUE)

    # Read in the GDP percapita data and match it to income levels
    # Income lev
    gdp_percap <- arrow::read_parquet(gdp_percap_file, as_data_frame = TRUE) |>
        dplyr::select(country_code, contains("x")) |>
        tidyr::gather(key = "year", value = "gdp_per_capita_int_ppp",
                      -country_code) |>
        dplyr::mutate(
            year = as.numeric(substr(year, 2,length(year)))
        ) |>
        dplyr::filter(year == date) |>
        tidyr::drop_na(gdp_per_capita_int_ppp) |>
        dplyr::rename(
            iso3_code = country_code
        ) |>
        dplyr::select(-year)


    # Summarise livestock values to productivity
    productivity <- data |>
        dplyr::select(
            iso3_code, area,year,  item, animal,
            gross_production_value_constant_2014_2016_thousand_us,
            stock_value_constant_2014_2016_usd
        ) |>
        dplyr::filter(
            year == date,
            (gross_production_value_constant_2014_2016_thousand_us > 0) |
                (stock_value_constant_2014_2016_usd > 0),
            animal %in% c("cattle", "chicken", "pig", "sheep")) |>
        dplyr::group_by(
            iso3_code, area, year, animal
        ) |>
        dplyr::summarise(
            output_value = sum(gross_production_value_constant_2014_2016_thousand_us,
                               na.rm = TRUE) * 1000,

            asset_value = sum(stock_value_constant_2014_2016_usd ,
                              na.rm = TRUE),
            .groups = 'drop'
        ) |>
        dplyr::filter(
            (output_value > 0),
            (asset_value > 0) ) |>
        dplyr::group_by(iso3_code, animal) |>
        dplyr::summarise(
            livestock_productivity = sum(output_value) / (sum(output_value) + sum(asset_value)),
            .groups = 'drop'
        )  |>
        dplyr::mutate(
            iso3_code = toupper(iso3_code),
            animal = stringr::str_to_title(animal)
        )

    # Join to World Bank Income Classifications
    # and categorize each country
    # TODO: Extract into processed data
    income_classification <- readxl::read_xlsx(income_classification_file,
                                               sheet = 3,
                                               skip = 11,
                                               col_names = c("iso3_code",
                                                             "country",
                                                             as.character(1987:2020)))  |>
        tidyr::gather(
            key = "year", value = "gini_income_cl", -iso3_code, -country
        ) |>
        dplyr::mutate(year = as.numeric(year),
                      gini_income_cl = factor(gini_income_cl,
                                              levels = c("L", "LM", "UM", "H"),
                                              labels = c("Low Income",
                                                         "Low Middle Income",
                                                         "Upper Middle Income",
                                                         "High Income"))) |>
        dplyr::filter(year == date) |>
        dplyr::select(-year)


    # Join to the data
    data <- productivity |>
        dplyr::left_join(gdp_percap, by = c("iso3_code")) |>
        dplyr::left_join(income_classification, by = c("iso3_code")) |>
        dplyr::mutate(
            animal = factor(animal,
                            levels = c("Cattle", "Chicken", "Pig", "Sheep"))
        )

    spearman_strs <- purrr::imap(
        data |>
            group_by(animal) |>
            nest() |>
            pull(data),
        ~compute_spearman_rank(.x, "livestock_productivity",
                               "gdp_per_capita_int_ppp",
                               extra_str = paste(levels(data$animal)[.y],':'))
    )



    levels(data$animal) <- c(
        Cattle = spearman_strs[[1]],
        Chicken = spearman_strs[[2]],
        Pig = spearman_strs[[3]],
        Sheep = spearman_strs[[4]]
    )


    nature_color_scheme <- c(
        "Low Income" = "#DC0000FF" ,
        "Low Middle Income" = "#F39B7FFF",
        "Upper Middle Income" = "#00A087FF",
        "High Income" =  "#4DBBD5FF"
    )


    p <- ggplot(data) +
        geom_point(
        aes(x = gdp_per_capita_int_ppp,
            y = livestock_productivity,
            color = gini_income_cl),
        size = 1,
        alpha = 1
       ) +
        scale_y_percent(breaks = c(0, .5, .10, .25, .75, 1)) +
        scale_x_continuous(
            labels = scales::dollar_format(),
            breaks = c(5, 15, 25, 50, 75, 100) * 1e3
        ) +
        facet_wrap(vars(animal), labeller = label_parsed,
                   scales = "free_x") +
        scale_color_manual(values = nature_color_scheme) +
        labs(
            title = glue::glue("GDP Per Capita vs Livestock Productivity for Cattle, Chicken, Pig and Sheep ({date})"),
            subtitle = "Values are in current GDP Per Capita (International $) ",
            x = "GDP per capita (Int $)",
            y = "Livestock Productivity (%)",
            color = " ",
            size = "",
            caption = paste0("1. GDP Per Capita Source: ", config$data$source$tables$gdp_per_capita_ppp$url,
                             "\n",
                             "2. Income Classifications Source: ",
                             config$data$source$tables$income_classification_history$url)
        ) +
        theme_clean() +
        theme(
            legend.position = "bottom",
            legend.title = element_text(family = figure_spec$typeface,
                                        size = figure_spec$font_size,
                                        face = NULL),
            legend.text = element_text(family = figure_spec$typeface,
                                       size = figure_spec$font_size),
            axis.title.y = element_text(family = figure_spec$typeface,
                                        size = figure_spec$font_size),
            axis.title.x = element_text(family = figure_spec$typeface,
                                        size = figure_spec$font_size),
            plot.title = element_text(family = figure_spec$typeface,
                                      size = figure_spec$font_size,
                                      face = NULL),
            plot.subtitle = element_text(family = figure_spec$typeface,
                                         size = figure_spec$font_size,
                                         face = NULL),
            axis.text.y = element_text(family = figure_spec$typeface,
                                       size = figure_spec$font_size - 1),
            axis.text.x = element_text(family = figure_spec$typeface,
                                       size = figure_spec$font_size - 2),
            plot.caption = element_text(family = figure_spec$typeface,
                                        size = figure_spec$font_size),
            strip.text = element_text(family = figure_spec$typeface,
                                      size = figure_spec$font_size)
        )

    ggsave(plot = p,
           filename = here::here('output', 'figures', "figure_5.pdf"),
           width = figure_spec$two_column_width,
           height = figure_spec$two_column_width * (1 / 1.6),
           units = figure_spec$units,
           dpi = figure_spec$dpi,
           device = figure_spec$format)


}



## Testing
args <- list()
args$figure <- 5

if (args$figure  == 5) {
    figure_5(
        df_file = config$data$output$livestock_values,
        gdp_percap_file = config$data$processed$tables$gdp_per_capita_ppp,
        income_classification_file = file.path(
            config$data$source$tables$income_classification_history$dir,
            config$data$source$tables$income_classification_history$file_name
        )
    )
}



## Figure 6 - Asset value change per annum (2005-2018)
figure_6 <- function(df_file,
                     population_file,
                     year_range = c(2005, 2018),
                     fig_title = "Average Livestock Asset Value Change per capita (%) per year between 2005 and 2018",
                     fig_subtitle =  "") {
    require(dplyr)
    require(tidyr)
    require(ggplot2)
    require(ggthemes)
    require(rnaturalearth)
    require(sf)
    require(ggtext)


    # Load in the data
    data <- arrow::read_parquet(df_file, as_data_frame = TRUE) |>
            dplyr::filter(year %in% year_range[1]:year_range[2]) |>
            dplyr::mutate(iso3_code = toupper(iso3_code))


    population <- arrow::read_parquet(population_file) |>
        dplyr::select(country_code, contains('x')) |>
        tidyr::gather(key = "year", value = "population", -country_code) |>
        dplyr::mutate(
            year = as.numeric(substr(year, 2, length(year)))
        ) |>
        dplyr::filter(year %in% year_range[1]:year_range[2]) |>
        dplyr::rename(iso3_code = country_code)




    assets <- data |>
        dplyr::filter(head > 0,
               stock_value_constant_2014_2016_usd > 0,
               item == "stock") |>
        dplyr::mutate(value = stock_value_constant_2014_2016_usd) |>
        dplyr::group_by(iso3_code, year) |>
        dplyr::summarise(
            value = sum(value, na.rm = TRUE),
            .groups = 'drop'
        ) |>
        dplyr::left_join(population, by = c("iso3_code", "year")) |>
        dplyr::group_by(iso3_code) |>
        dplyr::arrange(year) %>%
        dplyr::mutate(
            value = value/population
        ) |>
        dplyr::mutate(value = 100 * (value - lag(value)) / (lag(value)) / (year - lag(year))) %>%
        dplyr::summarise(
            avg_change = mean(value, na.rm = TRUE), .groups = "drop"
        ) %>%
        dplyr::mutate(
            change_vals = as.factor(
                cut(avg_change,
                breaks = c(-Inf, -2.5, 0, 1, 2.5, 5, 10, Inf),
                labels = c("&lt; -2.5", "-2.5 to 0", "0 to 1", "1 to 2.5", "2.5 to 5", "5 to 10", "&gt;10")
            ))
        )




    # World data:
    # Imports simple features for all countries in the world
    world <- ne_countries(scale = "medium", returnclass = "sf") %>%
        rename(iso3_code = iso_a3) |>
        left_join(assets, by = "iso3_code")


    p <- ggplot(world) +
        geom_sf(fill = "#808080", color = "#D5E4EB") +
        geom_sf(aes(fill = change_vals), color = "#D5E4EB") +
        coord_sf(ylim = c(-55, 78)) +
        theme_economist() +
        scale_fill_manual(
            values = setNames(
                c("#E64B35FF", "#F39B7FFF", "#F7FCF5" ,
                  "#74C476" ,"#41AB5D" ,"#238B45", "#005A32", "#808080"),
                c("&lt;-2.5", "-2.5 to 0", "0 to 1", "1 to 2.5", "2.5 to 5", "5 to 10", "&gt;10", "NA")
            )
        ) +
        labs(
            title = fig_title,
            fill = "",
            subtitle = fig_subtitle
        ) +
        guides(fill = guide_legend(nrow = 1)) +
        theme(
            legend.position = "bottom",
            axis.text.x = element_blank(),
            axis.ticks.x = element_blank(),
            panel.border = element_blank(),
            legend.text = ggtext::element_markdown(size = figure_spec$font_size,
                                                   family = figure_spec$family),
            legend.title = ggtext::element_markdown(size = figure_spec$font_size,
                                                    family = figure_spec$family),
            panel.grid.major = element_blank(),
            axis.line.x = element_blank(),
            plot.subtitle = element_text(size = figure_spec$font_size,
                                          family = figure_spec$family),
            plot.title = element_text(size = figure_spec$font_size,
                                       family = figure_spec$family, face = "plain"),
            plot.caption = element_text(size = figure_spec$font_size,
                                        family = figure_spec$family,
                                        face = "plain")
        )
    ggsave(plot = p,
           filename = here::here('output', 'figures', "figure_6.pdf"),
           width = figure_spec$two_column_width,
           height = figure_spec$two_column_width * (1 / 1.6),
           units = figure_spec$units,
           dpi = figure_spec$dpi,
           device = figure_spec$format)


}

## DEBUG
args <- list()
args$figure <- 6
if (args$figure == 6) {
    figure_6( config$data$output$livestock_values,
              population_file = config$data$processed$tables$population)
}


## Figure 7 - Average annual change in livestock and Aquaculture
## Output Values (2005-2018)
figure_7 <- function(df_list,
                    year_range = c(2005, 2018),
                    population_file,
                    fig_title = "Average Livestock and Aquaculture Output Value Change per Capita (%) per year between 2005 and 2018",
                    fig_subtitle =  "") {
    require(dplyr)
    require(tidyr)
    require(ggplot2)
    require(ggthemes)
    require(rnaturalearth)
    require(sf)
    require(ggtext)


    # Load in the data
    data <- purrr::map(
        df_list,
        ~arrow::read_parquet(.x, as_data_frame = TRUE) |>
        dplyr::filter(year %in% year_range[1]:year_range[2]) |>
        dplyr::mutate(iso3_code = toupper(iso3_code))
    )

    # Summarise by Country and produce a total value
    data$livestock_outputs <- data$livestock_values |>
        dplyr::filter(gross_production_value_constant_2014_2016_thousand_us > 0,
               tonnes > 0) |>
        tidyr::drop_na(gross_production_value_constant_2014_2016_thousand_us) |>
        dplyr::group_by(iso3_code, year) |>
        dplyr::summarise(
            value = sum(gross_production_value_constant_2014_2016_thousand_us,
                        na.rm = TRUE) * 1000,
            .groups = 'drop'
        )

   data$aquaculture_outputs <- data$aquaculture_values |>
        dplyr::filter(
            aquaculture_constant_2014_2016_constant_usd_value > 0,
            tonnes > 0
        ) |>
        dplyr::group_by(iso3_code, year) |>
        dplyr::summarise(
            value = sum(aquaculture_constant_2014_2016_constant_usd_value,
                        na.rm = TRUE)
        )

   population <- arrow::read_parquet(population_file) |>
       dplyr::select(country_code, contains('x')) |>
       tidyr::gather(key = "year", value = "population", -country_code) |>
       dplyr::mutate(
           year = as.numeric(substr(year, 2, length(year)))
       ) |>
       dplyr::filter(year %in% year_range[1]:year_range[2]) |>
       dplyr::rename(iso3_code = country_code)



    outputs <- bind_rows(data$livestock_outputs, data$aquaculture_outputs) |>
        dplyr::group_by(iso3_code, year) |>
        dplyr::summarise(value = sum(value, na.rm = TRUE),
                         .groups = 'drop') |>
        dplyr::left_join(population, by = c("iso3_code", "year")) |>
        dplyr::group_by(iso3_code) |>
        dplyr::arrange(year) %>%
        dplyr::mutate(
            value = value/population
        ) |>
        dplyr::mutate(value = 100 * (value - lag(value)) / (lag(value)) / (year - lag(year))) %>%
        dplyr::summarise(
            avg_change = mean(value, na.rm = TRUE), .groups = "drop"
        ) %>%
        dplyr::mutate(
            change_vals = as.factor(
                cut(avg_change,
                    breaks = c(-Inf, -2.5, 0, 1, 2.5, 5, 10, Inf),
                    labels = c("&lt;-2.5", "-2.5 to 0", "0 to 1", "1 to 2.5", "2.5 to 5", "5 to 10", "&gt;10")
                ))
        )






    # World data:
    # Imports simple features for all countries in the world
    world <- ne_countries(scale = "medium", returnclass = "sf") %>%
        rename(iso3_code = iso_a3) |>
        left_join(outputs, by = "iso3_code")


    p <- ggplot(world) +
        geom_sf(fill = "#808080", color = "#D5E4EB") +
        geom_sf(aes(fill = change_vals), color = "#D5E4EB") +
        coord_sf(ylim = c(-55, 78)) +
        theme_economist() +
        scale_fill_manual(
            values = setNames(
                c("#E64B35FF", "#F39B7FFF", "#F7FCF5" ,
                  "#74C476" ,"#41AB5D" ,"#238B45", "#005A32", "#808080"),
                c("&lt;-2.5", "-2.5 to 0", "0 to 1", "1 to 2.5", "2.5 to 5", "5 to 10", "&gt;10", "NA")
            )
        ) +
        labs(
            title = fig_title,
            fill = "",
            subtitle = fig_subtitle
        ) +
        guides(fill = guide_legend(nrow = 1)) +
        theme(
            legend.position = "bottom",
            axis.text.x = element_blank(),
            axis.ticks.x = element_blank(),
            panel.border = element_blank(),
            legend.text = ggtext::element_markdown(size = figure_spec$font_size,
                                                   family = figure_spec$family),
            legend.title = ggtext::element_markdown(size = figure_spec$font_size,
                                                    family = figure_spec$family),
            panel.grid.major = element_blank(),
            axis.line.x = element_blank(),
            plot.subtitle = element_text(size = figure_spec$font_size,
                                         family = figure_spec$family),
            plot.title = element_text(size = figure_spec$font_size,
                                      family = figure_spec$family, face = "plain"),
            plot.caption = element_text(size = figure_spec$font_size,
                                        family = figure_spec$family,
                                        face = "plain")
        )

    ggsave(plot = p,
           filename = here::here('output', 'figures', "figure_7.pdf"),
           width = figure_spec$two_column_width,
           height = figure_spec$two_column_width * (1 / 1.6),
           units = figure_spec$units,
           dpi = figure_spec$dpi,
           device = figure_spec$format)
}

## DEBUG
args <- list()
args$figure <- 7
if (args$figure == 7) {
    figure_7( df_list = config$data$output,
              population_file = config$data$processed$tables$population
              )
}


# Appendix:

## Figure A.1 Pie Chart of Asset + Output Values (2018)
figure_a1 <- function(df_list, date = 2018 ) {

    # Load in the data
    data <- purrr::map(
        df_list,
        ~arrow::read_parquet(.x, as_data_frame = TRUE) |>
            dplyr::filter(year == date) |>
            dplyr::mutate(iso3_code = toupper(iso3_code))
    )

    # Summarise by Country and produce a total value
    data$livestock_outputs <- data$livestock_values |>
        filter(gross_production_value_constant_2014_2016_thousand_us > 0,
               tonnes > 0) |>
        drop_na(gross_production_value_constant_2014_2016_thousand_us) |>
        group_by(iso3_code, animal) |>
        summarise(
            value = sum(gross_production_value_constant_2014_2016_thousand_us,
                        na.rm = TRUE) * 1000,
            .groups = 'drop'
        )


    data$livestock_assets <- data$livestock_values |>
        filter(head > 0,
               stock_value_constant_2014_2016_usd > 0,
               item == "stock") |>
        group_by(iso3_code, animal) |>
        summarise(
            value = sum(stock_value_constant_2014_2016_usd, na.rm = TRUE)
        )

    data$aquaculture_outputs <- data$aquaculture_values |>
        filter(
            aquaculture_constant_2014_2016_constant_usd_value > 0,
            tonnes > 0
        ) |>
        group_by(iso3_code) |>
        summarise(
            value = sum(aquaculture_constant_2014_2016_constant_usd_value,
                        na.rm = TRUE)
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
                !(animal %in% c("cattle", "chicken",
                                "goat", "sheep", "pig",
                                "Aquaculture")) ~ "Other",
                TRUE ~ animal
            )
        ) |>
        dplyr::group_by(animal) |>
        dplyr::summarise(
            value = sum(value, na.rm = TRUE)
        ) |>
        dplyr::mutate(animal = stringr::str_to_sentence(animal)) |>
        dplyr::mutate(value_label = scales::dollar_format(
            scale = 1e-9, suffix = "B",
            largest_with_cents = 0
        )(value), value_pct = value / sum(value, na.rm = TRUE)
        ) %>%
        mutate(animal = forcats::fct_reorder(animal, value, sum)) %>%
        arrange(desc(animal))


    sectors <- c(
        "Aquaculture", "Cattle", "Chicken", "Goat",
        "Sheep", "Pig", "Other"
    )
    pal <- ggsci::pal_jco()(7)
    names(pal) <- stringr::str_to_title(sectors)


    df2 <- df %>%
        arrange(desc(animal)) %>%
        mutate(
            csum = rev(cumsum(rev(value))),
            pos = value * 0.5 + lead(csum, 1),
            pos = if_else(is.na(pos), value * 0.5, pos)
        )

    total <- scales::dollar_format(scale = 1e-12, suffix = "T")(sum(df$value))
    # Create a basic bar
    p <- ggplot(df, aes(x = "", y = value, fill = forcats::fct_inorder(animal)),
           color = "grey"
    ) +
        geom_col(width = 1, color = "grey") +
        coord_polar(theta = "y") +
        scale_fill_manual(values = pal[levels(df$animal)]) +
        ggrepel::geom_label_repel(
            data = df2,
            aes(
                y = pos, label = paste0(animal, ":", value_label, "\n ", scales::percent(value_pct, accuracy = .1)),
                fill = animal
            ),
            size = 6,
            nudge_x = 0,
            nudge_y = 5,
            segment.color = rev(pal[levels(df$animal)]),
            show.legend = FALSE,
            color = "white",
            min.segment.length = 5,
            box.padding = 0.5,
            label.size = 0,
            label.paddi0g = 0.5,
            force = 20
        ) +
        theme_void() +
        labs(
            title = glue::glue("Global Value of Livestock - {date} (Total: {total})"),
            subtitle = "All values in constant 2014-2016 US dollars."
        ) +
        theme(
            legend.position = "none",
            plot.title = element_text(size = 30, face = "bold.italic"),
            plot.subtitle = element_text(size = 20, face = "italic")
        )

    ggsave(plot = p, filename = here::here('output', 'figures', "figure_a1.pdf"),
           width = 14, height = 18, units = "in", dpi = 400,
           device = "pdf")
}

## Figure A.2 World Maps of Asset Values per Livestock Type
figure_a2 <- function(df) {

}

## Figure A.4 World Map of Output Values per Livestock Type
figure_a4 <- function(df) {

}









