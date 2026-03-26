# *Single Site, Exploratory, Cross-Sectional*

*Single Site, Exploratory, Cross-Sectional*

## Usage

``` r
uc_ss_exp_cs(process_output, output_col, facet = NULL)
```

## Arguments

- process_output:

  tabular output from `uc_process`

- output_col:

  name of the column from process_output to be used in the analysis. can
  be any of the numeric cols, including either proportion col or any of
  the median cols

- facet:

  fields by which the graph should be facetted

## Value

a bar graph displaying either the proportion of unmapped rows/patients
or the median number of unmapped values per patient for each variable
