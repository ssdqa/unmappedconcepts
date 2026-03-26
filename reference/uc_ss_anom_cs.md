# *Single Site, Anomaly Detection, Cross-Sectional*

*Single Site, Anomaly Detection, Cross-Sectional*

## Usage

``` r
uc_ss_anom_cs(process_output, output_col, facet = NULL)
```

## Arguments

- process_output:

  tabular output from `uc_process`

- output_col:

  name of the column from process_output to be used in the analysis. can
  be any of the outlier\_ or prop_outlier\_ columns

- facet:

  fields by which the graph should be facetted

## Value

a bar plot displaying the number of patients, either overall or limited
to patients with at least one unmapped value, who are associated with a
number of unmapped rows that is further away from the mean than the SD
threshold
