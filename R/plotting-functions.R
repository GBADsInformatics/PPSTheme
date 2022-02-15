################################################################
#
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
# Date Created:  20220214
#
# Description:  This script contains helper functions for creating plots
# which will potentially be added to the manuscript
####################################



# Stacked Area Charts -----------------------------------------------------
# Function to create a stacked area chart


th <-  theme(
legend.position = "bottom",
legend.title = element_text(size = 18, face = "bold.italic"),
legend.text = element_text(size = 20, face = "italic"),
plot.title = element_text(face = "bold.italic", size = 25),
plot.subtitle = element_text(face = "italic", size = 20),
axis.text.y = element_text(size = 20, face = "bold.italic"),
axis.title = element_text(hjust = 0.5),
axis.text.x = element_text(size = 20, face = "bold.italic")
)



#
#  Returns the position and % for a stacked area chart
#
stacked_area.get_position <- function(df, value,group_var,  key_col, key_order) {
    df %>%
        mutate(
            key = factor( {{ key_col }} , levels = key_order, ordered = TRUE)
        ) %>%
        group_by({{ group_var }}) %>%
        arrange(desc(key)) %>%
        mutate(
            percentage = {{ value }}/sum({{ value }}, na.rm = TRUE),
            position = cumsum({{ value }}) - 0.5 * {{ value }}
        ) %>%
        ungroup()
}



#
# Attaches initial and final labels to a stacked area chart
#
stacked_area.append_end_labels <- function(plot, df, year_col, position_col, per_col, ...) {
    # Function to format percentages
    pct <- scales::percent_format(accuracy = 1)

    if (length(list(...)) == 0) {
        geom_label_repel_settings <- list(
            size = 10,
            nudge_x = 1,
            min.segment.length = 0.1,
            box.padding = 1,
            segment.size = 2,
            label.padding = 0.5
        )
    } else {
        geom_label_repel_settings <- list(...)
    }

    # Create the labels
    plot +
        ggrepel::geom_label_repel(
            data = df %>%
                filter({{ year_col }} %in% final_year),
            aes(x = {{ year_col}}, y = {{ position_col }} , label = pct( {{ per_col }} ))) +
        ggrepel::geom_label_repel(

            data = df %>%
                filter({{ year_col }} %in% first_year),
            aes(x = {{ year_col}}, y = {{ position_col }}, label = pct( {{ per_col }} )),
        )

}


stacked_area.plot <- function(df, keys,  color_pal, ...) {

    # Extract the first and last year
    first_year <- df %>% pull(year) %>% min()
    final_year <- df %>% pull(year) %>% max()



    ggplot(df,  aes(year, value)) +
        geom_area(aes(fill = {{keys}})) +
        ggrepel::geom_label_repel(
            data = df %>%
                filter(year  == final_year),
            aes(x =  year,
                y = position,
                label = pct(percentage),
                color = {{ keys }}
            ),
            size = 6,
            nudge_x = 1,
            min.segment.length = 0.1,
            box.padding = 1,
            segment.size = 2,
            label.padding = 0.5,
        )   +
        ggrepel::geom_label_repel(
            data = df %>%
                filter(year  == first_year),
            aes(x =  year,  y = position, label = pct(percentage), color = {{keys}}),
            size = 6,
            nudge_x = -1,
            min.segment.length = 0.1,
            box.padding = 1,
            segment.size = 2,
            label.padding = 0.5,
        )   +
        scale_fill_manual(values = color_pal) +
        scale_color_manual(values = color_pal, guide = FALSE) +
        guides(fill = guide_legend(nrow = 1)) +
        scale_y_continuous(labels = scales::dollar_format(scale = 1e-12, suffix = " Trillion", accuracy = .1)) +
        scale_x_continuous(limits = c(first_year - 2, final_year + 2)) +
        labs(...) +
        theme_ipsum() +
        th
}



# Pie Charts --------------------------------------------------------------


pie_chart.yearly_value <- function(df, date, id_col,color_pal, title ="", subtitle="", footnotes="") {

    require(scales)
    require(forcats)
    require(ggplot2)
    require(ggrepel)

    # Transform input data
    df <- df %>%
        filter(year == date) %>%
        mutate(
            sector = str_to_title({{id_col}}),
            value_label = dollar(value,
                scale = 1e-9, suffix = "B", accuracy = .1),
            value_pct = value / sum(value, na.rm = TRUE)
        ) %>%
        mutate(sector = fct_reorder(sector, value, sum)) %>%
        arrange(desc(sector))


    # Get the position to place the pie chart labels
    df2 <- df %>%
        arrange(desc(sector)) %>%
        mutate(
            csum = rev(cumsum(rev(value))),
            pos = value * 0.5 + lead(csum, 1),
            pos = if_else(is.na(pos), value * 0.5, pos)
        )


    # Global total
    total <- dollar(sum(df$value), scale = 1e-12, suffix = "T")

    ##  Create Pie Chart
    chart <- df %>%
        ggplot(
            aes(x = "", y = value, fill = fct_inorder(sector)), color = "grey") +
        geom_col(width = 1, color = "grey") +
        coord_polar(theta = "y") +
        scale_fill_manual(values = color_pal[levels(df$sector)]) +
        ggrepel::geom_label_repel(
            data = df2,
            aes(
                y = pos, label = paste0(sector,
                                        ":",
                                        value_label,
                                        "\n ",
                                        percent(value_pct, accuracy = .1)),
                fill = sector
            ),
            size = 6,
            nudge_x = 0,
            nudge_y = 5,
            segment.color = rev(color_pal[levels(df$sector)]),
            show.legend = FALSE,
            color = "white",
            min.segment.length = 5,
            box.padding = 0.5,
            label.size = 0,
            label.padding = 0.5,
            force = 20
        ) +
        theme_void() +
        labs(
            title = title,
            subtitle = subtitle
        ) +
        theme(
            legend.position = "none",
            plot.title = element_text(size = 30, face = "bold.italic"),
            plot.subtitle = element_text(size = 20, face = "italic")
        )
    return(chart)
}



