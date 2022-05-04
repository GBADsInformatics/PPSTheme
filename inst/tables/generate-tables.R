#! /usr/bin/Rscript --vanilla


# Description -------------------------------------------------------------
# Generates different tables for the
# livestock value manuscript




# Configuration -----------------------------------------------------------

config <- config::get(file = here::here("conf", "config.yml"))

library(dplyr)


# Create Excell Files of Tables -------------------------------------------

# Livestock
livestock <- config$data$output$livestock_values |>
  arrow::read_parquet() |>
  dplyr::filter(year %in% 2006:2018)

# Aquaculture
aquaculture <- config$data$output$aquaculture_values |>
  arrow::read_parquet() |>
  dplyr::filter(year %in% 2006:2018)

# Crops
crops <- config$data$output$crop_values |>
  arrow::read_parquet() |>
  dplyr::filter(year %in% 2006:2018)



# Total Values ------------------------------------------------------------
library(openxlsx)

livestock_total <- livestock |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    asset = sum(ifelse(item == "stock", stock_value_constant_2014_2016_usd, 0), na.rm = TRUE),
    output = sum(ifelse(item != "stock", gross_production_value_constant_2014_2016_thousand_us, 0), na.rm = TRUE) * 1e3,
    livestock_tonnes = sum(ifelse(item != "stock", tonnes, 0), na.rm = TRUE)
  ) |>
  dplyr::mutate(
    livestock = asset + output
  ) |>
  dplyr::select(-asset, -output) |>
  dplyr::select(year, livestock, livestock_tonnes)

aquaculture_total <- aquaculture |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    aquaculture = sum(constant_2014_2016_usd_value, na.rm = TRUE),
    aquaculture_tonnes = sum(tonnes, na.rm = TRUE)
  )

crop_total <- crops |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    crops = sum(gross_production_value_constant_2014_2016_thousand_us, na.rm = TRUE) * 1e3,
    crops_tonnes = sum(tonnes, na.rm = TRUE)
  )

total_table <- purrr::reduce((list(crop_total, livestock_total, aquaculture_total)), full_join) |>
  arrange(desc(year)) |>
  dplyr::mutate_at(vars(contains("tonnes")), ~ scales::comma(.x, scale = 1e-6, suffix = "M", accuracy = 1)) |>
  dplyr::mutate_at(vars(-contains("tonnes"), -year), ~ scales::dollar(.x, scale = 1e-9, suffix = "B", accuracy = 1))

names(total_table) <- c(
  "Year", "Crops Value (USD ($))", "Crop Quantities (Tonnes)",
  "Livestock Value (USD ($))",
  "Livestock Quantities (Tonnes)",
  "Aquaculture Value (USD ($))",
  "Aquaculture Quantities (Tonnes)"
)

wb <- createWorkbook(creator = "Gabriel Dennis")
addWorksheet(wb, sheetName = "TotalValueAndQuantity")
writeData(wb,
  "TotalValueAndQuantity",
  "Note: All values are in constant 2014-2016 US Dollars",
  startCol = 1, startRow = 1
)

writeData(wb,
  "TotalValueAndQuantity",
  total_table,
  startCol = 1, startRow = 3
)
saveWorkbook(wb, here::here("output", "tables", "table_appendix_tev_crops_livestock_aquaculture_2006-2018.xlsx"),
  overwrite = TRUE
)


# Total Values with Aquaculture ---------------------------------------------------------------

livestock_total <- livestock |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    livestock_asset = sum(ifelse(item == "stock", stock_value_constant_2014_2016_usd, 0), na.rm = TRUE),
    livestock_output = sum(ifelse(item != "stock", gross_production_value_constant_2014_2016_thousand_us, 0), na.rm = TRUE) * 1e3,
    livestock_tonnes = sum(ifelse(item != "stock", tonnes, 0), na.rm = TRUE)
  )

aquaculture_total <- aquaculture |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    aquaculture_asset = NA,
    aquaculture_output = sum(constant_2014_2016_usd_value, na.rm = TRUE),
    aquaculture_tonnes = sum(tonnes, na.rm = TRUE)
  )


total_table <- purrr::reduce((list(livestock_total, aquaculture_total)), full_join) |>
  arrange(desc(year)) |>
  dplyr::mutate_at(vars(contains("tonnes")), ~ scales::comma(.x, scale = 1e-6, suffix = "M", accuracy = 1)) |>
  dplyr::mutate_at(vars(-contains("tonnes"), -year), ~ scales::dollar(.x, scale = 1e-9, suffix = "B", accuracy = 1))

names(total_table) <- c(
  "Year",
  "Livestock Asset Value (USD ($))",
  "Livestock Output Value (USD ($))",
  "Livestock Quantities (Tonnes)",
  "Aquaculture Asset Value (USD ($))",
  "Aquaculture Output Value (USD ($))",
  "Aquaculture Quantities (Tonnes)"
)

wb <- createWorkbook(creator = "Gabriel Dennis")
addWorksheet(wb, sheetName = "AssetAndOutput")
writeData(wb,
  "AssetAndOutput",
  "Note: All values are in constant 2014-2016 US Dollars",
  startCol = 1, startRow = 1
)

writeData(wb,
  "AssetAndOutput",
  total_table,
  startCol = 1, startRow = 3
)

saveWorkbook(wb, here::here("output", "tables", "table_appendix_asset_output_livestock_aquaculture_2006-2018.xlsx"),
  overwrite = TRUE
)



# Selected Countries ------------------------------------------------------

high_impact_countries <- c("BRA", "CHN", "IND", "USA")

livestock_selected <- livestock |>
  dplyr::filter(iso3_code %in% high_impact_countries) |>
  dplyr::group_by(year, iso3_code) |>
  dplyr::summarise(
    asset = sum(stock_value_constant_2014_2016_usd, na.rm = TRUE),
    output = sum(gross_production_value_constant_2014_2016_thousand_us, na.rm = TRUE) * 1e3,
    tonnes = sum(tonnes, na.rm = TRUE)
  )

livestock_total <- livestock |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    total_asset = sum(stock_value_constant_2014_2016_usd, na.rm = TRUE),
    total_output = sum(gross_production_value_constant_2014_2016_thousand_us, na.rm = TRUE) * 1e3,
    livestock_tonnes = sum(tonnes, na.rm = TRUE)
  )

table_df <- livestock_selected |>
  left_join(livestock_total) |>
  dplyr::mutate(
    `Asset Value (USD ($))` = sprintf(
      "%s (%s)", scales::dollar(asset, scale = 1e-9, suffix = "B"),
      scales::percent(asset / total_asset, accuracy = 1)
    ),
    `Output Value (USD ($))` = sprintf(
      "%s (%s)", scales::dollar(output, scale = 1e-9, suffix = "B"),
      scales::percent(output / total_output, accuracy = 1)
    ),
    Tonnes = sprintf(
      "%s (%s)", scales::dollar(tonnes, scale = 1e-6, suffix = "M"),
      scales::percent(tonnes / livestock_tonnes, accuracy = 1)
    )
  ) |>
  select(year, iso3_code, `Asset Value (USD ($))`, `Output Value (USD ($))`, Tonnes) |>
  mutate(
    Country = case_when(
      iso3_code == "BRA" ~ "Brazil",
      iso3_code == "CHN" ~ "China",
      iso3_code == "IND" ~ "India",
      iso3_code == "USA" ~ "USA"
    )
  ) |>
  tidyr::pivot_wider(
    id_cols = year, names_from = Country, names_glue = "{Country} {.value}",
    values_from = c(`Asset Value (USD ($))`, `Output Value (USD ($))`, Tonnes),
    names_sort = TRUE
  ) |>
  arrange(desc(year)) %>%
  select("year", sort(colnames(.)[2:length(colnames(.))], decreasing = F))




wb <- createWorkbook(creator = "Gabriel Dennis")
addWorksheet(wb, sheetName = "SelectedCounties")
writeData(wb,
  "SelectedCounties",
  "Note: All values are in constant 2014-2016 US Dollars",
  startCol = 1, startRow = 1
)

writeData(wb,
  "SelectedCounties",
  table_df,
  startCol = 1, startRow = 3
)
saveWorkbook(wb, here::here("output", "tables", "table_appendix_bra_chn_ind_usa_2006-2018.xlsx"),
  overwrite = TRUE
)
