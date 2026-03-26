# *Multi-Site, Exploratory, Cross-Sectional*

*Multi-Site, Exploratory, Cross-Sectional*

## Usage

``` r
uc_ms_anom_cs(
  process_output,
  output_col,
  large_n = FALSE,
  large_n_sites = NULL,
  text_wrapping_char = 60
)
```

## Arguments

- process_output:

  tabular output from `uc_process`

- output_col:

  name of the column from process_output to be used in the analysis. can
  be either of the proportion columns

- large_n:

  a boolean indicating whether the large N visualization, intended for a
  high volume of sites, should be used; defaults to FALSE

- large_n_sites:

  a vector of site names that can optionally generate a filtered
  visualization

- text_wrapping_char:

  an integer indicating the length limit for text wrapping on axis text

## Value

a dot plot where the shape of the dot represents whether the point is
anomalous, the color of the dot represents the proportion of unmapped
rows/patients for a given variable, and the size of the dot represents
the mean proportion across all sites

        if there were no groups eligible for analysis, a heat map showing the proportion
        and a dot plot showing each site's average standard deviation away from the mean
        proportion is returned instead
