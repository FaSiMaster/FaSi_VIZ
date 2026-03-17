
prep_prognose <- function(df) {
  df |> 
    dplyr::mutate(prognose_datum = as.Date(prognose_datum)) |> 
    dplyr::filter(prognose_datum > max_date) |>
    dplyr::group_by(prognose_datum) |> 
    dplyr::filter(erstell_datum == max(erstell_datum, na.rm = T)) |> 
    dplyr::ungroup()
}

prep_real <- function(df, new_df, real_days = 55*7) {
  
  maxd <- max_date
  
  df <- df |> 
    dplyr::filter(datum > maxd - lubridate::days(real_days)) |>
    dplyr::count(datum)
  
  new_df <- new_df |> 
    dplyr::filter(datum <= maxd) |>
    dplyr::count(datum)
  
  df |> rbind(new_df)
}

ml_data <- function(approx = "day", real_days = 55*7, ...) {
  
  maxd <- max_date # stand# max(new_df$datum)
  
  # min(c(stand, min(prognose_df$prognose_datum)))
  
  approx_eoy <- lubridate::floor_date(
    as.Date(paste0(max_jahr, "-12-31")), unit = approx, week_start = 1
  )
  
  approx_maxd <- lubridate::floor_date(
    maxd, unit = approx, week_start = 1
  )
  
  real_df <- prep_real(unf_df, unf_new_df, real_days = real_days) |>  
    dplyr::mutate(
      prognose_datum = lubridate::floor_date(
        datum, unit = approx, week_start = 1
      )
    ) |> 
    dplyr::group_by(prognose_datum) |> 
    dplyr::summarise(n = sum(n)) |> 
    dplyr::mutate(
      n_laufend = dplyr::if_else(prognose_datum >= approx_eoy, n, NA),
      n = dplyr::if_else(prognose_datum <= approx_eoy, n, NA)
    ) |> 
    # drop minimum to avoid incomplete weeks/months
    dplyr::filter(prognose_datum > min(prognose_datum))
  
  prognose_df <- prep_prognose(prognose_df) |> 
    dplyr::mutate(
      prognose_datum = lubridate::floor_date(
        prognose_datum, unit = approx, week_start = 1
      )
    ) |> 
    dplyr::group_by(prognose_datum) |>
    dplyr::summarise(pred = sum(unfaelle)) |> 
    # drop maximum to avoid incomplete weeks/months
    dplyr::filter(prognose_datum < max(prognose_datum))
  
  prognose_df |>
    dplyr::full_join(real_df, dplyr::join_by(prognose_datum)) |> 
    # adds a point to prognose and adjust real value to tie it over
    # sum the values in case the week/month goes over the max_date
    dplyr::mutate(
      n_laufend = dplyr::if_else(
        prognose_datum == approx_maxd,
        n_laufend + dplyr::coalesce(pred, 0),
        n_laufend
      ),
      pred = dplyr::if_else(
        prognose_datum == approx_maxd,
        n_laufend,
        pred
      )
    ) |> 
    dplyr::arrange(prognose_datum)
}
