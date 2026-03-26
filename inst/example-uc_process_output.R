
#' Source setup file
source(system.file('setup.R', package = 'unmappedconcepts'))

#' Create in-memory RSQLite database using data in extdata directory
conn <- mk_testdb_omop()

#' Establish connection to database and generate internal configurations
initialize_dq_session(session_name = 'uc_process_test',
                      working_directory = my_directory,
                      db_conn = conn,
                      is_json = FALSE,
                      file_subdirectory = my_file_folder,
                      cdm_schema = NA)

#' Build mock study cohort
cohort <- cdm_tbl('person') %>% dplyr::distinct(person_id) %>%
  dplyr::mutate(start_date = as.Date(-15000), # RSQLite does not store date objects,
                                      # hence the numerics
                end_date = as.Date(20000),
                site = ifelse(person_id %in% c(1:6), 'synth1', 'synth2'))

#' Execute `uc_process` function
#' This example will use the single site, exploratory, cross sectional
#' configuration
uc_process_example <- uc_process(cohort = cohort,
                                 multi_or_single_site = 'single',
                                 anomaly_or_exploratory = 'exploratory',
                                 time = FALSE,
                                 omop_or_pcornet = 'omop',
                                 uc_input_file = uc_input_file_omop) %>%
  suppressMessages()

uc_process_example

#' Execute `uc_output` function
uc_output_example <- uc_output(process_output = uc_process_example,
                               output_col = 'unmapped_row_prop')

uc_output_example

#' Easily convert the graph into an interactive ggiraph or plotly object with
#' `make_interactive_squba()`

make_interactive_squba(uc_output_example)
