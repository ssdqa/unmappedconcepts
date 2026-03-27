
#' Compute unmapped concept distributions & per patient medians
#'
#' @param cohort table of cohort members with at least `site`, `person_id`, `start_date`, and `end_date`
#' @param uc_tbl A table with information about each of the variables that should be examined
#'   in the analysis. This table should contain the following columns:
#'   - `variable` | *character* | a string label for the variable being evaluated for unmapped values
#'   - `domain_tbl` | *character* | the CDM table where the variable is found
#'   - `unmapped_field` | *character* | the name of the field where unmapped values should be identified
#'   - `unmapped_values` | *character* | a string or vector with each value that should be considered as "unmapped"
#'   - `concept_field` | *character* | the string name of the field in the domain table where the concepts are located (if codeset is provided)
#'   - `date_field` | *character* | the name of the field in the domain table with the date that should be used for temporal filtering
#'   - `vocabulary_field` | *character* | for PCORnet applications, the name of the field in the domain table with a vocabulary identifier to differentiate concepts from one another (ex: dx_type); can be set to NA for OMOP applications
#'   - `codeset_name` | *character* | (optional) the name of the codeset that can be used to define a variable of interest (ex: evaluate unit completeness for a specific drug)
#'   - `filter_logic` | *character* | (optional) logic to be applied to the domain_tbl in order to achieve the definition of interest; should be written as if you were applying it in a dplyr::filter command in R
#' @param site_col the name of the column with site information (either site or site_summ)
#' @param grouped_list list of columns that should be used to group the analysis tables
#' @param time boolean indicating whether the analysis is being executed over time
#' @param omop_or_pcornet string indicating the data model of the underlying CDM data (either omop or pcornet)
#'
#' @importFrom purrr set_names
#' @importFrom purrr reduce
#' @importFrom rlang parse_expr
#' @importFrom stringr str_replace_all
#' @importFrom stringr str_split
#' @importFrom stats median
#' @importFrom tidyr pivot_wider
#' @importFrom tidyr pivot_longer
#'
#' @keywords internal
#'
compute_uc <- function(cohort,
                       uc_tbl,
                       site_col = 'site',
                       grouped_list = 'site',
                       time = FALSE,
                       omop_or_pcornet = 'omop'){

  uc_list <- split(uc_tbl, seq(nrow(uc_tbl)))

  check_concepts <- list()
  pt_concepts <- list()

  for(i in 1:length(uc_list)) {

    varb <- uc_list[[i]]$variable

    cli::cli_inform(paste0('Starting ', varb))

    if(omop_or_pcornet == 'omop'){
      join_cols <- purrr::set_names('concept_id', uc_list[[i]]$concept_field)
      person_col <- 'person_id'
    }else{
      join_cols <- purrr::set_names('concept_code', uc_list[[i]]$concept_field)

      if(!is.na(uc_list[[i]]$vocabulary_field)){
        join_cols2 <- purrr::set_names('vocabulary_id', uc_list[[i]]$vocabulary_field)
        join_cols <- join_cols %>% append(join_cols2)
      }

      person_col <- 'patid'
    }

    domain_tbl <- cdm_tbl(uc_list[[i]]$domain_tbl) %>%
      inner_join(cohort) %>%
      filter(!!sym(uc_list[[i]]$date_field) >= start_date &
               !!sym(uc_list[[i]]$date_field) <= end_date) %>%
      group_by(!!!syms(grouped_list))

    if(time){
      domain_tbl <- domain_tbl %>%
        filter(!!sym(uc_list[[i]]$date_field) >= time_start &
                 !!sym(uc_list[[i]]$date_field) <= time_end) %>%
        group_by(time_start, time_increment, .add = TRUE)
    }

    if(!is.na(uc_list[[i]]$filter_logic)){
      tbl_use <- domain_tbl %>%
        filter(!! rlang::parse_expr(uc_list[[i]]$filter_logic))
    }else{tbl_use <- domain_tbl}

    if(!is.na(uc_list[[i]]$codeset_name)){
      tbl_use <- tbl_use %>%
        inner_join(load_codeset(uc_list[[i]]$codeset_name), by = join_cols)
    }else{tbl_use <- tbl_use}

    ## unmapped info
    colname <- uc_list[[i]]$unmapped_field
    vals <- uc_list[[i]]$unmapped_values %>%
      stringr::str_replace_all(' ', '') %>%
      stringr::str_split(., ',')
    vals <- vals[[1]]

    if(length(vals) == 1){
      if(is.na(vals)){
        unmapped_vals <-
          tbl_use %>%
          filter(is.na(!!sym(colname)))

        per_pt <- tbl_use %>%
          mutate(tag = ifelse(is.na(!!sym(colname)),
                              'unmapped',
                              'mapped')) %>%
          group_by(!!sym(person_col), tag, .add = TRUE) %>%
          summarise(unmapped_pp = n()) %>%
          tidyr::pivot_wider(names_from = 'tag',
                             values_from = 'unmapped_pp') %>%
          collect()
      }else{
        unmapped_vals <-
          tbl_use %>%
          filter(!!sym(colname) %in% vals | is.na(!!sym(colname)))

        per_pt <- tbl_use %>%
          mutate(tag = ifelse(as.character(!!sym(colname)) %in% vals | is.na(!!sym(colname)),
                              'unmapped',
                              'mapped')) %>%
          group_by(!!sym(person_col), tag, .add = TRUE) %>%
          summarise(unmapped_pp = n()) %>%
          tidyr::pivot_wider(names_from = 'tag',
                             values_from = 'unmapped_pp') %>%
          collect()
      }
    }else{
      unmapped_vals <-
        tbl_use %>%
        filter(!!sym(colname) %in% vals | is.na(!!sym(colname)))

      per_pt <- tbl_use %>%
        mutate(tag = ifelse(as.character(!!sym(colname)) %in% vals | is.na(!!sym(colname)),
                            'unmapped',
                            'mapped')) %>%
        group_by(!!sym(person_col), tag, .add = TRUE) %>%
        summarise(unmapped_pp = n()) %>%
        tidyr::pivot_wider(names_from = 'tag',
                           values_from = 'unmapped_pp') %>%
        collect()
    }

    ## proportion
    total_pts <- cohort %>%
      summarise(total_pt = n_distinct(person_id),
                variable = varb) %>%
      collect()

    total_rows <- tbl_use %>%
      summarise(
        variable = varb,
        total_rows = n()
      ) %>% collect()

    total_unmapped <-
      unmapped_vals %>%
      summarise(
        unmapped_rows = n(),
        unmapped_pt = n_distinct(!!sym(person_col)),
        variable = varb
      ) %>% collect()

    if(nrow(total_unmapped) < 1){
      total_unmapped <-
        dplyr::tibble(
          unmapped_rows = 0L,
          unmapped_pt = 0L,
          variable = varb
        )
    }

    ## per patient
    if('unmapped' %in% colnames(per_pt)){
      per_pt <- per_pt %>%
        mutate(unmapped = ifelse(is.na(unmapped), 0L, unmapped)) %>%
        select(-mapped)
    }else{
      per_pt <- per_pt %>% mutate(unmapped = 0L) %>% select(-mapped)
    }

    site_meds <- per_pt %>%
      ungroup(!!sym(person_col)) %>%
      summarise(median_site_with0s = as.numeric(median(unmapped)),
                median_site_without0s = as.numeric(median(unmapped[unmapped!=0])),
                variable = varb) %>%
      mutate(median_site_without0s = ifelse(is.na(median_site_without0s),
                                            0L, median_site_without0s))

    all_meds <- per_pt %>%
      ungroup(!!sym(person_col), !!sym(site_col)) %>%
      summarise(median_all_with0s = as.numeric(median(unmapped)),
                median_all_without0s = as.numeric(median(unmapped[unmapped!=0])),
                variable = varb) %>%
      mutate(median_all_without0s = ifelse(is.na(median_all_without0s),
                                           0L, median_all_without0s))

    ## combined
    unmapped_cts <-
      total_rows %>%
      left_join(total_pts) %>%
      left_join(total_unmapped) %>%
      left_join(all_meds) %>%
      left_join(site_meds) %>%
      mutate(
        unmapped_rows = ifelse(is.na(unmapped_rows), 0, unmapped_rows),
        unmapped_pt = ifelse(is.na(unmapped_pt), 0, unmapped_pt),
        unmapped_row_prop = round(as.numeric(unmapped_rows) / as.numeric(total_rows), 2),
        unmapped_row_prop = ifelse(is.na(unmapped_row_prop), 0, unmapped_row_prop),
        unmapped_pt_prop = round(as.numeric(unmapped_pt) / as.numeric(total_pt), 2),
        unmapped_pt_prop = ifelse(is.na(unmapped_pt_prop), 0, unmapped_pt_prop)
      )

    check_concepts[[i]] <- unmapped_cts
    pt_concepts[[i]] <- per_pt %>% mutate(variable = varb)

  }

  check_concepts_red <- purrr::reduce(.x = check_concepts,
                                      .f = dplyr::union)
  pt_concepts_red <- purrr::reduce(.x = pt_concepts,
                                   .f = dplyr::union)

  opt <- list('summary' = check_concepts_red,
              'pt_lv' = pt_concepts_red)

  return(opt)
}




#' Single Site Anomaly Detection method for UC
#'
#' @param cohort table of cohort members with at least `site`, `person_id`, `start_date`, and `end_date`
#' @param uc_ptlv_rslt patient level results output by `uc_process`
#' @param n_sd numeric indicating the number of standard deviations away from the mean that will indicate an outlier (defaults to 2)
#'
#' @keywords internal
#'
compute_uc_ssanom <- function(cohort,
                              uc_ptlv_rslt,
                              n_sd = 2){

    n_tot <- cohort %>%
      summarise(ct = n()) %>%
      collect() %>% pull(ct)

    all_vals <- uc_ptlv_rslt %>%
      group_by(site, variable) %>%
      summarise(mean_tot=mean(unmapped),
                sd_tot=sd(unmapped),
                n_tot=n_tot)

    all_vals <- uc_ptlv_rslt %>%
      left_join(all_vals) %>%
      mutate(zscore_tot = ((unmapped - mean_tot) / sd_tot),
             abs_z = abs(zscore_tot),
             outlier = case_when(zscore_tot > n_sd ~ 1L,
                                 TRUE ~ 0L)) %>%
      group_by(site, variable, n_tot, sd_tot, mean_tot) %>%
      mutate(outlier_tot = sum(outlier),
             prop_outlier_tot = round(outlier_tot / n_tot, 3)) %>%
      select(group_vars(.), n_tot, outlier_tot, mean_tot, sd_tot, prop_outlier_tot) %>%
      ungroup() %>% distinct()

    fact_vals <- uc_ptlv_rslt %>%
      filter(unmapped != 0) %>%
      group_by(site, variable) %>%
      summarise(mean_fact=mean(unmapped),
                sd_fact=sd(unmapped),
                n_w_fact=n())

    fact_vals <- uc_ptlv_rslt %>%
      filter(unmapped != 0) %>%
      left_join(fact_vals) %>%
      mutate(zscore_fact = ((unmapped - mean_fact) / sd_fact),
             abs_z = abs(zscore_fact),
             outlier = case_when(zscore_fact > n_sd ~ 1L,
                                 TRUE ~ 0L)) %>%
      group_by(site, variable, n_w_fact, sd_fact, mean_fact) %>%
      mutate(outlier_fact = sum(outlier),
             prop_outlier_fact = round(outlier_fact / n_w_fact, 3)) %>%
      select(group_vars(.), n_w_fact, outlier_fact, mean_fact, sd_fact, prop_outlier_fact) %>%
      ungroup() %>% distinct() %>%
      left_join(all_vals)

    ## combined
    unmapped_cts <- fact_vals %>% replace(is.na(.), 0)

    return(unmapped_cts)
}
