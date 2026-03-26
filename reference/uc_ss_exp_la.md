# *Single Site, Exploratory, Longitudinal*

*Single Site, Exploratory, Longitudinal*

## Usage

``` r
uc_ss_exp_la(process_output, output_col, facet = NULL)
```

## Arguments

- process_output:

  tabular output from `uc_process`

- output_col:

  name of the column from process_output to be used in the analysis. can
  be any of the proportion or median columns

- facet:

  fields by which the graph should be facetted

## Value

a line graph showing the proportion or median per patient of unmapped
concepts per variable across the time series
