# *Multi Site, Exploratory, Longitudinal*

*Multi Site, Exploratory, Longitudinal*

## Usage

``` r
uc_ms_exp_la(
  process_output,
  output_col,
  filter_variable = NULL,
  facet = NULL,
  large_n = FALSE,
  large_n_sites = NULL
)
```

## Arguments

- process_output:

  tabular output from `uc_process`

- output_col:

  name of the column from process_output to be used in the analysis. can
  be any of the proportion or either of the median_site\_\* columns

- filter_variable:

  the name(s) of variables that should be included on the plot

- facet:

  fields by which the graph should be facetted

- large_n:

  a boolean indicating whether the large N visualization, intended for a
  high volume of sites, should be used; defaults to FALSE

- large_n_sites:

  a vector of site names that can optionally generate a filtered
  visualization

## Value

a line graph showing the proportion or median per patient of unmapped
concepts per site & variable across the time series
