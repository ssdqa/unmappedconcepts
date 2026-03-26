# *Multi Site, Anomaly Detection, Longitudinal*

*Multi Site, Anomaly Detection, Longitudinal*

## Usage

``` r
uc_ms_anom_la(
  process_output,
  filter_variable = NULL,
  large_n = FALSE,
  large_n_sites = NULL
)
```

## Arguments

- process_output:

  tabular output from `uc_process`

- filter_variable:

  the name(s) of variables that should be included on the plot

- large_n:

  a boolean indicating whether the large N visualization, intended for a
  high volume of sites, should be used; defaults to FALSE

- large_n_sites:

  a vector of site names that can optionally generate a filtered
  visualization

## Value

three graphs:

1.  line graph that shows the smoothed proportion of unmapped concepts
    across time computation with the Euclidean distance associated with
    each line

2.  line graph that shows the raw proportion of unmapped concepts across
    time computation with the Euclidean distance associated with each
    line

3.  a bar graph with the Euclidean distance value for each site, with
    the average proportion as the fill
