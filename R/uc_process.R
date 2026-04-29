
#' Unmapped Concepts
#'
#' This is a completeness module that will assess the distribution of unmapped values, both proportionally and by examining
#' the median number of unmapped values per patient. The user will provide the variables (`uc_input_file`) to be evaluated and
#' define any values that should be considered "unmapped" (NULL is considered by default).
#' Sample versions of these inputs, both for OMOP and PCORnet, are included as data in the package and
#' are accessible with `unmappedconcepts::`. Results can optionally be stratified by site, age group, and/or time.
#' This function is compatible with both the OMOP and the PCORnet CDMs based on the user's selection.
#'
#' @param cohort *tabular input* || **required**
#'
#'   The cohort to be used for data quality testing. This table should contain,
#'   at minimum:
#'   - `site` | *character* | the name(s) of institutions included in your cohort
#'   - `person_id` / `patid` | *integer* / *character* | the patient identifier
#'   - `start_date` | *date* | the start of the cohort period
#'   - `end_date` | *date* | the end of the cohort period
#'
#'   Note that the start and end dates included in this table will be used to
#'   limit the search window for the analyses in this module.
#'
#' @param uc_input_file *tabular input* || **required**
#'
#'   A table with information about each of the variables that should be examined
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
#'
#'   To see an example of the structure of this file, please see `?unmappedconcepts::uc_input_file_omop` or
#'   `?unmappedconcepts::uc_input_file_pcornet`
#'
#' @param omop_or_pcornet *string* || **required**
#'
#'   A string, either `omop` or `pcornet`, indicating the CDM format of the data
#'
#' @param patient_level_tbl *boolean* || defaults to `FALSE`
#'
#'   A boolean indicating whether an additional table with patient level results should be output.
#'
#'   If `TRUE`, the output of this function will be a list containing both the summary and patient level
#'   output. Otherwise, this function will just output the summary dataframe
#'
#' @param multi_or_single_site *string* || defaults to `single`
#'
#'   A string, either `single` or `multi`, indicating whether a single-site or
#'   multi-site analysis should be executed
#'
#' @param anomaly_or_exploratory *string* || defaults to `exploratory`
#'
#'   A string, either `anomaly` or `exploratory`, indicating what type of results
#'   should be produced.
#'
#'   Exploratory analyses give a high level summary of the data to examine the
#'   fact representation within the cohort. Anomaly detection analyses are
#'   specialized to identify outliers within the cohort.
#'
#' @param time *boolean* || defaults to `FALSE`
#'
#'   A boolean to indicate whether to execute a longitudinal analysis
#'
#' @param time_span *vector - length 2* || defaults to `c('2012-01-01', '2020-01-01')`
#'
#'   A vector indicating the lower and upper bounds of the time series for longitudinal analyses
#'
#' @param time_period *string* || defaults to `year`
#'
#'   A string indicating the distance between dates within the specified time_span.
#'   Defaults to `year`, but other time periods such as `month` or `week` are
#'   also acceptable
#'
#' @param p_value *numeric* || defaults to `0.9`
#'
#'   The p value to be used as a threshold in the Multi-Site,
#'   Anomaly Detection, Cross-Sectional analysis
#'
#' @param n_sd *numeric* || defaults to `2`
#'
#'   For `Single Site, Anomaly Detection, Cross-Sectional` analysis, the number
#'   of standard deviations that should be used as a threshold to
#'   identify an outlier
#'
#' @param age_groups *tabular input* || defaults to `NULL`
#'
#'   If you would like to stratify the results by age group, create a table or
#'   CSV file with the following columns and use it as input to this parameter:
#'
#'   - `min_age` | *integer* | the minimum age for the group (i.e. 10)
#'   - `max_age` | *integer* | the maximum age for the group (i.e. 20)
#'   - `group` | *character* | a string label for the group (i.e. 10-20, Young Adult, etc.)
#'
#'   If you would *not* like to stratify by age group, leave as `NULL`
#'
#' @param output_level *string* || defaults to `row`
#'
#'   A string indicating the analysis level to use as the basis for the
#'   Multi Site, Anomaly Detection computations
#'
#'   Acceptable values are either `patient` or `row`
#'
#' @returns This function will return a dataframe summarizing the
#'          distribution of unmapped values for each user-defined input. For a
#'          more detailed description of output specific to each check type,
#'          see the PEDSpace metadata repository
#'
#' @import cli
#' @import squba.gen
#' @import argos
#' @import dplyr
#'
#' @export
#'
#' @example inst/example-uc_process_output.R
#'
uc_process <- function(cohort,
                       uc_input_file,
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
      uc_dat <- compute_uc(cohort = cohort_prep,
                           uc_tbl = uc_input_file,
                           site_col = site_col,
                           grouped_list = grouped_list,
                           time = FALSE,
                           omop_or_pcornet = omop_or_pcornet)

      uc_ptct <- uc_dat$pt_lv %>% replace_site_col()
      uc_dat <- uc_dat$summary %>% replace_site_col()

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
    }else if(anomaly_or_exploratory == 'anomaly' && multi_or_single_site == 'single'){
      uc_rslt <- compute_uc_ssanom(cohort = cohort_prep,
                                   uc_ptlv_rslt = uc_ptct,
                                   n_sd = n_sd) %>%
         replace_site_col() %>%
         mutate(sd_threshold = n_sd)
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
                                       uc_tbl = uc_input_file,
                                       site_col = site_col,
                                       grouped_list = grouped_list,
                                       time = TRUE,
                                       omop_or_pcornet = omop_or_pcornet)
                          }) %>% replace_site_col()

    if(tolower(omop_or_pcornet) == 'omop'){
      uc_ptct <- uc_dat %>% select(site, time_start, time_increment, variable, person_id, unmapped) %>%
        filter(!is.na(person_id))
      uc_dat <- uc_dat %>% select(-c(person_id, unmapped)) %>% distinct() %>% filter(!is.na(total_rows))
    }else{
      uc_ptct <- uc_dat %>% select(site, time_start, time_increment, variable, patid, unmapped) %>%
        filter(!is.na(patid))
      uc_dat <- uc_dat %>% select(-c(patid, unmapped)) %>% distinct() %>% filter(!is.na(total_rows))
    }

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
