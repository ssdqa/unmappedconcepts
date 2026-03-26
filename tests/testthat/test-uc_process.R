
uc_input<- dplyr::tibble('variable' = c('visit type',
                                        'hypertension provider'),
                         'domain_tbl' = c('visit_occurrence',
                                          'condition_occurrence'),
                         'unmapped_field' = c('visit_concept_id',
                                              'provider_id'),
                         'unmapped_values' = c('9203', # playing pretend here!
                                               '8'),
                         'concept_field' = c(NA, 'condition_concept_id'),
                         'date_field' = c('visit_start_date',
                                          'condition_start_date'),
                         'codeset_name' = c(NA, 'dx_hypertension'),
                         'filter_logic' = c(NA, NA))

## Testing error functionality
test_that('only single & multi are allowed inputs', {

  cht <- data.frame('person_id' = c(1000, 1001),
                    'site' = c('a', 'b'),
                    'start_date' = c('2007-01-01','2008-01-01'),
                    'end_date' = c('2011-01-01','2009-01-01'))

  expect_error(uc_process(cohort = cht,
                          uc_input_file = uc_input,
                          multi_or_single_site = 'test',
                          anomaly_or_exploratory = 'exploratory',
                          omop_or_pcornet = 'omop'))
})


test_that('only anomaly & exploratory are allowed inputs', {

  cht <- data.frame('person_id' = c(1000, 1001),
                    'site' = c('a', 'b'),
                    'start_date' = c('2007-01-01','2008-01-01'),
                    'end_date' = c('2011-01-01','2009-01-01'))

  expect_error(uc_process(cohort = cht,
                          uc_input_file = uc_input,
                          multi_or_single_site = 'single',
                          anomaly_or_exploratory = 'test',
                          omop_or_pcornet = 'omop'))
})

test_that('only omop & pcornet are allowed inputs', {

  cht <- data.frame('person_id' = c(1000, 1001),
                    'site' = c('a', 'b'),
                    'start_date' = c('2007-01-01','2008-01-01'),
                    'end_date' = c('2011-01-01','2009-01-01'))

  expect_error(uc_process(cohort = cht,
                          uc_input_file = uc_input,
                          multi_or_single_site = 'single',
                          anomaly_or_exploratory = 'exploratory',
                          omop_or_pcornet = 'test'))
})


## Generally checking that code runs
test_that('uc ss/ms exp nt -- omop', {

  rlang::is_installed("DBI")
  rlang::is_installed("readr")
  rlang::is_installed('RSQLite')

  conn <- mk_testdb_omop()

  initialize_dq_session(session_name = 'evp_process_test',
                        working_directory = getwd(),
                        db_conn = conn,
                        is_json = FALSE,
                        file_subdirectory = 'testspecs',
                        cdm_schema = NA)
  config('subdirs', list('specs' = 'testspecs'))

  cohort <- cdm_tbl('person') %>% distinct(person_id) %>%
    mutate(start_date = as.Date(-5000),
           end_date = as.Date(15000),
           site = ifelse(person_id %in% c(1:6), 'synth1', 'synth2'))

  expect_no_error(uc_process(cohort = cohort,
                             uc_input_file = uc_input,
                             multi_or_single_site = 'single',
                             anomaly_or_exploratory = 'exploratory',
                             omop_or_pcornet = 'omop'))
})

test_that('uc ss anom nt -- omop', {

  rlang::is_installed("DBI")
  rlang::is_installed("readr")
  rlang::is_installed('RSQLite')

  conn <- mk_testdb_omop()

  initialize_dq_session(session_name = 'evp_process_test',
                        working_directory = getwd(),
                        db_conn = conn,
                        is_json = FALSE,
                        file_subdirectory = 'testspecs',
                        cdm_schema = NA)
  config('subdirs', list('specs' = 'testspecs'))

  cohort <- cdm_tbl('person') %>% distinct(person_id) %>%
    mutate(start_date = as.Date(-5000),
           end_date = as.Date(15000),
           site = ifelse(person_id %in% c(1:6), 'synth1', 'synth2'))

  expect_no_error(uc_process(cohort = cohort,
                             uc_input_file = uc_input,
                             multi_or_single_site = 'single',
                             anomaly_or_exploratory = 'anomaly',
                             omop_or_pcornet = 'omop'))
})

test_that('uc ms anom nt -- omop', {

  rlang::is_installed("DBI")
  rlang::is_installed("readr")
  rlang::is_installed('RSQLite')

  conn <- mk_testdb_omop()

  initialize_dq_session(session_name = 'evp_process_test',
                        working_directory = getwd(),
                        db_conn = conn,
                        is_json = FALSE,
                        file_subdirectory = 'testspecs',
                        cdm_schema = NA)
  config('subdirs', list('specs' = 'testspecs'))

  cohort <- cdm_tbl('person') %>% distinct(person_id) %>%
    mutate(start_date = as.Date(-5000),
           end_date = as.Date(15000),
           site = ifelse(person_id %in% c(1:6), 'synth1', 'synth2'))

  expect_no_error(uc_process(cohort = cohort,
                             uc_input_file = uc_input,
                             multi_or_single_site = 'multi',
                             anomaly_or_exploratory = 'anomaly',
                             omop_or_pcornet = 'omop'))
})

test_that('uc ss/ms exp at -- omop', {

  rlang::is_installed("DBI")
  rlang::is_installed("readr")
  rlang::is_installed('RSQLite')

  conn <- mk_testdb_omop()

  initialize_dq_session(session_name = 'evp_process_test',
                        working_directory = getwd(),
                        db_conn = conn,
                        is_json = FALSE,
                        file_subdirectory = 'testspecs',
                        cdm_schema = NA)
  config('subdirs', list('specs' = 'testspecs'))

  cohort <- cdm_tbl('person') %>% distinct(person_id) %>%
    mutate(start_date = as.Date(-5000),
           end_date = as.Date(15000),
           site = ifelse(person_id %in% c(1:6), 'synth1', 'synth2'))

  expect_error(uc_process(cohort = cohort,
                          uc_input_file = uc_input,
                          multi_or_single_site = 'single',
                          anomaly_or_exploratory = 'exploratory',
                          omop_or_pcornet = 'omop',
                          time = TRUE,
                          time_period = 'year',
                          time_span = c('1950-01-01', '1970-01-01')))
})
