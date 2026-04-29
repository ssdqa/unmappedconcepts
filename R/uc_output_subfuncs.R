
#'
#' @import ggplot2
#' @import ggiraph
#' @import gt
#' @importFrom tidyr tibble
#' @importFrom tidyr unite
#' @importFrom qicharts2 qic
#' @importFrom timetk plot_anomalies
#' @importFrom timetk plot_anomalies_decomp
#' @importFrom plotly layout
#' @importFrom graphics text
#' @importFrom patchwork plot_layout
#' @importFrom stats quantile
#' @importFrom stats sd
#'
NULL

#' *Single Site, Exploratory, Cross-Sectional*
#'
#' @param process_output tabular output from `uc_process`
#' @param output_col name of the column from process_output to be used in the analysis.
#'     can be any of the numeric cols, including either proportion col or any of the
#'     median cols
#' @param facet fields by which the graph should be facetted
#'
#' @returns a bar graph displaying either the proportion of unmapped rows/patients or the
#'          median number of unmapped values per patient for each variable
#'
#' @keywords internal
#'
uc_ss_exp_cs <- function(process_output,
                         output_col,
                         facet = NULL){

  if(!output_col %in% c('unmapped_row_prop', 'unmapped_pt_prop',
                        'median_all_with0s', 'median_all_without0s',
                        'median_site_with0s', 'median_site_without0s')){
    cli::cli_abort("Please select a valid output_col: {.code unmapped_row_prop}, {.code unmapped_pt_prop},
                    {.code median_(site/all)_with0s}, {.code median_(site/all)_without0s}")
  }

  if(output_col == 'unmapped_row_prop'){
    xaxis <- 'Prop. Unmapped Rows'
  }else if(output_col == 'unmapped_pt_prop'){
    xaxis <- 'Prop. Unmapped Patients'
  }else if(output_col %in% c('median_all_with0s', 'median_site_with0s')){
    xaxis <- 'Median Unmapped Rows per Patient \n(of All Patients)'
  }else if(output_col %in% c('median_all_without0s', 'median_site_without0s')){
    xaxis <- 'Median Unmapped Rows per Patient \n(of Patients w/ any Unmapped Rows)'
  }

  tbl_use <- process_output %>%
    mutate(tooltip = paste0('Unmapped Pt: ', prettyNum(unmapped_pt, big.mark = ','),
                            '\nUnmapped Row: ', prettyNum(unmapped_rows, big.mark = ','),
                            '\nTotal Pt: ', prettyNum(total_pt, big.mark = ','),
                            '\nTotal Row: ', prettyNum(total_rows, big.mark = ',')))

  plt <- tbl_use %>%
    ggplot(aes(x = !!sym(output_col), y = variable, fill = variable,
               tooltip = tooltip)) +
    geom_col_interactive(show.legend = FALSE) +
    scale_fill_squba() +
    theme_minimal() +
    facet_wrap((facet)) +
    labs(x = xaxis,
         y = 'Variable')

  plt[['metadata']] <- tibble('pkg_backend' = 'ggiraph',
                              'tooltip' = TRUE)

  return(plt)

}



#' *Multi Site, Exploratory, Cross-Sectional*
#'
#' @param process_output tabular output from `uc_process`
#' @param output_col name of the column from process_output to be used in the analysis.
#'     can be either of the proportion columns or either of the median_site_* columns
#' @param filter_variable the name(s) of variables that should be included on the plot
#' @param facet fields by which the graph should be facetted
#' @param large_n a boolean indicating whether the large N visualization, intended for a high
#'                volume of sites, should be used; defaults to FALSE
#' @param large_n_sites a vector of site names that can optionally generate a filtered visualization
#'
#' @returns if a proportion column is selected as the output_col, a heatmap with the proportion
#'     of unmapped values at each site for each variable will be returned. if a median column
#'     is selected, a dot plot comparing site medians (with a star for the all-site median)
#'     for each variable will be returned.
#'
#' @keywords internal
#'
uc_ms_exp_cs <- function(process_output,
                         output_col,
                         filter_variable = NULL,
                         facet = NULL,
                         large_n = FALSE,
                         large_n_sites = NULL){

  if(!output_col %in% c('unmapped_row_prop', 'unmapped_pt_prop',
                        'median_site_with0s', 'median_site_without0s')){
    cli::cli_abort("Please select a valid output_col: {.code unmapped_row_prop}, {.code unmapped_pt_prop},
                    {.code median_site_with0s}, {.code median_site_without0s}")
  }

  if(length(filter_variable) > 5){cli::cli_alert_warning('We recommend limiting to 5 or fewer variables to maintain visibility on the plot')}
  if(is.null(filter_variable)){filter_variable <- process_output %>% distinct(variable) %>% pull()}

  if(output_col == 'unmapped_row_prop'){
    xaxis <- 'Prop. Unmapped Rows'
  }else if(output_col == 'unmapped_pt_prop'){
    xaxis <- 'Prop. Unmapped Patients'
  }else if(output_col == 'median_site_with0s'){
    xaxis <- 'Median Unmapped Rows per Patient \n(of All Patients)'
    comp_var <- 'median_all_with0s'
  }else if(output_col == 'median_site_without0s'){
    xaxis <- 'Median Unmapped Rows per Patient \n(of Patients w/ any Unmapped Rows)'
    comp_var <- 'median_all_without0s'
  }

  tbl_use <- process_output %>%
    mutate(tooltip = paste0('Site: ', site,
                            'Value: ', !!sym(output_col),
                            '\nUnmapped Pt: ', prettyNum(unmapped_pt, big.mark = ','),
                            '\nUnmapped Row: ', prettyNum(unmapped_rows, big.mark = ','),
                            '\nTotal Pt: ', prettyNum(total_pt, big.mark = ','),
                            '\nTotal Row: ', prettyNum(total_rows, big.mark = ',')))

  if(!large_n){
    if(output_col %in% c('unmapped_row_prop', 'unmapped_pt_prop')){
      plt <- tbl_use %>%
        filter(variable %in% filter_variable) %>%
        ggplot(aes(x = variable, y = site, fill = !!sym(output_col),
                   tooltip = tooltip)) +
        geom_tile_interactive() +
        scale_fill_squba(palette = 'diverging', discrete = FALSE) +
        theme_minimal() +
        facet_wrap((facet)) +
        labs(x = 'Variable',
             y = 'Site')
    }else{
      plt <- tbl_use %>%
        filter(variable %in% filter_variable) %>%
        ggplot(aes(x = !!sym(output_col), y = variable, color = site,
                   tooltip = tooltip)) +
        geom_point_interactive(size = 3) +
        geom_point(aes(x = !!sym(comp_var)), shape = 8, color = 'black',
                   size = 3) +
        scale_color_squba() +
        theme_minimal() +
        facet_wrap((facet)) +
        labs(x = xaxis,
             y = 'Site')
    }
  }else{
    if(output_col %in% c('unmapped_row_prop', 'unmapped_pt_prop')){
      summ_stats <- process_output %>%
        filter(variable %in% filter_variable) %>%
        group_by(variable) %>%
        summarise(allsite_median = median(!!sym(output_col)),
                  allsite_q1 = quantile(!!sym(output_col), 0.25),
                  allsite_q3 = quantile(!!sym(output_col), 0.75)) %>%
        pivot_longer(cols = !variable,
                     names_to = 'site',
                     values_to = output_col) %>%
        mutate(site = case_when(site == 'allsite_median' ~ 'All Site Median',
                                site == 'allsite_q1' ~ 'All Site Q1',
                                site == 'allsite_q3' ~ 'All Site Q3')) %>%
        union(process_output %>% filter(site %in% large_n_sites) %>%
                select(site, variable, !!sym(output_col))) %>%
        mutate(tooltip = paste0('Site: ', site,
                                '\nProportion: ', !!sym(output_col)))

      sts <- summ_stats %>% filter(!site %in% c('All Site Median', 'All Site Q1',
                                                'All Site Q3')) %>%
        distinct(site) %>% pull()

      plt <- ggplot(summ_stats %>%
                      mutate(site = factor(site, levels = c('All Site Q1',
                                                            'All Site Median',
                                                            'All Site Q3',
                                                            sts))),
                    aes(x = site, y = variable,
                        fill = !!sym(output_col), tooltip = tooltip)) +
        geom_tile_interactive() +
        geom_vline(xintercept = 3.5, color = 'black') +
        scale_fill_squba(palette = 'diverging', discrete = FALSE) +
        theme_minimal() +
        facet_wrap((facet)) +
        labs(y = 'Variable',
             x = 'Site')
    }else{
      if(!is.null(large_n_sites)){
        plt <- ggplot(process_output %>% filter(site %in% large_n_sites) %>%
                        mutate(tooltip = paste0('Site: ', site,
                                                '\nMedian: ', !!sym(output_col))),
                      aes(y=variable,x=!! sym(output_col))) +
          geom_col(aes(y=variable, x=!! sym(comp_var)), fill="gray")+
          geom_point_interactive(aes(tooltip = tooltip, colour=site), size=3)+
          scale_color_squba() +
          theme_minimal() +
          facet_wrap((facet)) +
          labs(y = 'Variable',
               x = xaxis)
      }else{
        plt <- ggplot(process_output %>%
                        distinct(variable, !!sym(comp_var)) %>%
                        mutate(tooltip = paste0('All Site Median: ', !!sym(comp_var))),
                      aes(y=variable,x=!! sym(comp_var))) +
          geom_col_interactive(aes(tooltip = tooltip), fill = squba_colors_standard[2]) +
          scale_color_squba() +
          theme_minimal() +
          facet_wrap((facet)) +
          labs(y = 'Variable',
               x = xaxis)
      }
    }
  }

  plt[['metadata']] <- tibble('pkg_backend' = 'ggiraph',
                              'tooltip' = TRUE)

  return(plt)

}



#' *Multi-Site, Exploratory, Cross-Sectional*
#'
#' @param process_output tabular output from `uc_process`
#' @param output_col name of the column from process_output to be used in the analysis.
#'     can be either of the proportion columns
#' @param large_n a boolean indicating whether the large N visualization, intended for a high
#'                volume of sites, should be used; defaults to FALSE
#' @param large_n_sites a vector of site names that can optionally generate a filtered visualization
#' @param text_wrapping_char an integer indicating the length limit for text wrapping on axis text
#'
#' @returns a dot plot where the shape of the dot represents whether the point is
#'         anomalous, the color of the dot represents the proportion of unmapped rows/patients
#'         for a given variable, and the size of the dot represents the mean proportion
#'         across all sites
#'
#'         if there were no groups eligible for analysis, a heat map showing the proportion
#'         and a dot plot showing each site's average standard deviation away from the mean
#'         proportion is returned instead
#'
#' @keywords internal
#'
uc_ms_anom_cs <- function(process_output,
                          output_col,
                          large_n = FALSE,
                          large_n_sites = NULL,
                          text_wrapping_char = 60){

  cli::cli_div(theme = list(span.code = list(color = 'blue')))

  if(!output_col %in% c('unmapped_row_prop', 'unmapped_pt_prop')){
    cli::cli_abort("Please select a valid output_col: {.code unmapped_row_prop}, {.code unmapped_pt_prop}")
  }

  if(output_col == 'unmapped_row_prop'){
    title <- 'Row'
  }else{
    title <- 'Patient'
  }

  comparison_col = output_col

  check_n <- process_output %>%
    filter(anomaly_yn != 'no outlier in group')

  dat_to_plot <- process_output %>%
    mutate(text=paste("Variable: ",variable,
                      "\nSite: ",site,
                      "\nProportion: ",round(!!sym(comparison_col),2),
                      "\nMean proportion:",round(mean_val,2),
                      '\nSD: ', round(sd_val,2),
                      "\nMedian proportion: ",round(median_val,2),
                      "\nMAD: ", round(mad_val,2)))

  if(!large_n){
    if(nrow(check_n) > 0){

      dat_to_plot <- dat_to_plot %>% mutate(anomaly_yn = ifelse(anomaly_yn == 'no outlier in group',
                                                                'not outlier', anomaly_yn))

      plt<-ggplot(dat_to_plot,
                  aes(x=site, y=variable, text=text, color=!!sym(comparison_col)))+
        geom_point_interactive(aes(size=mean_val,shape=anomaly_yn, tooltip = text))+
        geom_point_interactive(data = dat_to_plot %>% filter(anomaly_yn == 'not outlier'),
                               aes(size=mean_val,shape=anomaly_yn, tooltip = text), shape = 1, color = 'black')+
        scale_color_squba(palette = 'diverging', discrete = FALSE) +
        scale_shape_manual(values=c(19,8))+
        scale_y_discrete(labels = function(x) stringr::str_wrap(x, width = text_wrapping_char)) +
        theme_minimal() +
        labs(y = "Variable",
             size="",
             title=paste0('Anomalous Unmapped Variables per ', title, ' by Site'),
             subtitle = 'Dot size is the mean proportion per variable') +
        guides(color = guide_colorbar(title = 'Proportion'),
               shape = guide_legend(title = 'Anomaly'),
               size = 'none')

      plt[['metadata']] <- tibble('pkg_backend' = 'ggiraph',
                                  'tooltip' = TRUE)

      return(plt)

    }else{

      plt <- ggplot(dat_to_plot, aes(x = site, y = variable, fill = !!sym(comparison_col),
                                     tooltip = text)) +
        geom_tile_interactive() +
        theme_minimal() +
        scale_fill_squba(discrete = FALSE, palette = 'diverging') +
        labs(y = 'Variable',
             x = 'Site',
             fill = 'Proportion')

      # Test Site Score using SD Computation
      test_site_score <- process_output %>%
        mutate(dist_mean = (!!sym(comparison_col) - mean_val)^2) %>%
        group_by(site) %>%
        summarise(n_grp = n(),
                  dist_mean_sum = sum(dist_mean),
                  overall_sd = sqrt(dist_mean_sum / n_grp)) %>%
        mutate(tooltip = paste0('Site: ', site,
                                '\nStandard Deviation: ', round(overall_sd, 3)))

      ylim_max <- test_site_score %>% filter(overall_sd == max(overall_sd)) %>% pull(overall_sd) + 1
      ylim_min <- test_site_score %>% filter(overall_sd == min(overall_sd)) %>% pull(overall_sd) - 1

      g2 <- ggplot(test_site_score, aes(y = overall_sd, x = site, color = site,
                                        tooltip = tooltip)) +
        geom_point_interactive(show.legend = FALSE) +
        theme_minimal() +
        scale_color_squba() +
        geom_hline(yintercept = 0, linetype = 'solid') +
        labs(title = 'Average Standard Deviation per Site',
             y = 'Average Standard Deviation',
             x = 'Site')

      plt[["metadata"]] <- tibble('pkg_backend' = 'ggiraph',
                                  'tooltip' = TRUE)
      g2[["metadata"]] <- tibble('pkg_backend' = 'ggiraph',
                                 'tooltip' = TRUE)

      opt <- list(plt,
                  g2)

      return(opt)

    }
  }else{
    suppressWarnings(
      far_site <- process_output %>%
        # filter(anomaly_yn != 'no outlier in group') %>%
        mutate(zscr = (!!sym(comparison_col) - mean_val) / sd_val,
               zscr = ifelse(is.nan(zscr), NA, zscr),
               zscr = abs(zscr)) %>%
        group_by(variable) %>%
        filter(zscr == max(zscr, na.rm = TRUE)) %>%
        reframe(farthest_site = site,
                nvar = n())

    )

    if(any(far_site$nvar > 1)){
      far_site <- far_site %>%
        group_by(variable) %>%
        summarise_all(toString) %>% select(-nvar)
    }else{
      far_site <- far_site %>% select(-nvar)
    }

    suppressWarnings(
      close_site <- process_output %>%
        # filter(anomaly_yn != 'no outlier in group') %>%
        mutate(zscr = (!!sym(comparison_col) - mean_val) / sd_val,
               zscr = ifelse(is.nan(zscr), NA, zscr),
               zscr = abs(zscr)) %>%
        group_by(variable) %>%
        filter(zscr == min(zscr, na.rm = TRUE)) %>%
        reframe(closest_site = site,
                nvar = n())
    )

    if(any(close_site$nvar > 1)){
      close_site <- close_site %>%
        group_by(variable) %>%
        summarise_all(toString) %>% select(-nvar)
    }else{
      close_site <- close_site %>% select(-nvar)
    }

    nsite_anom <- process_output %>%
      group_by(variable, anomaly_yn) %>%
      summarise(site_w_anom = n_distinct(site)) %>%
      filter(anomaly_yn == 'outlier') %>%
      ungroup() %>%
      select(-anomaly_yn)

    sitesanoms <- process_output %>%
      filter(anomaly_yn == 'outlier') %>%
      group_by(variable) %>%
      summarise(site_anoms = toString(site)) %>%
      select(variable, site_anoms)

    tbl <- process_output %>%
      group_by(variable) %>%
      mutate(iqr_val = stats::IQR(!!sym(comparison_col))) %>%
      ungroup() %>%
      distinct(variable, mean_val, sd_val, median_val, iqr_val) %>%
      left_join(nsite_anom) %>%
      left_join(sitesanoms) %>%
      left_join(far_site) %>%
      left_join(close_site) %>%
      mutate(delim = sub("^([^,]+,){5}([^,]+).*", "\\2", site_anoms),
             site_anoms = ifelse(site_w_anom > 5,
                                 stringr::str_replace(site_anoms, paste0(",", delim, '(.*)'), ' . . .'),
                                 site_anoms)) %>%
      select(-delim) %>%
      gt::gt() %>%
      tab_header('Large N Anomaly Detection Summary Table') %>%
      cols_label(variable = 'Variable',
                 site_anoms = 'Site(s) with Anomaly',
                 mean_val = 'Mean',
                 sd_val = 'Standard Deviation',
                 median_val = 'Median',
                 iqr_val = 'IQR',
                 site_w_anom = 'No. Sites w/ Anomaly',
                 farthest_site = 'Site(s) Farthest from Mean',
                 closest_site = 'Site(s) Closest to Mean') %>%
      sub_missing(missing_text = 0,
                  columns = site_w_anom) %>%
      sub_missing(missing_text = '--',
                  columns = c(farthest_site, closest_site, site_anoms)) %>%
      fmt_number(columns = c(mean_val, median_val, sd_val, iqr_val),
                 decimals = 3) %>%
      opt_stylize(style = 2)

    if(!is.null(large_n_sites)){
      dat_to_plot <- dat_to_plot %>% mutate(anomaly_yn = ifelse(anomaly_yn == 'no outlier in group',
                                                                'not outlier', anomaly_yn))

      plt<-ggplot(dat_to_plot %>% filter(site %in% large_n_sites),
                  aes(x=site, y=variable, text=text, color=!!sym(comparison_col)))+
        geom_point_interactive(aes(size=mean_val,shape=anomaly_yn, tooltip = text))+
        geom_point_interactive(data = dat_to_plot %>% filter(anomaly_yn == 'not outlier',
                                                             site %in% large_n_sites),
                               aes(size=mean_val,shape=anomaly_yn, tooltip = text), shape = 1, color = 'black')+
        scale_color_squba(palette = 'diverging', discrete = FALSE) +
        scale_shape_manual(values=c(19,8))+
        scale_y_discrete(labels = function(x) stringr::str_wrap(x, width = text_wrapping_char)) +
        theme_minimal() +
        labs(y = "Variable",
             size="",
             title=paste0('Anomalous Unmapped Variables per ', title, ' by Site'),
             subtitle = 'Dot size is the mean proportion per variable') +
        guides(color = guide_colorbar(title = 'Proportion'),
               shape = guide_legend(title = 'Anomaly'),
               size = 'none')

      plt[['metadata']] <- tibble('pkg_backend' = 'ggiraph',
                                  'tooltip' = TRUE)

      opt <- list(plt,
                  tbl)

      return(opt)
    }else{
      return(tbl)
    }
  }

}



#' *Single Site, Anomaly Detection, Cross-Sectional*
#'
#' @param process_output tabular output from `uc_process`
#' @param output_col name of the column from process_output to be used in the analysis.
#'     can be any of the outlier_ or prop_outlier_ columns
#' @param facet fields by which the graph should be facetted
#'
#' @returns a bar plot displaying the number of patients, either overall or
#' limited to patients with at least one unmapped value, who are associated with
#' a number of unmapped rows that is further away from the mean than the SD
#' threshold
#'
#' @keywords internal
uc_ss_anom_cs <- function(process_output,
                          output_col,
                          facet = NULL){

  cli::cli_div(theme = list(span.code = list(color = 'blue')))

  n_sd <- process_output %>% distinct(sd_threshold) %>% pull()

  if(output_col=='outlier_fact'){
    y_title = paste0('Number of Patients with Unmapped Values \n+/- ', n_sd, ' SD Away from Mean')
    x_lab = 'Number of Anomalous Patients with Unmapped Values'
  }else if(output_col=='prop_outlier_fact'){
    y_title = paste0('Proportion of Patients with Unmapped Values \n+/- ', n_sd, ' SD Away from Mean')
    x_lab = 'Proportion of Anomalous Patients with Unmapped Values'
  }else if(output_col=='outlier_tot'){
    y_title = paste0('Number of Total Patients +/- ', n_sd, ' SD Away from Mean')
    x_lab = 'Number of Anomalous Total Patients'
  }else if(output_col=='prop_outlier_tot'){
    y_title = paste0('Proportion of Total Patients +/- ', n_sd, ' SD Away from Mean')
    x_lab = 'Proportion of Anomalous Total Patients'
  }else(cli::cli_abort('Please select a valid output_col: {.code outlier_fact}, {.code prop_outlier_fact}, {.code outlier_tot}, or
             {.code prop_outlier_tot}'))

  plt <- ggplot(process_output,
                aes(x = !!sym(output_col), y = variable, fill = variable)) +
    geom_col(show.legend = FALSE) +
    scale_fill_squba() +
    labs(title = y_title,
         y = 'Variable',
         x = x_lab) +
    theme_minimal() +
    facet_wrap((facet)) +
    theme(panel.grid.major = element_line(linewidth=0.4, linetype = 'solid'),
          panel.grid.minor = element_line(linewidth=0.2, linetype = 'dashed'))

  plt[["metadata"]] <- tibble('pkg_backend' = 'plotly',
                              'tooltip' = FALSE)

  return(plt)

}


#' *Single Site, Exploratory, Longitudinal*
#'
#' @param process_output tabular output from `uc_process`
#' @param output_col name of the column from process_output to be used in the analysis.
#'     can be any of the proportion or median columns
#' @param facet fields by which the graph should be facetted
#'
#' @returns a line graph showing the proportion or median per patient of
#' unmapped concepts per variable across the time series
#'
#' @keywords internal
uc_ss_exp_la <- function(process_output,
                         output_col,
                         facet = NULL){

  cli::cli_div(theme = list(span.code = list(color = 'blue')))

  if(!output_col %in% c('unmapped_row_prop', 'unmapped_pt_prop',
                        'median_site_with0s', 'median_site_without0s',
                        'median_all_with0s', 'median_site_without0s')){
    cli::cli_abort("Please select a valid output_col: {.code unmapped_row_prop}, {.code unmapped_pt_prop},
                    {.code median_(site/all)_with0s}, {.code median_(site/all)_without0s}")
  }

  if(output_col == 'unmapped_row_prop'){
    xaxis <- 'Prop. Unmapped Rows'
  }else if(output_col == 'unmapped_pt_prop'){
    xaxis <- 'Prop. Unmapped Patients'
  }else if(output_col %in% c('median_site_with0s', 'median_all_with0s')){
    xaxis <- 'Median Unmapped Rows per Patient \n(of All Patients)'
  }else if(output_col %in% c('median_site_without0s', 'median_all_without0s')){
    xaxis <- 'Median Unmapped Rows per Patient \n(of Patients w/ any Unmapped Rows)'
  }

  p <- process_output %>%
    ggplot(aes(y = !!sym(output_col), x = time_start, color = variable)) +
    geom_line() +
    scale_color_squba() +
    theme_minimal() +
    facet_wrap((facet)) +
    labs(color = 'Variable',
         y = xaxis,
         x = 'Time')

  p[['metadata']] <- tibble('pkg_backend' = 'plotly',
                            'tooltip' = FALSE)

  return(p)
}


#' *Multi Site, Exploratory, Longitudinal*
#'
#' @param process_output tabular output from `uc_process`
#' @param output_col name of the column from process_output to be used in the analysis.
#'                   can be any of the proportion or either of the median_site_* columns
#' @param filter_variable the name(s) of variables that should be included on the plot
#' @param facet fields by which the graph should be facetted
#' @param large_n a boolean indicating whether the large N visualization, intended for a high
#'                volume of sites, should be used; defaults to FALSE
#' @param large_n_sites a vector of site names that can optionally generate a filtered visualization
#'
#' @returns a line graph showing the proportion or median per patient of
#' unmapped concepts per site & variable across the time series
#'
#' @keywords internal
#'
uc_ms_exp_la <- function(process_output,
                         output_col,
                         filter_variable = NULL,
                         facet = NULL,
                         large_n = FALSE,
                         large_n_sites = NULL){


  cli::cli_div(theme = list(span.code = list(color = 'blue')))

  if(!output_col %in% c('unmapped_row_prop', 'unmapped_pt_prop',
                        'median_site_with0s', 'median_site_without0s')){
    cli::cli_abort("Please select a valid output_col: {.code unmapped_row_prop}, {.code unmapped_pt_prop},
                    {.code median_site_with0s}, {.code median_site_without0s}")
  }

  if(length(filter_variable) > 5){cli::cli_alert_warning('We recommend limiting to 5 or fewer variables to maintain visibility on the plot')}
  if(is.null(filter_variable)){filter_variable <- process_output %>% distinct(variable) %>% pull()}

  facet <- facet %>% append('variable') %>% unique()

  if(output_col == 'unmapped_row_prop'){
    xaxis <- 'Prop. Unmapped Rows'
  }else if(output_col == 'unmapped_pt_prop'){
    xaxis <- 'Prop. Unmapped Patients'
  }else if(output_col == 'median_site_with0s'){
    xaxis <- 'Median Unmapped Rows per Patient \n(of All Patients)'
    comp_var <- 'median_all_with0s'
  }else if(output_col == 'median_site_without0s'){
    xaxis <- 'Median Unmapped Rows per Patient \n(of Patients w/ any Unmapped Rows)'
    comp_var <- 'median_all_without0s'
  }

  if(!large_n){
    p <- process_output %>%
      filter(variable %in% filter_variable) %>%
      ggplot(aes(x = time_start, y = !!sym(output_col), fill = site, color = site)) +
      geom_line() +
      facet_wrap((facet)) +
      theme_minimal() +
      scale_fill_squba() +
      scale_color_squba() +
      labs(x = 'Time',
           y = xaxis)
  }else{

    if(!is.null(large_n_sites)){
      a <- 0.5
      lt <- 'dashed'
    }else{
      a <- 1
      lt <- 'solid'}

    if(grepl('median', output_col)){
      allsite_summs <- process_output %>%
        ungroup() %>%
        filter(variable %in% filter_variable) %>%
        distinct(variable, time_start, !!sym(comp_var)) %>%
        # summarise(allsite_max_med = max(!!sym(output_col)),
        #           allsite_min_med = min(!!sym(output_col))) %>%
        pivot_longer(cols = c(!!sym(comp_var)),
                     names_to = 'site') %>%
        mutate(site = 'All Site Median')
    }else{
      allsite_summs <- process_output %>%
        group_by(variable, time_start) %>%
        summarise(allsite_median = median(!!sym(output_col)),
                  allsite_q1 = quantile(!!sym(output_col), 0.25),
                  allsite_q3 = quantile(!!sym(output_col), 0.75)) %>%
        pivot_longer(cols = c(allsite_median, allsite_q1, allsite_q3),
                     names_to = 'site') %>%
        mutate(site = case_when(site == 'allsite_median' ~ 'All Site Median',
                                site == 'allsite_q1' ~ 'All Site Q1',
                                site == 'allsite_q3' ~ 'All Site Q3'))
    }

    p <- ggplot(allsite_summs, aes(x = time_start, y = value, fill = site, color = site)) +
      geom_line(alpha = a, linetype = lt) +
      facet_wrap((facet)) +
      theme_minimal() +
      scale_fill_squba() +
      scale_color_squba() +
      labs(x = 'Time',
           y = xaxis)

    if(!is.null(large_n_sites)){
      p <- p + geom_line(data = process_output %>% filter(site %in% large_n_sites), aes(y = !!sym(output_col)))
    }


  }

  p[["metadata"]] <- tibble('pkg_backend' = 'plotly',
                            'tooltip' = FALSE)

  return(p)

}



#' *Single Site, Anomaly Detection, Longitudinal*
#'
#' @param process_output tabular output from `uc_process`
#' @param output_col name of the column from process_output to be used in the analysis.
#'                   can be either of the proportion columns
#' @param filter_variable the name(s) of variables that should be included on the plot
#' @param facet fields by which the graph should be facetted
#'
#' @returns if analysis was executed by year or greater, a P Prime control chart
#'          is returned with outliers marked with orange dots
#'
#'          if analysis was executed by month or smaller, an STL regression is
#'          conducted and outliers are marked with red dots. the graphs representing
#'          the data removed in the regression are also returned
#'
#' @keywords internal
uc_ss_anom_la <- function(process_output,
                          output_col = NULL,
                          filter_variable = NULL,
                          facet = NULL){

  cli::cli_div(theme = list(span.code = list(color = 'blue')))

  if(output_col == 'unmapped_row_prop'){
    lv <- 'Rows'
    denom <- 'total_rows'
    num <- 'unmapped_rows'
  }else if(output_col == 'unmapped_pt_prop'){
    lv <- 'Patients'
    denom <- 'total_pt'
    num <- 'unmapped_pt'
  }else{
    cli::cli_abort("Please select a valid output_col: {.code unmapped_row_prop}, {.code unmapped_pt_prop}")
  }

  time_inc <- process_output %>% filter(!is.na(time_increment)) %>% distinct(time_increment) %>% pull()
  facet <- facet %>% append('variable') %>% unique()

  op_w_facet <- process_output %>%
    filter(variable == filter_variable) %>%
    unite(facet_col, !!!syms(facet), sep = '\n') %>%
    mutate(prop = !!sym(output_col),
           num = !!sym(num),
           denom = !!sym(denom))

  if(time_inc == 'year'){

    pp_qi <- qic(data = op_w_facet, x = time_start, y = num, chart = 'pp', facets = ~facet_col,
                 n = denom, title = paste0('Control Chart: Proportion ', lv,' with Unmapped ', filter_variable),
                 ylab = 'Proportion',
                 xlab = 'Time', show.grid = TRUE)

    op_dat <- pp_qi$data

    new_c <- ggplot(op_dat,aes(x, y)) +
      geom_ribbon(aes(ymin = lcl, ymax = ucl), fill = "lightgray",alpha = 0.4) +
      geom_line(colour = squba_colors_standard[[12]], linewidth = .5) +
      geom_line(aes(x, cl)) +
      geom_point(colour = squba_colors_standard[[6]] , fill = squba_colors_standard[[6]], size = 1) +
      geom_point(data = subset(op_dat, y >= ucl), color = squba_colors_standard[[3]], size = 2) +
      geom_point(data = subset(op_dat, y <= lcl), color = squba_colors_standard[[3]], size = 2) +
      facet_wrap(~facet1, scales = 'free_y', ncol = 2) +
      theme_minimal() +
      ggtitle(label = paste0('Control Chart: Proportion ', lv, ' with Unmapped ', filter_variable)) +
      labs(x = 'Time',
           y = 'Proportion')

    new_c[["metadata"]] <- tibble('pkg_backend' = 'plotly',
                                  'tooltip' = FALSE)

    output <- new_c

  }else{

    anomalies <-
      plot_anomalies(.data=process_output %>% filter(variable == filter_variable),
                     .date_var=time_start,
                     .interactive = FALSE,
                     .title = paste0('Anomalous ', lv, ' with Unmapped ', filter_variable, ' Over Time'))

    decomp <-
      plot_anomalies_decomp(.data=process_output %>% filter(variable == filter_variable),
                            .date_var=time_start,
                            .interactive=FALSE,
                            .title = paste0('Anomalous ', lv, ' with Unmapped ', filter_variable, ' Over Time'))

    anomalies[["metadata"]] <- tibble('pkg_backend' = 'plotly',
                                      'tooltip' = FALSE)
    decomp[["metadata"]] <- tibble('pkg_backend' = 'plotly',
                                   'tooltip' = FALSE)

    output <- list(anomalies, decomp)
  }

  return(output)

}


#' *Multi Site, Anomaly Detection, Longitudinal*
#'
#' @param process_output tabular output from `uc_process`
#' @param filter_variable the name(s) of variables that should be included on the plot
#' @param large_n a boolean indicating whether the large N visualization, intended for a high
#'                volume of sites, should be used; defaults to FALSE
#' @param large_n_sites a vector of site names that can optionally generate a filtered visualization
#'
#' @returns three graphs:
#'    1) line graph that shows the smoothed proportion of
#'    unmapped concepts across time computation with the Euclidean distance associated with each line
#'    2) line graph that shows the raw proportion of
#'    unmapped concepts across time computation with the Euclidean distance associated with each line
#'    3) a bar graph with the Euclidean distance value for each site, with the average
#'    proportion as the fill
#'
#' @keywords internal
uc_ms_anom_la <- function(process_output,
                          filter_variable = NULL,
                          large_n = FALSE,
                          large_n_sites = NULL) {


  filt_op <- process_output %>% filter(variable == filter_variable)
  if('unmapped_row_prop' %in% colnames(process_output)){
    lv <- 'Proportion Unmapped Rows'
    col <- 'unmapped_row_prop'
  }else{
    lv <- 'Proportion Patients with Unmapped Rows'
    col <- 'unmapped_pt_prop'
  }

  allsites <-
    filt_op %>%
    select(time_start,variable,mean_allsiteprop) %>% distinct() %>%
    rename(prop=mean_allsiteprop) %>%
    mutate(site='all site average') %>%
    mutate(text_smooth=paste0("Site: ", site,
                              "\n",lv, " ", round(.data$prop, 4)),
           text_raw=paste0("Site: ", site,
                           "\n",lv," ", round(.data$prop, 4)))

  iqr_dat <- filt_op %>%
    select(time_start,variable,!!sym(col)) %>% distinct() %>%
    group_by(time_start,variable) %>%
    summarise(q1 = stats::quantile(!!sym(col), 0.25),
              q3 = stats::quantile(!!sym(col), 0.75))

  dat_to_plot <-
    filt_op %>%
    rename(prop = !!sym(col)) %>%
    mutate(text_smooth=paste0("Site: ", site,
                              "\n","Euclidean Distance from All-Site Mean: ",dist_eucl_mean),
           text_raw=paste0("Site: ", site,
                           "\n","Site Proportion: ", round(.data$prop, 4),
                           "\n","Site Smoothed Proportion: ", site_loess,
                           "\n","Euclidean Distance from All-Site Mean: ", dist_eucl_mean))

  if(!large_n){
    p <- dat_to_plot %>%
      ggplot(aes(y = .data$prop, x = time_start, color = site, group = site, text = .data$text_smooth)) +
      geom_line(data=allsites, linewidth=1.1) +
      geom_smooth(se=TRUE,alpha=0.1,linewidth=0.5, formula = y ~ x) +
      scale_color_squba() +
      theme_minimal() +
      labs(y = 'Proportion \n(Loess)',
           x = 'Time',
           title = paste0('Smoothed ', lv, ' - ', filter_variable, ' Across Time'))

    q <- dat_to_plot %>%
      ggplot(aes(y = .data$prop, x = time_start, color = site,
                 group=site, text=.data$text_raw)) +
      geom_line(data=allsites,linewidth=1.1) +
      geom_line(linewidth=0.2) +
      scale_color_squba() +
      theme_minimal() +
      labs(x = 'Time',
           y = 'Proportion',
           title = paste0(lv, ' - ', filter_variable, ' Across Time'))

    t <- dat_to_plot %>%
      distinct(site, dist_eucl_mean, site_loess) %>%
      group_by(site, dist_eucl_mean) %>%
      summarise(mean_site_loess = mean(site_loess)) %>%
      mutate(tooltip = paste0('Site: ', site,
                              '\nEuclidean Distance: ', dist_eucl_mean,
                              '\nAverage Loess Proportion: ', .data$mean_site_loess)) %>%
      ggplot(aes(x = site, y = dist_eucl_mean, fill = .data$mean_site_loess, tooltip = .data$tooltip)) +
      geom_segment(aes(x = site, xend = site, y = 0, yend = dist_eucl_mean), color = 'navy') +
      geom_point_interactive(aes(fill = mean_site_loess), shape = 21, size = 4) +
      coord_radial(r.axis.inside = FALSE, rotate.angle = TRUE) +
      guides(theta = guide_axis_theta(angle = 0)) +
      theme_minimal() +
      scale_fill_squba(palette = 'diverging', discrete = FALSE) +
      labs(fill = 'Avg. Proportion \n(Loess)',
           y ='Euclidean Distance',
           x = '',
           title = paste0('Euclidean Distance for ', filter_variable))

    p[['metadata']] <- tibble('pkg_backend' = 'plotly',
                              'tooltip' = TRUE)

    q[['metadata']] <- tibble('pkg_backend' = 'plotly',
                              'tooltip' = TRUE)

    t[['metadata']] <- tibble('pkg_backend' = 'ggiraph',
                              'tooltip' = TRUE)

    output <- list(p,q,t)
  }else{
    q <- ggplot(allsites, aes(x = time_start)) +
      geom_ribbon(data = iqr_dat, aes(ymin = q1, ymax = q3), alpha = 0.2) +
      geom_line(aes(y = prop, color = site, group = site), linewidth=1.1) +
      geom_point_interactive(aes(y = prop, color = site, group = site, tooltip=text_raw)) +
      theme_minimal() +
      scale_color_squba() +
      labs(x = 'Time',
           y = 'Proportion',
           title = paste0(lv, ' - ', filter_variable, ' Across Time'),
           subtitle = 'Ribbon boundaries are IQR')

    if(is.null(large_n_sites)){

      t <- dat_to_plot %>%
        distinct(variable, dist_eucl_mean) %>%
        ggplot(aes(x = dist_eucl_mean, y = variable)) +
        geom_boxplot() +
        geom_point_interactive(color = 'gray',
                               alpha = 0.75, aes(tooltip = dist_eucl_mean)) +
        theme_minimal() +
        theme(axis.text.y = element_blank(),
              legend.title = element_blank()) +
        scale_fill_squba(palette = 'diverging', discrete = FALSE) +
        labs(x ='Euclidean Distance',
             y = '',
             title = paste0('Distribution of Euclidean Distances'))

    }else{

      q <- q + geom_line(data = dat_to_plot %>% filter(site %in% large_n_sites),
                         aes(y = prop, color = site, group = site),
                         linewidth=0.2) +
        geom_point_interactive(data = dat_to_plot %>% filter(site %in% large_n_sites),
                               aes(y = prop, color = site, group = site, tooltip=text_raw))

      t <- dat_to_plot %>%
        distinct(variable, dist_eucl_mean) %>%
        ggplot(aes(x = dist_eucl_mean, y = variable)) +
        geom_boxplot() +
        geom_point_interactive(data = dat_to_plot %>% filter(site %in% large_n_sites),
                               aes(color = site, tooltip = dist_eucl_mean)) +
        theme_minimal() +
        theme(axis.text.y = element_blank(),
              legend.title = element_blank()) +
        scale_fill_squba(palette = 'diverging', discrete = FALSE) +
        scale_color_squba() +
        labs(x ='Euclidean Distance',
             y = '',
             title = paste0('Distribution of Euclidean Distances'))
    }

    q[['metadata']] <- tibble('pkg_backend' = 'ggiraph',
                              'tooltip' = TRUE)
    t[['metadata']] <- tibble('pkg_backend' = 'ggiraph',
                              'tooltip' = TRUE)

    output <- q + t + plot_layout(ncol = 1, heights = c(5, 1))
  }

  return(output)

}
