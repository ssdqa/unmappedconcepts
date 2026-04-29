# UC Sample Input File – OMOP

A sample version of the file structure expected for the uc_input_file
parameter in the `uc_process` function. The user should recreate this
file structure and include their own variables.

## Usage

``` r
uc_input_file_omop
```

## Format

### `uc_input_file_omop`

A data frame with 8 columns

- variable:

  A string label for the variable of interest

- domain_tbl:

  The name of the CDM table where the variable can be found

- unmapped_field:

  The field in the domain_tbl that should be evaluated for unmapped
  values

- unmapped_values:

  A comma separated string with values that indicate "unmapped"
  information; NULL values are considered by default.

- concept_field:

  The field in the domain_tbl that should be used to join to the
  codeset; only required when codeset is provided

- date_field:

  The date field in the domain_tbl that should be used to filter the
  dataset to the cohort period and for longitudinal analyses

- codeset_name:

  The name of the codeset as found in the specs directory; file
  extension should not be included

- filter_logic:

  optional; a string to be parsed as logic to filter the default_tbl and
  better identify the variable of interest

## Details

Please note that the codesets should be stored in the
`file_subdirectory` established when `ssdqa.gen::initialize_dq_session`
is executed.

Examples of appropriately structured codeset files are attached to the
ssdqa.gen package and can be accessed with `ssdqa.gen::`
