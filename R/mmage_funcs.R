#!/usr/bin/env Rscript
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
# Date Created:  20220203
#
# Description:  This file contains helper functions
# to wor with the mmage to generate estimates of
# the herd structure and hence biomass of livestock.
#
# Because there is not information on herd structure,
# this will be run without initial age structures.

# Citation:
# Matthieu Lesnoff (2021). mmage: A R package for sex-and-age population matrix models. R
# package version 2.4-3.
####################################
library(pointblank)
library(purrr)
library(tibble)
library(dplyr)
library(mmage)


##  - Create Schema table for DynamodDataFrame ------------------------------#

#' get_dynamod_schema
#'
#' Returns the pointblank schema required to validate the
#' dataframe columns which are passed into dynamod.
#'
#' @return a pointblack database schema
get_dynamod_schema <- function() {
  dynamod_schema <- pointblank::col_schema(
    iso3 = "character",
    population = "integer",
    carcass_pct = "numeric",
    prob_female = "numeric",
    parturation = "numeric",
    prolificacy = "numeric",
    male_juvenile_mortality = "numeric",
    female_juvenile_mortality = "numeric",
    male_sub_mortality = "numeric",
    female_sub_mortality = "numeric",
    male_adult_mortality = "numeric",
    female_adult_mortality = "numeric",
    male_juvenile_offtake = "numeric",
    female_juvenile_offtake = "numeric",
    male_sub_offtake = "numeric",
    female_sub_offtake = "numeric",
    male_adult_offtake = "numeric",
    female_adult_offtake = "numeric",
    male_juvenile_lbw = "numeric",
    female_juvenile_lbw = "numeric",
    male_sub_lbw = "numeric",
    female_sub_lbw = "numeric",
    male_adult_lbw = "numeric",
    female_adult_lbw = "numeric",
    .db_col_types = "r"
  )
}

##  - Validate dataframe schema------------------------------#
#' validate_dynamod_schema
#'
#' Validates if the data frame passed into the dynamod functions
#' has the appropriate schema.
#'
#' @param df
#' @param .schema
#'
#' @return logical determining if the dataframe conforms
validate_dynamod_schema <- function(df, .schema = get_dynamod_schema()) {
  return(df %>% pointblank::has_columns(names(.schema)))
}

##  - Validate  if the dataframe passed in has correct values -----------------#

#' validate_dynamod_df_values
#'
#' @param df data frame to be run in dynamod
validate_dynamod_df_values <- function(df) {
  # Test if rates have been passed in correctly
  df %>%
    col_vals_between(
      columns = contains("offtake|mortality|prob_female|parturation|carcass_pct"),
      left = 0, right = 1
    )
}

##  - Creates age structure matrix ------------------------------#

#' Title
#'
#' @param ...
#'
#' @return default age structure matrix
#'
get_tcla <- function(...) {
  age_structure <- c(11, 24, 144, 1)
  return(as_tibble(
    mmage::fclass(
      age_structure,
      age_structure
    )
  ))
}


##  - Run Dynamod on the conforming dataframe ------------------------------#

#' Runs dynamod truncated projection model
#'
#' @param df data frame containing dynamod parameters
#' @param num_phases number of phases within a dynamod cycle defaults to 12
#' @param num_cycles number of cycles to run the projections for defaults to 1
#'
run_dynamod_projection <- function(df, num_phases = 12, num_cycles = 1) {

    library(mmage)

  # Ensure Data is a tibble
  df <- as_tibble(df)

  # Validate the data which is being passed in
  if ((num_phases <= 1) | (num_cycles <= 0)) {
    stop("num_phases and num_cycles must be positive")
  }
  if (!validate_dynamod_schema(df)) {
    stop("Dataframe has incorrect column schema to run dynamod.")
  }

  # if (!validate_dynamod_df_values(df)) {
  #   stop("Dataframe has incorrect column values to run dynamod.")
  # }

  df$tcla <- purrr::pmap(df, get_tcla)
  df$params <- purrr::pmap(df, get_param)
  df$proj <- purrr::pmap(df, run_projection)
  df$results <- purrr::pmap(df, get_results)
  return(df$results)
}


#' get_param
#'
#' @param ... list of parameters
#' @param num_phases
#'
#' @examples
get_param <- function(..., num_phases = 12) {
  x <- list(...)
  param <- list()
  param$hpar <- c(rep(0, 2), x$parturation, x$parturation, rep(0, 4)) / num_phases
  netpro <- c(rep(0, 2), x$prolificacy, x$prolificacy, rep(0, 4))
  pfbirth <- c(rep(0, 2), x$prob_female, x$prob_female, rep(0, 4))
  param$hfecf <- x$prob_female * netpro * param$hpar
  param$hfecm <- (1 - x$prob_female) * netpro * param$hpar
  param$hdea <- c(
    x$female_juvenile_mortality,
    x$female_sub_mortality,
    x$female_adult_mortality,
    0,
    x$male_juvenile_mortality,
    x$male_sub_mortality,
    x$male_adult_mortality,
    0
  ) / num_phases
  param$hoff <- c(
    x$female_juvenile_offtake,
    x$female_sub_offtake,
    x$female_adult_offtake,
    1, # Culling
    x$male_juvenile_offtake,
    x$male_sub_offtake,
    x$male_adult_offtake,
    1
  ) / num_phases

  hh <- bind_cols(x$tcla[x$tcla$class > 0, 1:3], data.frame(param))
  vh <- mmage::fhh2vh(hh)
  params <- mmage::fvh2par(vh, terminal = "off")
  return(params)
}

##  - Runs the dynamod projection ------------------------------#
run_projection <- function(..., num_phases = 12, num_cycles = 1) {
  dfx <- list(...)
  tryCatch({
      length_male <- length_female <- 4 # Change this
      mat <- mmage::fmat(dfx$params, length_female, length_male)
      res <- feig(mat$A, left = TRUE)
      tabini <- dfx$tcla[dfx$tcla$class > 0, ]
      tabini$x <- res$v * dfx$population
      num_steps <- num_cycles * num_phases
      listpar <- rep(list(dfx$params), num_steps)
      proj <- fproj(listpar, tabini$x, num_cycles, num_phases)
      return(proj)
    },
    error = function(e) {
      return(list())
    }
  )
}

get_results <- function(...) {
  x <- list(...)
  if (length(x$proj) > 0) {
    vecx <- x$proj$vecx
    vecprod <- x$proj$vecprod
    final_population <- sum(vecx$x[vecx$cycle == 2])
    average_population <- ((vecx$x[(vecx$cycle == 1) & (vecx$phase == 1)] + vecx$x[vecx$cycle == 2]) / 2)
    total_offtake <- sum(vecprod$off)
    total_mortality <- sum(vecprod$dea)
    total_born <- sum(vecprod$b)
    average_live_weight <- sum(average_population * c(
      x$female_juvenile_lbw, x$female_sub_lbw, x$female_adult_lbw, x$female_adult_lbw,
      x$male_juvenile_lbw, x$male_sub_lbw, x$male_adult_lbw, x$male_adult_lbw
    ))
    average_carcass_weight <- average_live_weight * x$carcass_pct
    female_juvenile_avg_population <- average_population[1]
    female_sub_avg_population <- average_population[2]
    female_adult_avg_population <- sum(average_population[3:4])
    male_juvenile_avg_population <- sum(average_population[5])
    male_sub_avg_population <- sum(average_population[6])
    male_adult_avg_population <- sum(average_population[7:8])
    total_female_population_avg <- female_adult_avg_population + female_juvenile_avg_population + female_sub_avg_population
    total_male_population_avg <- male_adult_avg_population + male_juvenile_avg_population + male_sub_avg_population
    return(
      tibble::tibble(
        iso3 = x$iso3,
        system = x$System,
        total_born,
        total_mortality,
        total_offtake,
        average_live_weight,
        average_carcass_weight,
        female_juvenile_avg_population,
        female_sub_avg_population,
        female_adult_avg_population,
        male_juvenile_avg_population,
        male_sub_avg_population,
        male_adult_avg_population,
        total_female_population_avg,
        total_male_population_avg,
        initial_population  = x$population,
        final_population
      )
    )
  } else {
    return(tibble())
  }
}


if (interactive()) {
  # Create dummy test file
  test <- tibble::tibble(
    iso3 = "character",
    population = 100,
    carcass_pct = 0.5,
    prob_female = 0.5,
    parturation = 0.1,
    prolificacy = 1,
    male_juvenile_mortality = 0.01,
    female_juvenile_mortality = 0.1,
    male_sub_mortality = 0.01,
    female_sub_mortality = 0.3,
    male_adult_mortality = 0.2,
    female_adult_mortality = 0.1,
    male_juvenile_offtake = 0.3,
    female_juvenile_offtake = 0.01,
    male_sub_offtake = 0.01,
    female_sub_offtake = 0.01,
    male_adult_offtake = 0.04,
    female_adult_offtake = 0.04,
    male_juvenile_lbw = 20,
    female_juvenile_lbw = 20,
    male_sub_lbw = 50,
    female_sub_lbw = 50,
    male_adult_lbw = 250,
    female_adult_lbw = 250
  )

  test_result <- run_dynamod_projection(test)
}
