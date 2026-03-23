
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
        join_cols2 <- set_names('vocabulary_id', uc_list[[i]]$vocabulary_field)
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

    unmapped_vals <-
      tbl_use %>%
      filter(as.character(!!sym(colname)) %in% vals | is.na(!!sym(colname)))

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
        tibble::tibble(
          unmapped_rows = 0L,
          unmapped_pt = 0L,
          variable = varb
        )
    }

    ## per patient
    per_pt <- tbl_use %>%
      mutate(tag = ifelse(as.character(!!sym(colname)) %in% vals | is.na(!!sym(colname)),
                          'unmapped',
                          'mapped')) %>%
      group_by(!!sym(person_col), tag, .add = TRUE) %>%
      summarise(unmapped_pp = n()) %>%
      pivot_wider(names_from = 'tag',
                  values_from = 'unmapped_pp')

    if('unmapped' %in% colnames(per_pt)){
      per_pt <- per_pt %>%
        mutate(unmapped = ifelse(is.na(unmapped), 0L, unmapped)) %>%
        select(-mapped) %>%
        collect()
    }else{
      per_pt <- per_pt %>% mutate(unmapped = 0L) %>% select(-mapped) %>% collect()
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


###################

compute_uc_ssanom <- function(cohort,
                              uc_tbl,
                              site_col = 'site',
                              grouped_list = 'site',
                              n_sd = 2,
                              time = FALSE,
                              omop_or_pcornet = 'omop'){
  uc_list <- split(uc_tbl, seq(nrow(uc_tbl)))

  check_concepts <- list()

  for(i in 1:length(uc_list)) {

    varb <- uc_list[[i]]$variable

    cli::cli_inform(paste0('Starting ', varb))

    if(omop_or_pcornet == 'omop'){
      join_cols <- purrr::set_names('concept_id', uc_list[[i]]$concept_field)
      person_col <- 'person_id'
    }else{
      join_cols <- purrr::set_names('concept_code', uc_list[[i]]$concept_field)

      if(!is.na(uc_list[[i]]$vocabulary_field)){
        join_cols2 <- set_names('vocabulary_id', uc_list[[i]]$vocabulary_field)
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

    unmapped_vals <-
      tbl_use %>%
      filter(as.character(!!sym(colname)) %in% vals | is.na(!!sym(colname)))

    ## per patient
    per_pt <- tbl_use %>%
      mutate(tag = ifelse(as.character(!!sym(colname)) %in% vals | is.na(!!sym(colname)),
                          'unmapped',
                          'mapped')) %>%
      group_by(!!sym(person_col), tag, .add = TRUE) %>%
      summarise(unmapped_pp = n()) %>%
      pivot_wider(names_from = 'tag',
                  values_from = 'unmapped_pp') %>%
      mutate(unmapped = ifelse(is.na(unmapped), 0L, unmapped)) %>%
      select(-mapped) %>%
      collect()

    n_tot <- cohort %>%
      summarise(ct = n()) %>%
      collect() %>% pull(ct)

    all_vals <- per_pt %>%
      group_by(!!sym(site_col)) %>%
      summarise(mean_tot=mean(unmapped),
                sd_tot=sd(unmapped),
                n_tot=n_tot)

    all_vals <- per_pt %>%
      left_join(all_vals) %>%
      mutate(zscore_tot = ((unmapped - mean_tot) / sd_tot),
             abs_z = abs(zscore_tot),
             outlier = case_when(zscore_tot > n_sd ~ 1L,
                                 TRUE ~ 0L)) %>%
      group_by(!!sym(site_col), n_tot, sd_tot, mean_tot) %>%
      mutate(outlier_tot = sum(outlier),
             prop_outlier_tot = round(outlier_tot / n_tot, 3)) %>%
      select(group_vars(.), n_tot, outlier_tot, mean_tot, sd_tot, prop_outlier_tot) %>%
      ungroup() %>% distinct()

    fact_vals <- per_pt %>%
      filter(unmapped != 0) %>%
      group_by(!!sym(site_col)) %>%
      summarise(mean_fact=mean(unmapped),
                sd_fact=sd(unmapped),
                n_w_fact=n())

    fact_vals <- per_pt %>%
      filter(unmapped != 0) %>%
      left_join(fact_vals) %>%
      mutate(zscore_fact = ((unmapped - mean_fact) / sd_fact),
             abs_z = abs(zscore_fact),
             outlier = case_when(zscore_fact > n_sd ~ 1L,
                                 TRUE ~ 0L)) %>%
      group_by(!!sym(site_col), n_w_fact, sd_fact, mean_fact) %>%
      mutate(outlier_fact = sum(outlier),
             prop_outlier_fact = round(outlier_fact / n_w_fact, 3)) %>%
      select(group_vars(.), n_w_fact, outlier_fact, mean_fact, sd_fact, prop_outlier_fact) %>%
      ungroup() %>% distinct() %>%
      left_join(all_vals) %>%
      mutate(variable = varb)

    ## combined
    unmapped_cts <- fact_vals %>% replace(is.na(.), 0)

    check_concepts[[i]] <- unmapped_cts

  }

  check_concepts_red <- purrr::reduce(.x = check_concepts,
                                      .f = dplyr::union)

  return(check_concepts_red)
}
