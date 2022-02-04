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
# to work with the mmage to generate estimates of
# the herd structure and hence biomass of livestock
#
# Citation:
# Matthieu Lesnoff (2021). mmage: A R package for sex-and-age population matrix models. R
# package version 2.4-3.
####################################



#' Runs dynamod truncated projection model
#'
#' @param df data frame containing dynamod parameters
#' @param num_phases number of phases within a dynamod cycle defaults to 12
#' @param num_cycles number of cycles to run the projections for defaults to 1
#'
# TODO: Add config file to make sure parameters are correct
run_dynamod_projection <- function(df, num_phases = 12, num_cycles = 1) {
  df$ProbFemale <- ifelse(df$ProbFemale <= 1, df$ProbFemale, df$ProbFemale / 100)

  # Ensure Data is a tibble
  df <- as_tibble(df)
  get_tcla <- function(...) {
    x <- list(...)
    female_lengths <- c(
      x$femaleJuvenileAge,
      x$femaleSubAdultAge,
      x$femaleAdultCullAge
    )
    male_lengths <- c(
      x$maleJuvenileAge,
      x$maleSubAdultAge,
      x$maleAdultCullAge
    )
    if (all(female_lengths == sort(female_lengths)) & all(male_lengths == sort(male_lengths))) {
      return(
        as_tibble(
          mmage::fclass(
            c(female_lengths, 1),
            c(male_lengths, 1)
          )
        )
      )
    } else {
      return(as_tibble(
        mmage::fclass(
          c(11, 24, 144, 1),
          c(11, 24, 144, 1)
        )
      ))
    }
  }


  #################################################################
  # Create Herd Rates and Parameter vectors
  #################################################################
  get_param <- function(..., num_phases = 12) {
    x <- list(...)
    param <- list()
    param$hpar <- c(rep(0, 2), x$parturation, x$parturation, rep(0, 4)) / num_phases
    netpro <- c(rep(0, 2), x$prolificacy, x$prolificacy, rep(0, 4))
    pfbirth <- c(rep(0, 2), x$ProbFemale, x$ProbFemale, rep(0, 4))
    param$hfecf <- x$ProbFemale * netpro * param$hpar
    param$hfecm <- (1 - x$ProbFemale) * netpro * param$hpar
    param$hdea <- c(
      x$femaleJuvenileMortality,
      x$femaleSubAdultMortality,
      x$femaleAdultMortality,
      0,
      x$maleJuvenileMortality,
      x$maleSubAdultMortality,
      x$maleAdultMortality,
      0
    ) / num_phases
    param$hoff <- c(
      x$femaleJuvenileOfftake,
      x$femaleSubAdultOfftake,
      x$femaleAdultOfftake,
      1, # Culling
      x$maleJuvenileOfftake,
      x$maleSubAdultOfftake,
      x$maleAdultOfftake,
      1
    ) / num_phases

    hh <- bind_cols(x$tcla[x$tcla$class > 0, 1:3], data.frame(param))
    vh <- mmage::fhh2vh(hh)
    params <- mmage::fvh2par(vh, terminal = "off")
    return(params)
  }

  #################################################################
  # Run the projection and output results
  #################################################################
  run_projection <- function(..., num_phases = 12, num_cycles = 1) {
    dfx <- list(...)
    tryCatch(
      {
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
        x$femaleJuvenileLBW, x$femaleSubAdultLBW, x$femaleAdultLBW, x$femaleAdultLBW,
        x$maleJuvenileLBW, x$maleSubAdultLBW, x$maleAdultLBW, x$maleAdultLBW
      ))
      average_carcass_weight <- average_live_weight * x$carcassYield
      femaleJuvenileAvgPopulation <- average_population[1]
      femaleSubAdultAvgPopulation <- average_population[2]
      femaleAdultAvgPopulation <- sum(average_population[3:4])
      maleJuvenileAvgPopulation <- sum(average_population[5])
      maleSubAdultAvgPopulation <- sum(average_population[6])
      maleAdultAvgPopulation <- sum(average_population[7:8])
      total_female_population_avg <- femaleAdultAvgPopulation + femaleJuvenileAvgPopulation + femaleSubAdultAvgPopulation
      total_male_population_avg <- maleAdultAvgPopulation + maleJuvenileAvgPopulation + maleSubAdultAvgPopulation

      return(
        tibble(
          iso3 = x$iso3,
          system = x$System,
          total_born,
          total_mortality,
          total_offtake,
          average_live_weight,
          average_carcass_weight,
          femaleJuvenileAvgPopulation,
          femaleSubAdultAvgPopulation,
          femaleAdultAvgPopulation,
          maleJuvenileAvgPopulation,
          maleSubAdultAvgPopulation,
          maleAdultAvgPopulation,
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

  df$tcla <- purrr::pmap(df, get_tcla)
  df$params <- purrr::pmap(df, get_param)
  df$proj <- purrr::pmap(df, run_projection)
  df$results <- purrr::pmap(df, get_results)
  return(df$results)
}
