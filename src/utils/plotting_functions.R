####################################
# Creator: Gabriel Dennis
# GitHub: denn173
# Email: gabriel.dennis@csiro.au
# Date last edited:20210913
#
# File Description: This file contains all
# plotting functions to be used in the targets pipeline
#
####################################
####################################
library(ggtext)
library(showtext)
source('./src/data_loading_functions.R')

world_map_plotter <- function(O1, AS2, TEV,TEV_sector) {
  for (year in c(2015)) {
    #world_map(O1, year, usd_value, type = "O1")
    #world_map_plot_sector(O1, year, usd_value, type = "O1")
    world_map_percap_plot(O1, year, usd_value, type = 'O1')
    #world_map(AS2, year, usd_value, type = "AS2")
    world_map_percap_plot(AS2, year, usd_value, type = "AS2")
    #world_map_plot_sector(AS2, year, usd_value, type = "AS2")
    #world_map(TEV, year, value, type = "TEV")
    world_map_percap_plot(TEV, year, value, type = "TEV")
    #world_map_plot_sector(TEV_sector, year, value_usd, type = "TEV")
  }
}





world_map <- function(data, date, value, type) {
  # Function to plot and save basic world maps for each
  # Scenario
  require(tidyverse)
  require(rnaturalearth)
  require(rnaturalearthdata)
  require(ggthemes)

  theme_set(theme_economist())


  if (!(type %in% c("O1", "AS2", "TEV"))) {
    stop(
      paste0(type, "not in c(O1, AS2, TEV)")
    )
  }

  # Set title subtitla and caption

  if (type == "O1") {
    ttl <- list(
      title = glue::glue("What is the global distribution of the value of direct livestock outputs in {date}?"),
      subtitle = paste0(
        "This estimate includes livestock and aquatic  products",
        " such as meat, milk, eggs and fish.",
        "<br>  All values  are reported in current US dollars."
      ),
      caption = "Data: FAO (2021)"
    )
  } else if (type == "AS2") {
    ttl <- list(
      title = glue::glue("What is the global distribution of the value of animal stock in {date}?"),
      subtitle = paste0(
        "This estimate includes cattle, chickens, pigs, sheep, pigs, camels, mules, and horses.",
        "<br> All values are reported in current US dollars."
      ),
      caption = "Data: FAO (2021)"
    )
  } else {
    ttl <- list(
      title = glue::glue("<b> What is the global distribution of the total economic value of livestock in {date}?"),
      subtitle = paste0(
        "This estimate includes the value of animal stock, as well as the value of direct livestock outputs.",
        "<br> All values  are reported in current US dollars."
      ),
      caption = "Data: FAO (2021)"
    )
  }

  # World data
  world <- ne_countries(scale = "medium", returnclass = "sf") %>%
    rename(iso3 = iso_a3)

  # Rename data
  data <- data %>%
    rename(value = {{value}})



  # Summarise data
  data <- data %>%
    filter(year == date) %>%
    group_by(iso3) %>%
    summarise(value = sum(value, na.rm = TRUE))

  mappers <- calc_quintiles(data)

  data$value_bin <- cut(data$value,
    c(
      0, unlist(mappers$values)[1:length(mappers$values) - 1],
      max(data$value)
    ),
    labels = names(mappers$values),
    include.lowest = TRUE,
    right = FALSE,
    ordered_result = TRUE
  )


  world_values <- left_join(world, data, by = c("iso3")) %>%
    select(value_bin, geometry)


  p <- ggplot(data = world) +
    geom_sf(fill = "#808080", color = "#D5E4EB") +
    geom_sf(data = world_values, aes(fill = value_bin), color = "#D5E4EB") +
    coord_sf(ylim = c(-55, 78)) +
    scale_fill_manual(
      values = rev(mappers$colors)
    ) +
    labs(
      title = ttl$title,
      subtitle = ttl$subtitle,
      fill = "USD ($)",
      caption = ttl$caption
    ) +
    theme(
      legend.position = c(0.1, 0.1),
      legend.justification = c("left", "bottom"),
      legend.text = element_text(size = 12, face = "italic"),
      legend.key = element_rect(linetype = 19),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      panel.border = element_blank(),
      panel.grid.major = element_blank(),
      axis.line.x = element_blank(),
      plot.subtitle = element_markdown(
        size = 15,
        hjust = 0,
        family = "Times"
      ),
      plot.title.position = "plot",
      plot.title = element_markdown(
        size = 20,
        face = "bold.italic",
        family = "Times"
      ),
      plot.caption = element_markdown(
        size = 15,
        face = "italic",
        hjust = 0
      )
    ) +
    guides(shape = guide_legend(override.aes = list(shape = 19)))


  ggsave(glue::glue("output/tar_figures/{type}/world_map_{type}_{date}.png"),
    plot = p, width = 55, height = 26, units = "cm", device = "png"
  )
}

world_map_plot_sector <- function(data, date, value_var, type) {
  # Plots the world map by sector
  require(tidyverse)
  require(rnaturalearth)
  require(rnaturalearthdata)
  require(ggthemes)

  theme_set(theme_economist())


  if (!(type %in% c("O1", "AS2", "TEV"))) {
    stop(
      paste0(type, "not in c(O1, AS2, TEV)")
    )
  }

  data <- data %>%
    dplyr::rename(value = {{ value_var }})

  # World data
  world <- ne_countries(scale = "medium", returnclass = "sf") %>%
    rename(iso3 = iso_a3)

  if (type == "O1") {
    ttl <- list(
      title = glue::glue("What is the global distribution of the value of meat, milk, eggs and fish outputs in {date}?"),
      subtitle = paste0("All values  are reported in current US dollars"),
      caption = "Data: FAO (2021)"
    )
    sectors <- c("meat", "milk", "eggs", "fish")
    data <- data %>%
      filter(stringr::str_detect(item, "meat|milk|eggs|fish"), year == date) %>%
      mutate(
        item = case_when(
          str_detect(item, "meat") ~ "Meat",
          str_detect(item, "milk") ~ "Milk",
          str_detect(item, "eggs") ~ "Eggs",
          str_detect(item, "fish") ~ "Fish"
        )
      ) %>%
      group_by(iso3, item) %>%
      summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
      mutate(item = stringr::str_to_title(item))

  } else if (type == "AS2") {
    ttl <- list(
      title = glue::glue("What is the global distribution of the value of cattle, chickens, pigs and sheep stocks in {date}?"),
      subtitle = paste0("All values are reported in current US dollars"),
      caption = "Data: FAO (2021)"
    )
    sectors <- c("cattle", "chickens", "pigs", "sheep")
    data <- data %>%
      filter(item %in% sectors, year == date) %>%
      group_by(iso3, item) %>%
      summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
      mutate(item = stringr::str_to_title(item))
  } else {
    ttl <- list(
      title = glue::glue("<b> What is the global distribution of the total economic value of cattle, chickens, pigs and sheep in {date}?"),
      subtitle = paste0("All values  are reported in current US dollars"),
      caption = "Data: FAO (2021)"
    )
    sectors <- c("cattle", "chicken", "pig", "sheep")
    data <- data %>%
      filter(item %in% sectors, year == date) %>%
      group_by(iso3, item) %>%
      summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
      mutate(item = stringr::str_to_title(item)) %>%
      mutate(
        item = case_when(
          str_detect(item, "Cattle") ~ "Cattle",
          str_detect(item, "Chicken") ~ "Chickens",
          str_detect(item, "Pig") ~ "Pigs",
          str_detect(item, "Sheep") ~ "Sheep"
        ))
  }



  mappers <- calc_quintiles(data)

  data$value_bin <- cut(data$value,
    c(
      0, unlist(mappers$values)[1:length(mappers$values) - 1],
      max(data$value)
    ),
    labels = names(mappers$values),
    include.lowest = TRUE,
    right = FALSE,
    ordered_result = TRUE
  )


  world_values <- left_join(world, data, by = c("iso3")) %>%
    select(item, value_bin, geometry) %>%
    drop_na(value_bin)


  p <- ggplot(data = world) +
    geom_sf(fill = "#808080", color = "#D5E4EB") +
    geom_sf(data = world_values, aes(fill = value_bin), color = "#D5E4EB") +
    coord_sf(ylim = c(-55, 78)) +
    scale_fill_manual(
      values = rev(mappers$colors)
    ) +
    facet_wrap(~item) +
    labs(
      title = ttl$title,
      subtitle = ttl$subtitle,
      fill = "USD ($)",
      caption = ttl$caption
    ) +
    theme(
      legend.position = "right",
      legend.text = element_text(size = 12, face = "italic"),
      legend.key = element_rect(linetype = 19),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      panel.border = element_blank(),
      panel.grid.major = element_blank(),
      axis.line.x = element_blank(),
      strip.text.x = element_text(vjust = 1),
      plot.subtitle = element_markdown(
        size = 15,
        hjust = 0,
        family = "Times"
      ),
      plot.title.position = "plot",
      plot.title = element_markdown(
        size = 20,
        face = "bold.italic",
        family = "Times"
      ),
      plot.caption = element_markdown(
        size = 15,
        face = "italic",
        hjust = 0
      )
    ) +
    guides(shape = guide_legend(override.aes = list(shape = 19)))


  ggsave(glue::glue("output/tar_figures/{type}/world_map_{type}_sector_{date}.png"),
    plot = p, width = 55, height = 26, units = "cm", device = "png"
  )
}

#------------------------------------------------------------------------
world_map_percap_plot_combined <- function(o1,as2, date, value_var) {
  # Function to plot and save basic world maps of values per capita  for each
  # Scenario
  require(tidyverse)
  require(rnaturalearth)
  require(rnaturalearthdata)
  require(ggthemes)

  theme_set(theme_economist())


  # World data
  world <- ne_countries(scale = "medium", returnclass = "sf") %>%
    rename(iso3 = iso_a3)

  # Population data
  pop_total <- get_world_bank_population_data(force = FALSE, total = TRUE) %>%
    rename(iso3 = iso3c, year = date, population = SP.POP.TOTL) %>%
    filter(year == date) %>%
    select(iso3,  population) %>%
    filter(iso3 %in% c(unique(o1$iso3), unique(as2$iso3)))


  # Summarise both O1 and AS2

  o1 <- o1 %>%
    rename(value = {{value_var}}) %>%
    filter(year == date) %>%
    group_by(iso3) %>%
    summarise(
      value = sum(value, na.rm = TRUE), .groups = 'drop'
    ) %>%
    mutate(scenario = 'What is the global distribution of the direct output value per capita?')

  as2 <- as2 %>%
    rename(value = {{value_var}}) %>%
    filter(year == date) %>%
    group_by(iso3) %>%
    summarise(
      value = sum(value, na.rm = TRUE), .groups = 'drop'
    ) %>%
    mutate(scenario = 'What is the global distribution of live animal value per capita?')



  # Rename data and join to population
  data <- bind_rows(o1, as2) %>%
    left_join(pop_total, by = c('iso3')) %>%
    mutate(value = if_else(population == 0, 0, value/population)) %>%
    select(iso3,scenario,  population, value) %>%
    drop_na(value)


  mappers <- calc_quintiles(data)

  data$value_bin <- cut(data$value,
                        c(
                          0, unlist(mappers$values)[1:length(mappers$values) - 1],
                          max(data$value)
                        ),
                        labels = names(mappers$values),
                        include.lowest = TRUE,
                        right = FALSE,
                        ordered_result = TRUE
  )


  world_values <- right_join(world, data, by = c("iso3")) %>%
    dplyr::select(scenario, value_bin, geometry) %>%
    tidyr::drop_na(value_bin)




  p <- ggplot(data = world) +
    geom_sf(fill = "#808080", color = "#D5E4EB") +
    geom_sf(data = world_values, aes(fill = value_bin), color = "#D5E4EB") +
    coord_sf(ylim = c(-55, 78)) +
    scale_fill_manual(
      values = rev(mappers$colors)
    ) +
    facet_wrap(~scenario, nrow = 2) +
    labs(
      title = "",
      subtitle = "",
      fill = "USD ($) per capita",
      caption = "Data: FAO (2021), World Bank (SP.POP.TOT)  (2021)"
    ) +
    theme(
      legend.position = c(0.1, 0.6),
      legend.justification = c('left'),
      legend.text = element_text(size = 11, face = "italic"),
      legend.key = element_rect(linetype = 19),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      panel.border = element_blank(),
      panel.grid.major = element_blank(),
      axis.line.x = element_blank(),
      strip.text.x = element_text(vjust = 1, size = 15, face = "bold.italic"),
      plot.subtitle = element_markdown(
        size = 10,
        hjust = 0,
        family = "Times"
      ),
      plot.title.position = "plot",
      plot.title = element_markdown(
        size = 15,
        face = "bold.italic",
        family = "Times"
      ),
      plot.caption = element_markdown(
        size = 10,
        face = "italic",
        hjust = 0
      )
    )




  ggsave(glue::glue("output/tar_figures/world_map_O1-AS2_per_capita_{date}.png"),
         plot = p, width = 36, height = 26, units = "cm", device = "png")

}
##------------------------------------------------------------------------

world_map_percap_plot <- function(data, date, value_var, type) {
    # Function to plot and save basic world maps of values per capita  for each
    # Scenario
    require(tidyverse)
    require(rnaturalearth)
    require(rnaturalearthdata)
    require(ggthemes)

    theme_set(theme_economist())


    if (!(type %in% c("O1", "AS2", "TEV"))) {
      stop(
        paste0(type, "not in c(O1, AS2, TEV)")
      )
    }
    # Set title subtitle and caption

    if (type == "O1") {
      ttl <- list(
        title = glue::glue("What effect does a countries rural population have on the value of their direct animal outputs? {date}"),
        subtitle = paste0(
          "This estimate includes livestock and aquatic  products",
          " such as meat, milk, eggs and fish.",
          "<br>  All values  are reported in current US dollars per capita."
        ),
        caption = "Data: FAO (2021), World Bank (SP.POP.TOTL,SP.RUR.TOTL.ZS) (2021)"
      )
    } else if (type == "AS2") {
      ttl <- list(
        title = glue::glue("What effect does a countries rural population have on the value of their animal stock? {date}"),
        subtitle = paste0(
          "This estimate includes cattle, chickens, pigs, sheep, pigs, camels, mules, and horses.",
          "<br> All values  are reported in current US dollars per capita."
        ),
        caption = "Data: FAO (2021), World Bank (SP.POP.TOTL,SP.RUR.TOTL.ZS) (2021)"
      )
    } else {
      ttl <- list(
        title = glue::glue("What effect does a countries rural population have on the total economic value of their livestock? {date}"),
        subtitle = paste0(
          "This estimate includes the value of animal stock, as well as the value of direct livestock outputs.",
          "<br> All values  are reported in current US dollars per capita."
        ),
        caption = "Data: FAO (2021), World Bank (SP.POP.TOTL,SP.RUR.TOTL.ZS)  (2021)"
      )
    }

    # World data
    world <- ne_countries(scale = "medium", returnclass = "sf") %>%
      rename(iso3 = iso_a3)

    # Population data
    pop_total <- get_world_bank_population_data(force = FALSE, total = TRUE) %>%
      rename(iso3 = iso3c, year = date, population = SP.POP.TOTL) %>%
      filter(year == date) %>%
      select(iso3,  population)


    pop_rural <- get_world_bank_population_data(force = FALSE, total = FALSE) %>%
      rename(iso3 = iso3c, year = date, rural_pct = SP.RUR.TOTL.ZS) %>%
      filter(year == date) %>%
      select(iso3,  rural_pct)


    pop_data <- dplyr::inner_join(pop_total, pop_rural, by = c('iso3')) %>%
      mutate(
        rural_population = rural_pct * population/100
      ) %>%
      pivot_longer(c(rural_population, population), names_to = 'pop_type', values_to = 'pop_value') %>%
      mutate(
        pop_type = factor(case_when(
          pop_type== 'population' ~ 'USD ($) per capita',
          pop_type == 'rural_population' ~ 'USD ($) per capita (Rural)'),
          levels = c('USD ($) per capita',  'USD ($) per capita (Rural)')
        )
      ) %>%
      drop_na(pop_value) %>%
      filter(iso3 %in% unique(data$iso3))


    # Rename data and join to population
    data <- data %>%
      rename(value = {{value_var}}) %>%
      filter(year == date) %>%
      group_by(iso3) %>%
      summarise(value = sum(value,  na.rm = TRUE), .groups = 'drop') %>%
      right_join(pop_data, by = c('iso3')) %>%
      mutate(value = if_else(pop_value == 0, 0, value/pop_value)) %>%
      select(iso3, pop_type, value) %>%
      drop_na(value)


    mappers <- calc_quintiles(data)

    data$value_bin <- cut(data$value,
                          c(
                            0, unlist(mappers$values)[1:length(mappers$values) - 1],
                            max(data$value)
                          ),
                          labels = names(mappers$values),
                          include.lowest = TRUE,
                          right = FALSE,
                          ordered_result = TRUE
    )


    world_values <- right_join(world, data, by = c("iso3")) %>%
      dplyr::select(pop_type, value_bin, geometry) %>%
      tidyr::drop_na(value_bin)




    p <- ggplot(data = world) +
      geom_sf(fill = "#808080", color = "#D5E4EB") +
      geom_sf(data = world_values, aes(fill = value_bin), color = "#D5E4EB") +
      coord_sf(ylim = c(-55, 78)) +
      scale_fill_manual(
        values = rev(mappers$colors)
      ) +
      facet_wrap(~pop_type, nrow = 2) +
      labs(
        title = ttl$title,
        subtitle = ttl$subtitle,
        fill = "",
        caption = ttl$caption
      ) +
      theme(
        legend.position = c(0.1, 0.6),
        legend.justification = c('left'),
        legend.text = element_text(size = 11, face = "italic"),
        legend.key = element_rect(linetype = 19),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        panel.border = element_blank(),
        panel.grid.major = element_blank(),
        axis.line.x = element_blank(),
        strip.text.x = element_text(vjust = 1, size = 11, face = "italic"),
        plot.subtitle = element_markdown(
          size = 10,
          hjust = 0,
          family = "Times"
        ),
        plot.title.position = "plot",
        plot.title = element_markdown(
          size = 15,
          face = "bold.italic",
          family = "Times"
        ),
        plot.caption = element_markdown(
          size = 10,
          face = "italic",
          hjust = 0
        )
      ) +
      guides(shape = guide_legend(override.aes = list(shape = 19)))


    ggsave(glue::glue("output/tar_figures/{type}/world_map_{type}_per_capita_{date}.png"),
           plot = p, width = 36, height = 26, units = "cm", device = "png")

}




#------------------------------------------------------------------------
calc_quintiles <- function(data) {
  options(scipen = 999)
  quintiles <- quantile(data$value, probs = seq(0.5, 0.95, 0.15))
  rounded_quintiles <- dplyr::case_when(
    quintiles < 20 ~ plyr::round_any(quintiles, 5, ceiling),
    quintiles < 100 ~ plyr::round_any(quintiles, 10,ceiling),
    quintiles < 1000 ~ plyr::round_any(quintiles, 100,ceiling),
    quintiles < 10000 ~ plyr::round_any(quintiles, 1000,ceiling),
    quintiles < 1e5~ plyr::round_any(quintiles, 1e5,ceiling),
    quintiles < 1e6 ~ plyr::round_any(quintiles, 1e6, ceiling),
    quintiles < 10e6 ~ plyr::round_any(quintiles, 5e6, ceiling),
    quintiles < 100e6 ~ plyr::round_any(quintiles, 10e6, ceiling),
    quintiles < 500e6 ~ plyr::round_any(quintiles, 50e6, ceiling),
    quintiles < 1e9 ~ plyr::round_any(quintiles, 100e6, ceiling),
    quintiles < 10e9 ~ plyr::round_any(quintiles, 5e9, ceiling),
    quintiles < 50e9 ~ plyr::round_any(quintiles, 10e9, ceiling),
    quintiles < 100e9 ~ plyr::round_any(quintiles, 20e9, ceiling),
    quintiles >= 100e9 ~ plyr::round_any(quintiles, 100e9, ceiling)
  )

  # If any of the quintiles are the same only take the uniqe ones
  uniq_quintiles <- unique(rounded_quintiles)

  # Get values
  value_names <- character(length(uniq_quintiles))
  for (i in seq_along(value_names)) {
    if (i == 1) {
      value_names[i] <- paste0("<", round_func(uniq_quintiles[i]))
    } else {
      value_names[i] <- paste0(
        round_func(uniq_quintiles[i - 1]),
        "-", round_func(uniq_quintiles[i])
      )
    }
  }
  value_names <- append(value_names, paste0(
    ">",
    round_func(tail(uniq_quintiles, 1))
  ))


  value_map <- setNames(as.list(c(
    uniq_quintiles,
    tail(uniq_quintiles, 1)
  )), value_names)

  # Return names and colors
  color_map <- setNames(
    as.list(c(
      "#808080",
      RColorBrewer::brewer.pal(
        length(value_names),
        "YlGnBu"
      )
    )),
    c("NA", value_names)
  )

  return(list(values = value_map, colors = color_map))
}

round_func <- function(val) {
  if (val > 1e9) {
    return(paste0(val * (1e-9), "B"))
  } else if (val > 1e6) {
    return(paste0(val * (1e-6), "M"))
  } else {
    return(paste0(val))
  }
}
