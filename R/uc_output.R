
uc_output <- function(process_output,
                      output_col,
                      filter_variable = NULL,
                      large_n = FALSE,
                      large_n_sites = NULL){

  output_function <- process_output %>% collect() %>% ungroup() %>%
    distinct(output_function) %>% pull()

  if('age_grp' %in% colnames(process_output)){facet <- 'age_grp'}else{facet <- NULL}

  if(output_function == 'uc_ss_exp_cs'){

    uc_output <- uc_ss_exp_cs(process_output = process_output,
                              output_col = output_col,
                              facet = facet)

  }else if(output_function == 'uc_ss_anom_cs'){

    uc_output <- uc_ss_anom_cs(process_output = process_output,
                               output_col = output_col,
                               facet = facet)

  }else if(output_function == 'uc_ms_exp_cs'){

    uc_output <- uc_ms_exp_cs(process_output = process_output,
                              output_col = output_col,
                              filter_variable = filter_variable,
                              facet = facet,
                              large_n = large_n,
                              large_n_sites = large_n_sites)

  }else if(output_function == 'uc_ms_anom_cs'){

    uc_output <- uc_ms_anom_cs(process_output = process_output,
                               filter_variable = filter_variable,
                               large_n = large_n,
                               large_n_sites = large_n_sites)

  }else if(output_function == 'uc_ss_exp_la'){

    uc_output <- uc_ss_exp_la(process_output = process_output,
                              output_col = output_col,
                              facet = facet)

  }else if(output_function == 'uc_ss_anom_la'){

    uc_output <- uc_ss_anom_la(process_output = process_output,
                               output_col = output_col,
                               filter_variable = filter_variable,
                               facet = facet)

  }else if(output_function == 'uc_ms_exp_la'){

    uc_output <- uc_ms_exp_la(process_output = process_output,
                              output_col = output_col,
                              filter_variable = filter_variable,
                              facet = facet,
                              large_n = large_n,
                              large_n_sites = large_n_sites)

  }else if(output_function == 'uc_ms_anom_la'){

    uc_output <- uc_ms_anom_la(process_output = process_output,
                               filter_variable = filter_variable,
                               large_n = large_n,
                               large_n_sites = large_n_sites)

  }else(cli::cli_abort('Please enter a valid output function for this check type.'))

  return(uc_output)
}
