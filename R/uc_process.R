
uc_process <- function(cohort,
                       uc_table,
                       omop_or_pcornet,
                       patient_level_tbl = FALSE,
                       multi_or_single_site = 'single',
                       anomaly_or_exploratory = 'exploratory',
                       time = FALSE,
                       time_span = c('2012-01-01', '2020-01-01'),
                       time_period = 'year',
                       p_value = 0.9,
                       n_sd = 2,
                       age_groups = NULL,
                       output_level = c('row', 'patient')){

  ## Check proper arguments
  cli::cli_div(theme = list(span.code = list(color = 'blue')))

  if(!multi_or_single_site %in% c('single', 'multi')){cli::cli_abort('Invalid argument for {.code multi_or_single_site}: please enter either {.code multi} or {.code single}')}
  if(!anomaly_or_exploratory %in% c('anomaly', 'exploratory')){cli::cli_abort('Invalid argument for {.code anomaly_or_exploratory}: please enter either {.code anomaly} or {.code exploratory}')}
  if(!tolower(omop_or_pcornet) %in% c('omop', 'pcornet')){cli::cli_abort('Invalid argument for {.code omop_or_pcornet}: this function is only compatible with {.code omop} or {.code pcornet}')}
  if(!any(output_level %in% c('row', 'patient'))){cli::cli_abort('Invalid argument for {.code output_level}: please enter either {.code row} or {.code patient}')}

  ## parameter summary output
  output_type <- suppressWarnings(param_summ(check_string = 'uc',
                                             as.list(environment())))

  # Add site check
  site_filter <- check_site_type(cohort = cohort,
                                 multi_or_single_site = multi_or_single_site)
  cohort_filter <- site_filter$cohort
  grouped_list <- site_filter$grouped_list
  site_col <- site_filter$grouped_list
  site_list_adj <- site_filter$site_list_adj

  if(is.data.frame(age_groups)){grouped_list <- grouped_list %>% append('age_grp')}

  # Prep cohort
  cohort_prep <- prepare_cohort(cohort_tbl = cohort_filter,
                                age_groups = age_groups,
                                omop_or_pcornet = omop_or_pcornet) %>%
    group_by(!!! syms(grouped_list))

  var_col <- ifelse(length(output_level) > 1, output_level[1], output_level)
  var_col <- ifelse(var_col == 'row', 'unmapped_row_prop', 'unmapped_pt_prop')


  if(!time){
    if(anomaly_or_exploratory == 'anomaly' && multi_or_single_site == 'single'){
      uc_dat <- compute_uc_ssanom(cohort = cohort_prep,
                                  uc_tbl = uc_table,
                                  site_col = site_col,
                                  grouped_list = grouped_list,
                                  n_sd = n_sd,
                                  time = FALSE,
                                  omop_or_pcornet = omop_or_pcornet) %>%
        replace_site_col()
    }else{
      uc_dat <- compute_uc(cohort = cohort_prep,
                           uc_tbl = uc_table,
                           site_col = site_col,
                           grouped_list = grouped_list,
                           time = FALSE,
                           omop_or_pcornet = omop_or_pcornet) %>%
        replace_site_col()

      uc_ptct <- uc_dat$pt_lv
      uc_dat <- uc_dat$summary
    }

    if(anomaly_or_exploratory == 'anomaly' && multi_or_single_site == 'multi'){
      uc_tbl_int <- compute_dist_anomalies(df_tbl = uc_dat,
                                           grp_vars = c('variable'),
                                           var_col = var_col,
                                           denom_cols = c('variable', 'total_pt', 'total_rows'))

      uc_rslt <- detect_outliers(df_tbl = uc_tbl_int,
                                 tail_input = 'both',
                                 p_input = p_value,
                                 column_analysis = var_col,
                                 column_variable = 'variable')
    }else{uc_rslt <- uc_dat}
  }else{
    uc_dat <- compute_fot(cohort = cohort_prep,
                          site_col = site_col,
                          site_list = site_list_adj,
                          time_period = time_period,
                          time_span = time_span,
                          reduce_id = NULL,
                          check_func = function(dat){
                            compute_uc(cohort = dat,
                                       uc_tbl = uc_table,
                                       site_col = site_col,
                                       grouped_list = grouped_list,
                                       time = TRUE,
                                       omop_or_pcornet = omop_or_pcornet)
                          }) %>% replace_site_col()

    uc_ptct <- uc_dat %>% select(site, time_start, time_increment, variable, person_id, unmapped) %>%
      filter(!is.na(person_id))
    uc_dat <- uc_dat %>% select(-c(person_id, unmapped)) %>% distinct() %>% filter(!is.na(total_rows))

    if(anomaly_or_exploratory == 'anomaly' && multi_or_single_site == 'single'){
      uc_rslt <- anomalize_ss_anom_la(fot_input_tbl = uc_dat,
                                      time_var = 'time_start',
                                      grp_vars = 'variable',
                                      var_col = var_col)
    }else if(anomaly_or_exploratory == 'anomaly' && multi_or_single_site == 'multi'){
      uc_rslt <- ms_anom_euclidean(fot_input_tbl = uc_dat,
                                   grp_vars = c('site', 'variable'),
                                   var_col = var_col)
    }else{uc_rslt <- uc_dat}
  }

  ## parameter summary output
  print(cli::boxx(c('You can optionally use this dataframe in the accompanying',
                    '`uc_output` function. Here are the parameters you will need:', '', output_type$vector, '',
                    'See ?uc_output for more details.'), padding = c(0,1,0,1),
                  header = cli::col_cyan('Output Function Details')))

  if(patient_level_tbl){
    output <- list('uc_summary_results' = uc_rslt %>% replace_site_col() %>% mutate(output_function = output_type$string),
                   'uc_patient_level_results' = uc_ptct %>% replace_site_col() %>% mutate(output_function = output_type$string))

    return(output)
  }else{
    return(uc_rslt %>% replace_site_col() %>% mutate(output_function = output_type$string))
  }

}
