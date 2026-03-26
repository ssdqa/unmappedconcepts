# Single Site Anomaly Detection method for UC

Single Site Anomaly Detection method for UC

## Usage

``` r
compute_uc_ssanom(cohort, uc_ptlv_rslt, n_sd = 2)
```

## Arguments

- cohort:

  table of cohort members with at least `site`, `person_id`,
  `start_date`, and `end_date`

- uc_ptlv_rslt:

  patient level results output by `uc_process`

- n_sd:

  numeric indicating the number of standard deviations away from the
  mean that will indicate an outlier (defaults to 2)
