# Unmapped Concepts

This is a completeness module that will assess the distribution of
unmapped values, both proportionally and by examining the median number
of unmapped values per patient. The user will provide the variables
(`uc_input_file`) to be evaluated and define any values that should be
considered "unmapped" (NULL is considered by default). Sample versions
of these inputs, both for OMOP and PCORnet, are included as data in the
package and are accessible with `unmappedconcepts::`. Results can
optionally be stratified by site, age group, and/or time. This function
is compatible with both the OMOP and the PCORnet CDMs based on the
user's selection.

## Usage

``` r
uc_process(
  cohort,
  uc_input_file,
  omop_or_pcornet,
  patient_level_tbl = FALSE,
  multi_or_single_site = "single",
  anomaly_or_exploratory = "exploratory",
  time = FALSE,
  time_span = c("2012-01-01", "2020-01-01"),
  time_period = "year",
  p_value = 0.9,
  n_sd = 2,
  age_groups = NULL,
  output_level = c("row", "patient")
)
```

## Arguments

- cohort:

  *tabular input* \|\| **required**

  The cohort to be used for data quality testing. This table should
  contain, at minimum:

  - `site` \| *character* \| the name(s) of institutions included in
    your cohort

  - `person_id` / `patid` \| *integer* / *character* \| the patient
    identifier

  - `start_date` \| *date* \| the start of the cohort period

  - `end_date` \| *date* \| the end of the cohort period

  Note that the start and end dates included in this table will be used
  to limit the search window for the analyses in this module.

- uc_input_file:

  *tabular input* \|\| **required**

  A table with information about each of the variables that should be
  examined in the analysis. This table should contain the following
  columns:

  - `variable` \| *character* \| a string label for the variable being
    evaluated for unmapped values

  - `domain_tbl` \| *character* \| the CDM table where the variable is
    found

  - `unmapped_field` \| *character* \| the name of the field where
    unmapped values should be identified

  - `unmapped_values` \| *character* \| a string or vector with each
    value that should be considered as "unmapped"

  - `concept_field` \| *character* \| the string name of the field in
    the domain table where the concepts are located (if codeset is
    provided)

  - `date_field` \| *character* \| the name of the field in the domain
    table with the date that should be used for temporal filtering

  - `vocabulary_field` \| *character* \| for PCORnet applications, the
    name of the field in the domain table with a vocabulary identifier
    to differentiate concepts from one another (ex: dx_type); can be set
    to NA for OMOP applications

  - `codeset_name` \| *character* \| (optional) the name of the codeset
    that can be used to define a variable of interest (ex: evaluate unit
    completeness for a specific drug)

  - `filter_logic` \| *character* \| (optional) logic to be applied to
    the domain_tbl in order to achieve the definition of interest;
    should be written as if you were applying it in a dplyr::filter
    command in R

  To see an example of the structure of this file, please see
  [`?unmappedconcepts::uc_input_file_omop`](https://ssdqa.github.io/unmappedconcepts/reference/uc_input_file_omop.md)
  or
  [`?unmappedconcepts::uc_input_file_pcornet`](https://ssdqa.github.io/unmappedconcepts/reference/uc_input_file_pcornet.md)

- omop_or_pcornet:

  *string* \|\| **required**

  A string, either `omop` or `pcornet`, indicating the CDM format of the
  data

- patient_level_tbl:

  *boolean* \|\| defaults to `FALSE`

  A boolean indicating whether an additional table with patient level
  results should be output.

  If `TRUE`, the output of this function will be a list containing both
  the summary and patient level output. Otherwise, this function will
  just output the summary dataframe

- multi_or_single_site:

  *string* \|\| defaults to `single`

  A string, either `single` or `multi`, indicating whether a single-site
  or multi-site analysis should be executed

- anomaly_or_exploratory:

  *string* \|\| defaults to `exploratory`

  A string, either `anomaly` or `exploratory`, indicating what type of
  results should be produced.

  Exploratory analyses give a high level summary of the data to examine
  the fact representation within the cohort. Anomaly detection analyses
  are specialized to identify outliers within the cohort.

- time:

  *boolean* \|\| defaults to `FALSE`

  A boolean to indicate whether to execute a longitudinal analysis

- time_span:

  *vector - length 2* \|\| defaults to `c('2012-01-01', '2020-01-01')`

  A vector indicating the lower and upper bounds of the time series for
  longitudinal analyses

- time_period:

  *string* \|\| defaults to `year`

  A string indicating the distance between dates within the specified
  time_span. Defaults to `year`, but other time periods such as `month`
  or `week` are also acceptable

- p_value:

  *numeric* \|\| defaults to `0.9`

  The p value to be used as a threshold in the Multi-Site, Anomaly
  Detection, Cross-Sectional analysis

- n_sd:

  *numeric* \|\| defaults to `2`

  For `Single Site, Anomaly Detection, Cross-Sectional` analysis, the
  number of standard deviations that should be used as a threshold to
  identify an outlier

- age_groups:

  *tabular input* \|\| defaults to `NULL`

  If you would like to stratify the results by age group, create a table
  or CSV file with the following columns and use it as input to this
  parameter:

  - `min_age` \| *integer* \| the minimum age for the group (i.e. 10)

  - `max_age` \| *integer* \| the maximum age for the group (i.e. 20)

  - `group` \| *character* \| a string label for the group (i.e. 10-20,
    Young Adult, etc.)

  If you would *not* like to stratify by age group, leave as `NULL`

- output_level:

  *string* \|\| defaults to `row`

  A string indicating the analysis level to use as the basis for the
  Multi Site, Anomaly Detection computations

  Acceptable values are either `patient` or `row`

## Value

This function will return a dataframe summarizing the distribution of
unmapped values for each user-defined input. For a more detailed
description of output specific to each check type, see the PEDSpace
metadata repository

## Examples

``` r
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
#> Connected to: :memory:@NA

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
#> ┌ Output Function Details ─────────────────────────────────────┐
#> │ You can optionally use this dataframe in the accompanying    │
#> │ `uc_output` function. Here are the parameters you will need: │
#> │                                                              │
#> │                                                              │
#> │ See ?uc_output for more details.                             │
#> └──────────────────────────────────────────────────────────────┘

uc_process_example
#> # A tibble: 2 × 13
#>   site  variable total_rows total_pt unmapped_rows unmapped_pt median_all_with0s
#>   <chr> <chr>         <int>    <int>         <int>       <int>             <dbl>
#> 1 comb… visit t…       1627       12             0           0                 0
#> 2 comb… hyperte…         58       12            13           1                 0
#> # ℹ 6 more variables: median_all_without0s <int>, median_site_with0s <dbl>,
#> #   median_site_without0s <int>, unmapped_row_prop <dbl>,
#> #   unmapped_pt_prop <dbl>, output_function <chr>

#' Execute `uc_output` function
uc_output_example <- uc_output(process_output = uc_process_example,
                               output_col = 'unmapped_row_prop')

uc_output_example


#' Easily convert the graph into an interactive ggiraph or plotly object with
#' `make_interactive_squba()`

make_interactive_squba(uc_output_example)

{"x":{"html":"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' class='ggiraph-svg' role='graphics-document' id='svg_b25b670b028f478b' viewBox='0 0 432 360'>\n <defs id='svg_b25b670b028f478b_defs'>\n  <clipPath id='svg_b25b670b028f478b_c1'>\n   <rect x='0' y='0' width='432' height='360'/>\n  <\/clipPath>\n  <clipPath id='svg_b25b670b028f478b_c2'>\n   <rect x='107.64' y='22.13' width='318.88' height='306.99'/>\n  <\/clipPath>\n  <clipPath id='svg_b25b670b028f478b_c3'>\n   <rect x='107.64' y='5.48' width='318.88' height='16.65'/>\n  <\/clipPath>\n <\/defs>\n <g id='svg_b25b670b028f478b_rootg' class='ggiraph-svg-rootg'>\n  <g clip-path='url(#svg_b25b670b028f478b_c1)'>\n   <rect x='0' y='0' width='432' height='360' fill='#FFFFFF' fill-opacity='1' stroke='#FFFFFF' stroke-opacity='1' stroke-width='0.75' stroke-linejoin='round' stroke-linecap='round' class='ggiraph-svg-bg'/>\n   <rect x='0' y='0' width='432' height='360' fill='#FFFFFF' fill-opacity='1' stroke='none'/>\n  <\/g>\n  <g clip-path='url(#svg_b25b670b028f478b_c2)'>\n   <polyline points='155.08,329.12 155.08,22.13' fill='none' stroke='#EBEBEB' stroke-opacity='1' stroke-width='0.53' stroke-linejoin='round' stroke-linecap='butt'/>\n   <polyline points='220.96,329.12 220.96,22.13' fill='none' stroke='#EBEBEB' stroke-opacity='1' stroke-width='0.53' stroke-linejoin='round' stroke-linecap='butt'/>\n   <polyline points='286.85,329.12 286.85,22.13' fill='none' stroke='#EBEBEB' stroke-opacity='1' stroke-width='0.53' stroke-linejoin='round' stroke-linecap='butt'/>\n   <polyline points='352.73,329.12 352.73,22.13' fill='none' stroke='#EBEBEB' stroke-opacity='1' stroke-width='0.53' stroke-linejoin='round' stroke-linecap='butt'/>\n   <polyline points='418.61,329.12 418.61,22.13' fill='none' stroke='#EBEBEB' stroke-opacity='1' stroke-width='0.53' stroke-linejoin='round' stroke-linecap='butt'/>\n   <polyline points='107.64,245.39 426.52,245.39' fill='none' stroke='#EBEBEB' stroke-opacity='1' stroke-width='1.07' stroke-linejoin='round' stroke-linecap='butt'/>\n   <polyline points='107.64,105.85 426.52,105.85' fill='none' stroke='#EBEBEB' stroke-opacity='1' stroke-width='1.07' stroke-linejoin='round' stroke-linecap='butt'/>\n   <polyline points='122.14,329.12 122.14,22.13' fill='none' stroke='#EBEBEB' stroke-opacity='1' stroke-width='1.07' stroke-linejoin='round' stroke-linecap='butt'/>\n   <polyline points='188.02,329.12 188.02,22.13' fill='none' stroke='#EBEBEB' stroke-opacity='1' stroke-width='1.07' stroke-linejoin='round' stroke-linecap='butt'/>\n   <polyline points='253.91,329.12 253.91,22.13' fill='none' stroke='#EBEBEB' stroke-opacity='1' stroke-width='1.07' stroke-linejoin='round' stroke-linecap='butt'/>\n   <polyline points='319.79,329.12 319.79,22.13' fill='none' stroke='#EBEBEB' stroke-opacity='1' stroke-width='1.07' stroke-linejoin='round' stroke-linecap='butt'/>\n   <polyline points='385.67,329.12 385.67,22.13' fill='none' stroke='#EBEBEB' stroke-opacity='1' stroke-width='1.07' stroke-linejoin='round' stroke-linecap='butt'/>\n   <rect id='svg_b25b670b028f478b_e1' x='122.14' y='43.06' width='0' height='125.58' fill='#BD777A' fill-opacity='1' stroke='none' title='Unmapped Pt: 0&amp;lt;br/&amp;gt;Unmapped Row: 0&amp;lt;br/&amp;gt;Total Pt: 12&amp;lt;br/&amp;gt;Total Row: 1,627'/>\n   <rect id='svg_b25b670b028f478b_e2' x='122.14' y='182.6' width='289.89' height='125.58' fill='#FF4D6F' fill-opacity='1' stroke='none' title='Unmapped Pt: 1&amp;lt;br/&amp;gt;Unmapped Row: 13&amp;lt;br/&amp;gt;Total Pt: 12&amp;lt;br/&amp;gt;Total Row: 58'/>\n  <\/g>\n  <g clip-path='url(#svg_b25b670b028f478b_c3)'>\n   <text x='259.75' y='16.83' font-size='6.6pt' font-family='Liberation Sans' fill='#1A1A1A' fill-opacity='1'>(all)<\/text>\n  <\/g>\n  <g clip-path='url(#svg_b25b670b028f478b_c1)'>\n   <text x='113.57' y='340.1' font-size='6.6pt' font-family='Liberation Sans' fill='#4D4D4D' fill-opacity='1'>0.00<\/text>\n   <text x='179.45' y='340.1' font-size='6.6pt' font-family='Liberation Sans' fill='#4D4D4D' fill-opacity='1'>0.05<\/text>\n   <text x='245.34' y='340.1' font-size='6.6pt' font-family='Liberation Sans' fill='#4D4D4D' fill-opacity='1'>0.10<\/text>\n   <text x='311.22' y='340.1' font-size='6.6pt' font-family='Liberation Sans' fill='#4D4D4D' fill-opacity='1'>0.15<\/text>\n   <text x='377.1' y='340.1' font-size='6.6pt' font-family='Liberation Sans' fill='#4D4D4D' fill-opacity='1'>0.20<\/text>\n   <text x='18.07' y='248.42' font-size='6.6pt' font-family='Liberation Sans' fill='#4D4D4D' fill-opacity='1'>hypertension provider<\/text>\n   <text x='68.48' y='108.88' font-size='6.6pt' font-family='Liberation Sans' fill='#4D4D4D' fill-opacity='1'>visit type<\/text>\n   <text x='210.21' y='352.24' font-size='8.25pt' font-family='Liberation Sans'>Prop. Unmapped Rows<\/text>\n   <text transform='translate(13.05,195.40) rotate(-90.00)' font-size='8.25pt' font-family='Liberation Sans'>Variable<\/text>\n  <\/g>\n <\/g>\n<\/svg>","js":null,"uid":"svg_b25b670b028f478b","ratio":1.2,"settings":{"tooltip":{"css":".tooltip_SVGID_ { padding:5px;background:black;color:white;border-radius:2px;text-align:left; ; position:absolute;pointer-events:none;z-index:9999;}","placement":"doc","opacity":0.9,"offx":10,"offy":10,"use_cursor_pos":true,"use_fill":false,"use_stroke":false,"delay_over":200,"delay_out":500},"hover":{"css":".hover_data_SVGID_ { fill:orange;stroke:black;cursor:pointer; }\ntext.hover_data_SVGID_ { stroke:none;fill:orange; }\ncircle.hover_data_SVGID_ { fill:orange;stroke:black; }\nline.hover_data_SVGID_, polyline.hover_data_SVGID_ { fill:none;stroke:orange; }\nrect.hover_data_SVGID_, polygon.hover_data_SVGID_, path.hover_data_SVGID_ { fill:orange;stroke:none; }\nimage.hover_data_SVGID_ { stroke:orange; }","reactive":true,"nearest_distance":null,"linked":false},"hover_inv":{"css":""},"hover_key":{"css":".hover_key_SVGID_ { fill:orange;stroke:black;cursor:pointer; }\ntext.hover_key_SVGID_ { stroke:none;fill:orange; }\ncircle.hover_key_SVGID_ { fill:orange;stroke:black; }\nline.hover_key_SVGID_, polyline.hover_key_SVGID_ { fill:none;stroke:orange; }\nrect.hover_key_SVGID_, polygon.hover_key_SVGID_, path.hover_key_SVGID_ { fill:orange;stroke:none; }\nimage.hover_key_SVGID_ { stroke:orange; }","reactive":true},"hover_theme":{"css":".hover_theme_SVGID_ { fill:orange;stroke:black;cursor:pointer; }\ntext.hover_theme_SVGID_ { stroke:none;fill:orange; }\ncircle.hover_theme_SVGID_ { fill:orange;stroke:black; }\nline.hover_theme_SVGID_, polyline.hover_theme_SVGID_ { fill:none;stroke:orange; }\nrect.hover_theme_SVGID_, polygon.hover_theme_SVGID_, path.hover_theme_SVGID_ { fill:orange;stroke:none; }\nimage.hover_theme_SVGID_ { stroke:orange; }","reactive":true},"select":{"css":".select_data_SVGID_ { fill:red;stroke:black;cursor:pointer; }\ntext.select_data_SVGID_ { stroke:none;fill:red; }\ncircle.select_data_SVGID_ { fill:red;stroke:black; }\nline.select_data_SVGID_, polyline.select_data_SVGID_ { fill:none;stroke:red; }\nrect.select_data_SVGID_, polygon.select_data_SVGID_, path.select_data_SVGID_ { fill:red;stroke:none; }\nimage.select_data_SVGID_ { stroke:red; }","type":"multiple","only_shiny":true,"selected":[],"linked":false},"select_inv":{"css":""},"select_key":{"css":".select_key_SVGID_ { fill:red;stroke:black;cursor:pointer; }\ntext.select_key_SVGID_ { stroke:none;fill:red; }\ncircle.select_key_SVGID_ { fill:red;stroke:black; }\nline.select_key_SVGID_, polyline.select_key_SVGID_ { fill:none;stroke:red; }\nrect.select_key_SVGID_, polygon.select_key_SVGID_, path.select_key_SVGID_ { fill:red;stroke:none; }\nimage.select_key_SVGID_ { stroke:red; }","type":"single","only_shiny":true,"selected":[]},"select_theme":{"css":".select_theme_SVGID_ { fill:red;stroke:black;cursor:pointer; }\ntext.select_theme_SVGID_ { stroke:none;fill:red; }\ncircle.select_theme_SVGID_ { fill:red;stroke:black; }\nline.select_theme_SVGID_, polyline.select_theme_SVGID_ { fill:none;stroke:red; }\nrect.select_theme_SVGID_, polygon.select_theme_SVGID_, path.select_theme_SVGID_ { fill:red;stroke:none; }\nimage.select_theme_SVGID_ { stroke:red; }","type":"single","only_shiny":true,"selected":[]},"zoom":{"min":1,"max":1,"duration":300,"default_on":false},"toolbar":{"position":"topright","pngname":"diagram","tooltips":null,"fixed":false,"hidden":[],"delay_over":200,"delay_out":500},"sizing":{"rescale":true,"width":1}}},"evals":[],"jsHooks":[]}
```
