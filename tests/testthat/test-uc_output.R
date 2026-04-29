
test_that('errors on incorrect output_function', {

  tbl_test <- data.frame('test'= c(1, 2, 3),
                         'output_function' = 'uc_test')

  expect_error(uc_output(process_output = tbl_test))
})


test_that('single site, exploratory, no time', {

  tbl_test <- tidyr::tibble('site' = 'a',
                            'total_rows' = 100,
                            'total_pt' = 1000,
                            'unmapped_rows' = 50,
                            'unmapped_pt' = 500,
                            'unmapped_pt_prop' = 0.5,
                            'unmapped_row_prop' = 0.5,
                            'variable' = 'test',
                            'output_function' = 'uc_ss_exp_cs')

  expect_no_error(uc_output(process_output = tbl_test,
                             output_col = 'unmapped_row_prop'))

  expect_error(uc_output(process_output = tbl_test,
                         output_col = 'test'))

})


test_that('single site, anomaly detection, no time', {

  tbl_test <- tidyr::tibble('site' = 'a',
                            'n_w_fact' = 100,
                            'n_tot' = 1000,
                            'sd_threshold' = 2,
                            'outlier_fact' = 50,
                            'outlier_tot' = 500,
                            'prop_outlier_fact' = 0.5,
                            'prop_outlier_tot' = 0.5,
                            'variable' = 'test',
                            'output_function' = 'uc_ss_anom_cs')

  expect_no_error(uc_output(process_output = tbl_test,
                            output_col = 'prop_outlier_fact'))

})


test_that('multi site, exploratory, no time -- proportion', {

  tbl_test <- tidyr::tibble('site' = c('a', 'b'),
                            'total_rows' = c(100, 400),
                            'total_pt' = c(1000, 1000),
                            'unmapped_rows' = c(50, 10),
                            'unmapped_pt' = c(500, 100),
                            'unmapped_pt_prop' = c(0.5, 0.1),
                            'unmapped_row_prop' = c(0.5, 0.7),
                            'median_site_with0s' = c(50, 10),
                            'median_all_with0s' = c(25, 25),
                            'variable' = c('test', 'test'),
                            'output_function' = 'uc_ms_exp_cs')

  expect_no_error(uc_output(process_output = tbl_test,
                             output_col = 'unmapped_row_prop'))

  expect_no_error(uc_output(process_output = tbl_test,
                            output_col = 'unmapped_row_prop',
                            large_n = TRUE))

  expect_no_error(uc_output(process_output = tbl_test,
                            output_col = 'unmapped_row_prop',
                            large_n = TRUE,
                            large_n_sites = 'a'))

  expect_error(uc_output(process_output = tbl_test,
                          output_col = 'test'))

})

test_that('multi site, exploratory, no time -- median', {

  tbl_test <- tidyr::tibble('site' = c('a', 'b'),
                            'total_rows' = c(100, 400),
                            'total_pt' = c(1000, 1000),
                            'unmapped_rows' = c(50, 10),
                            'unmapped_pt' = c(500, 100),
                            'unmapped_pt_prop' = c(0.5, 0.1),
                            'unmapped_row_prop' = c(0.5, 0.7),
                            'median_site_with0s' = c(50, 10),
                            'median_all_with0s' = c(25, 25),
                            'variable' = c('test', 'test'),
                            'output_function' = 'uc_ms_exp_cs')

  expect_no_error(uc_output(process_output = tbl_test,
                            output_col = 'median_site_with0s'))

  expect_no_error(uc_output(process_output = tbl_test,
                            output_col = 'median_site_with0s',
                            large_n = TRUE))

  expect_no_error(uc_output(process_output = tbl_test,
                            output_col = 'median_site_with0s',
                            large_n = TRUE,
                            large_n_sites = 'a'))

  expect_error(uc_output(process_output = tbl_test,
                         output_col = 'test'))

})


test_that('multi site, anomaly detection, no time', {

  tbl_test <- tidyr::tibble('site' = c('a', 'b', 'c'),
                            'total_rows' = c(100, 400, 500),
                            'total_pt' = c(1000, 1000, 100),
                            'unmapped_rows' = c(50, 10, 50),
                            'unmapped_pt' = c(500, 100, 900),
                            'unmapped_pt_prop' = c(0.5, 0.1, 0.3),
                            'unmapped_row_prop' = c(0.5, 0.7, 0.1),
                            'variable' = c('test', 'test', 'test'),
                            'mean_val' = c(0.85, 0.85, 0.85),
                            'median_val' = c(0.82, 0.82, 0.82),
                            'sd_val' = c(0.05, 0.05, 0.05),
                            'mad_val' = c(0.02, 0.02, 0.02),
                            'cov_val' = c(0.01, 0.01, 0.01),
                            'max_val' = c(0.95, 0.95, 0.95),
                            'min_val' = c(0.79, 0.79, 0.79),
                            'range_val' = c(0.16, 0.16, 0.16),
                            'total_ct' = c(3,3,3),
                            'analysis_eligible' = c('yes','yes','yes'),
                            'lower_tail' = c(0.8134, 0.8134, 0.8134),
                            'upper_tail' = c(0.932, 0.932, 0.932),
                            'anomaly_yn' = c('no outlier', 'outlier', 'outlier'),
                            'output_function' = c('uc_ms_anom_cs','uc_ms_anom_cs','uc_ms_anom_cs'))

  expect_no_error(uc_output(process_output = tbl_test,
                             output_col = 'unmapped_row_prop'))

  expect_no_error(uc_output(process_output = tbl_test,
                            output_col = 'unmapped_row_prop',
                            large_n = TRUE))

  expect_no_error(uc_output(process_output = tbl_test,
                            output_col = 'unmapped_row_prop',
                            large_n = TRUE,
                            large_n_sites = 'a'))

  expect_no_error(uc_output(process_output = tbl_test %>% dplyr::mutate(anomaly_yn = 'no outlier in group'),
                             output_col = 'unmapped_row_prop'))

  expect_error(uc_output(process_output = tbl_test,
                          output_col = 'test'))

})


test_that('single site, exploratory, across time', {

  tbl_test <- tidyr::tibble('site' = c('a', 'a', 'a'),
                            'time_start' = c('2018-01-01', '2019-01-01', '2020-01-01'),
                            'time_increment' = c('year', 'year', 'year'),
                            'total_rows' = c(100, 400, 500),
                            'total_pt' = c(1000, 1000, 100),
                            'unmapped_rows' = c(50, 10, 50),
                            'unmapped_pt' = c(500, 100, 900),
                            'unmapped_pt_prop' = c(0.5, 0.1, 0.3),
                            'unmapped_row_prop' = c(0.5, 0.7, 0.1),
                            'variable' = c('test', 'test', 'test'),
                            'output_function' = c('uc_ss_exp_la','uc_ss_exp_la','uc_ss_exp_la'))

  expect_no_error(uc_output(process_output = tbl_test,
                             output_col = 'unmapped_row_prop'))

  expect_error(uc_output(process_output = tbl_test,
                         output_col = 'test'))

})

test_that('multi site, exploratory, across time', {

  tbl_test <- tidyr::tibble('site' = c('a', 'a', 'a', 'b', 'b', 'b'),
                            'time_start' = c('2018-01-01', '2019-01-01', '2020-01-01',
                                             '2018-01-01', '2019-01-01', '2020-01-01'),
                            'time_increment' = c('year', 'year', 'year',
                                                 'year', 'year', 'year'),
                            'total_pt' = c(10, 20, 30, 10, 20, 30),
                            'total_rows' = c(100, 200, 300, 100, 200, 300),
                            'unmapped_pt' = c(5, 15, 25, 5, 15, 25),
                            'unmapped_rows' = c(50, 150, 250, 50, 150, 250),
                            'unmapped_pt_prop' = c(0.5, 0.7, 0.8, 0.5, 0.7, 0.8),
                            'unmapped_row_prop' = c(0.5, 0.7, 0.8, 0.5, 0.7, 0.8),
                            'variable' = c('test', 'test', 'test', 'test', 'test', 'test'),
                            'output_function' = c('uc_ms_exp_la','uc_ms_exp_la','uc_ms_exp_la',
                                                  'uc_ms_exp_la','uc_ms_exp_la','uc_ms_exp_la'))

  expect_no_error(uc_output(process_output = tbl_test,
                             output_col = 'unmapped_row_prop',
                             filter_variable = 'test'))

  expect_no_error(uc_output(process_output = tbl_test,
                            output_col = 'unmapped_row_prop',
                            filter_variable = 'test',
                            large_n = TRUE))

  expect_no_error(uc_output(process_output = tbl_test,
                            output_col = 'unmapped_row_prop',
                            filter_variable = 'test',
                            large_n = TRUE,
                            large_n_sites = 'a'))

  expect_error(uc_output(process_output = tbl_test,
                          output_col = 'test',
                          filter_variable = 'test'))

})


test_that('single site, anomaly detection, across time - year', {

  tbl_test <- tidyr::tibble('site' = c('a', 'a', 'a'),
                            'time_start' = c('2018-01-01', '2019-01-01', '2020-01-01'),
                            'time_increment' = c('year', 'year', 'year'),
                            'total_rows' = c(100, 400, 500),
                            'total_pt' = c(1000, 1000, 100),
                            'unmapped_rows' = c(50, 10, 50),
                            'unmapped_pt' = c(500, 100, 900),
                            'unmapped_pt_prop' = c(0.5, 0.1, 0.3),
                            'unmapped_row_prop' = c(0.5, 0.7, 0.1),
                            'variable' = c('test', 'test', 'test'),
                            'output_function' = c('uc_ss_anom_la','uc_ss_anom_la','uc_ss_anom_la'))

  expect_no_error(uc_output(process_output = tbl_test,
                             output_col = 'unmapped_row_prop',
                             filter_variable = 'test'))

  expect_error(uc_output(process_output = tbl_test,
                          output_col = 'test',
                          filter_variable = 'test'))

})


test_that('single site, anomaly detection, across time - month', {

  tbl_test <- tidyr::tibble('site' = c('a', 'a', 'a', 'a', 'a'),
                            'time_start' = c('2018-01-01', '2018-02-01', '2018-03-01',
                                             '2018-04-01', '2018-05-01'),
                            'time_increment' = c('month', 'month', 'month', 'month', 'month'),
                            'total_rows' = c(100, 400, 500, 100, 100),
                            'total_pt' = c(1000, 1000, 100, 100, 100),
                            'unmapped_rows' = c(50, 10, 50, 100, 100),
                            'unmapped_pt' = c(500, 100, 900, 100, 100),
                            'unmapped_pt_prop' = c(0.5, 0.1, 0.3, 0.2, 0.2),
                            'unmapped_row_prop' = c(0.5, 0.7, 0.1, 0.2, 0.2),
                            'variable' = c('test', 'test', 'test', 'test', 'test'),
                            'observed' = c(0.5, 0.6, 0.7, 0.8, 0.9),
                            'season' = c(1,2,3,4,5),
                            'trend' = c(1,2,3,4,5),
                            'remainder' = c(0.46, 0.57, 0.69, 0.82, 0.88),
                            'seasonadj' = c(1,2,3,4,5),
                            'anomaly' = c('Yes', 'No', 'No', 'No', 'Yes'),
                            'anomaly_direction' = c(-1,0,0,0,1),
                            'anomaly_score' = c(1,2,3,4,5),
                            'recomposed_l1' = c(0.44, 0.6, 0.5, 0.49, 0.46),
                            'recomposed_l2' = c(0.84, 0.8, 0.8, 0.89, 0.86),
                            'observed_clean' = c(0.46, 0.57, 0.69, 0.82, 0.88),
                            'output_function' = c('uc_ss_anom_la','uc_ss_anom_la','uc_ss_anom_la',
                                                  'uc_ss_anom_la','uc_ss_anom_la'))

  expect_no_error(uc_output(process_output = tbl_test,
                             output_col = 'unmapped_row_prop',
                             filter_variable = 'test'))

  expect_error(uc_output(process_output = tbl_test,
                          output_col = 'test',
                          filter_variable = 'test'))

})


test_that('multi site, anomaly detection, across time', {

  tbl_test <- tidyr::tibble('site' = c('a', 'a', 'a', 'a', 'a', 'b', 'b', 'b', 'b', 'b'),
                            'time_start' = c('2018-01-01', '2019-01-01', '2020-01-01', '2021-01-01', '2022-01-01',
                                             '2018-01-01', '2019-01-01', '2020-01-01', '2021-01-01', '2022-01-01'),
                            'variable' = c('diagnoses', 'diagnoses', 'diagnoses', 'diagnoses', 'diagnoses',
                                         'diagnoses', 'diagnoses', 'diagnoses', 'diagnoses', 'diagnoses'),
                            'unmapped_row_prop' = c(0.84, 0.87, 0.89, 0.91, 0.89, 0.73, 0.81, 0.83, 0.94, 0.94),
                            'mean_allsiteprop' = c(0.83, 0.83, 0.83, 0.83, 0.83, 0.83, 0.83, 0.83, 0.83, 0.83),
                            'median' = c(0.87, 0.87, 0.87, 0.87, 0.87, 0.87, 0.87, 0.87, 0.87, 0.87),
                            'date_numeric' = c(17000, 17000, 17000, 17000, 17000, 17000, 17000, 17000, 17000, 17000),
                            'site_loess' = c(0.84, 0.87, 0.89, 0.91, 0.89, 0.73, 0.81, 0.83, 0.94, 0.94),
                            'dist_eucl_mean' = c(0.84,0.84,0.84,0.84,0.84,0.9,0.9,0.9,0.9,0.9),
                            'output_function' = c('uc_ms_anom_la','uc_ms_anom_la','uc_ms_anom_la',
                                                  'uc_ms_anom_la','uc_ms_anom_la','uc_ms_anom_la',
                                                  'uc_ms_anom_la','uc_ms_anom_la','uc_ms_anom_la',
                                                  'uc_ms_anom_la'))

  expect_no_error(uc_output(process_output = tbl_test,
                             output_col = NULL,
                             filter_variable = 'diagnoses'))

  expect_no_error(uc_output(process_output = tbl_test,
                            output_col = NULL,
                            filter_variable = 'diagnoses',
                            large_n = TRUE))

  expect_no_error(uc_output(process_output = tbl_test,
                            output_col = NULL,
                            filter_variable = 'diagnoses',
                            large_n = TRUE,
                            large_n_sites = 'a'))

  expect_error(uc_output(process_output = tbl_test,
                          output_level = 'test',
                          filter_variable = 'diagnoses'))
})
