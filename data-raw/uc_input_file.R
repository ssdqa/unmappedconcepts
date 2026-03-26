## code to prepare `DATASET` dataset goes here

uc_input_file_omop <- dplyr::tibble('variable' = c('visit type',
                                                   'hypertension provider'),
                                     'domain_tbl' = c('visit_occurrence',
                                                      'condition_occurrence'),
                                     'unmapped_field' = c('visit_concept_id',
                                                          'provider_id'),
                                     'unmapped_values' = c('0',
                                                           '0,9999'),
                                     'concept_field' = c(NA, 'condition_concept_id'),
                                     'date_field' = c('visit_start_date',
                                                      'condition_start_date'),
                                     'codeset_name' = c(NA, 'dx_hypertension'),
                                     'filter_logic' = c(NA, NA))

usethis::use_data(uc_input_file_omop, overwrite = TRUE)


uc_input_file_pcornet <- dplyr::tibble('variable' = c('lab units',
                                                      'mri visit type'),
                                       'domain_tbl' = c('lab_result_cm',
                                                        'procedures'),
                                       'unmapped_field' = c('result_unit',
                                                            'enc_type'),
                                       'unmapped_values' = c('NI,UN,OT',
                                                             'NI,UN,OT'),
                                       'concept_field' = c(NA, 'px'),
                                       'date_field' = c('result_date',
                                                        'px_date'),
                                       'codeset_name' = c(NA, 'px_mri'),
                                       'filter_logic' = c(NA, NA),
                                       'vocabulary_field' = c(NA, 'px_type'))

usethis::use_data(uc_input_file_pcornet, overwrite = TRUE)
