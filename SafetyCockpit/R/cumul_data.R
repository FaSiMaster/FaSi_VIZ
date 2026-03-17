#' Cumulative Prediction
#'
#' Predicts the cumulative number of accidents in the rest of the year based on
#' current year data and old data.
#' 
#' @param df Dataframe with the old accident data.
#' @param new_df Dataframe with the new accident data.
#' @param a Number indicating statistical significance (used for confidence intervals).
#' @noRd
cumul_pred <- function(df, new_df, a = 0.05, print_metrics = F, md2, mj2) {
  minj <- min(df$Jahr)
  maxj <- max(df$Jahr)
  nj <- max(maxj - minj + 1, 2)
  # the max is to avoid division by 0 when there is only one year
  
  # is_small <- nrow(df) < 365.24*(nj)
  # if(is_small) warning("Small data sample")
  
  pred_df <- df |>  
    dplyr::count(Jahr, tag = md_date(datum, mj2 + 1), wt = weight) |>
    tidyr::complete(
      Jahr = minj:maxj,
      tag = seq(
        lubridate::make_date(mj2 + 1,  1,  1), 
        lubridate::make_date(mj2 + 1, 12, 31),
        "day"
      ),
      fill = list(n = 0)
    ) |> 
    dplyr::group_by(tag) |> 
    dplyr::summarise(
      # low = quantile(n, a),
      # pred = median(n),
      pred = mean(n),
      std = sqrt(sum((n - pred)^2) / (nj-1)),
      low = pred - qt(1-a/2, nj-1) * std / sqrt(nj),
      high = pred + qt(1-a/2, nj-1) * std / sqrt(nj),
      # high = quantile(n, 1 - a),
    ) |> 
    # dplyr::filter(tag >= max_date) |> 
    dplyr::select(!std)
  
  join <- new_df |> 
    dplyr::filter(datum <= md2) |>
    dplyr::count(datum, wt = weight) |> 
    dplyr::arrange(datum) |> 
    tidyr::complete(
      datum = seq(
        lubridate::make_date(mj2 + 1,  1,  1), 
        md2,
        "day"
      ),
      fill = list(n = 0)
    ) |> 
    dplyr::full_join(pred_df, dplyr::join_by(datum == tag)) 
  
  if(print_metrics) {
    join |> 
      dplyr::filter(datum < md2) |> 
      dplyr::summarise(
        r2 = 1 - sum((n - pred)^2)/sum((n - mean(n))^2),
        rmse = sqrt(sum((n - pred)^2)/length(!is.na(pred)))
      ) |> 
      print()
  }
  
  join |>
    dplyr::mutate(
      is_pred = datum >= md2,
      dplyr::across(c(pred, low, high), ~dplyr::if_else(is_pred & datum != md2, .x, n)),
      # pred = dplyr::if_else(is_pred, pred, n),
      # low = dplyr::if_else(is_pred, low, n),
      # high = dplyr::if_else(is_pred, high, n),
      n = dplyr::if_else(is_pred, n, dplyr::coalesce(n , 0)),
      low = pmax(low, 0) # no negative prediction
    ) |>
    dplyr::arrange(datum) |> 
    dplyr::mutate(dplyr::across(!c(datum, is_pred), cumsum)) |> 
    dplyr::mutate(dplyr::across(
      c(pred, low, high), 
      ~ dplyr::if_else(is_pred, .x, NA)
    ))
}

cumul_pred_filter <- function(df, new_df, ..., a = 0.05, md, mj) {
  cumul_pred(df |> dplyr::filter(...), new_df |> dplyr::filter(...), a, md2 = md, mj2 = mj)
}

cumul_data <- function(cumul_df, pred_df, a = 0.05, md, mj) {
  
  minj <- min(cumul_df$Jahr)
  maxj <- max(cumul_df$Jahr)
  nj <- maxj - minj + 1
  
  cumul_df <- cumul_df |> 
    dplyr::count(Jahr, tag = md_date(datum, mj + 1), wt = weight) |>
    tidyr::complete(
      Jahr = minj:maxj,
      tag = seq(
        lubridate::make_date(mj + 1,  1,  1), 
        lubridate::make_date(mj + 1, 12, 31),
        "day"
      ),
      fill = list(n = 0)
    ) |> 
    dplyr::group_by(Jahr) |> 
    dplyr::mutate(n = cumsum(n)) |> 
    dplyr::group_by(tag) |> 
    dplyr::summarise(
      Minimum = min(n),
      `Quantil 25%` = quantile(n, .25),
      Median = median(n),
      `Quantil 75%` = quantile(n, .75),
      Maximum = max(n)
    ) |> 
    dplyr::mutate(tag = as.POSIXct(tag))
  
  cumul_df |> dplyr::left_join(pred_df, dplyr::join_by(tag == datum))
  
  # pred_df |>
  #   left_join(cumul_df, join_by(datum == tag)) |>
  #   ggplot(aes(x = datum)) +
  #   geom_ribbon(aes(ymin = low, ymax = high), fill = "#00000005", color = "#E2001A20", linetype = 2) +
  #   geom_line(aes(y = n, color = is_pred, linetype = is_pred)) +
  #   geom_line(aes(y = Median), color = ktz_palette[10]) +
  #   geom_line(aes(y = `Quantile 25%`), color = ktz_palette[19], linetype = 2) +
  #   geom_line(aes(y = `Quantile 75%`), color = ktz_palette[19], linetype = 2) +
  #   geom_line(aes(y = n, linetype = is_pred), color = "#E2001A") +
  #   theme_minimal() +
  #   theme(legend.position = "none")
}

cumul_data_filter <- function(df, new_df, ..., a = 0.05, maxd, maxj) {
  pred_df <- cumul_pred_filter(df, new_df, ..., a = a, md = maxd, mj = maxj)
  cumul_df <- df |> dplyr::filter(...) 
  cumul_data(cumul_df, pred_df, md = maxd, mj = maxj)
}

cumul_data_by_year <- function(df, md, mj) {
  
  if(nrow(df) == 0) return(tibble::tibble(Jahr = integer(), tag = as.Date(NULL), n = numeric()))
  
  if (!"weight" %in% names(df)) df <- df |> dplyr::mutate(weight = 1)
  
  jahrs <- unique(df$Jahr)
  
  maxd <- as.Date(ifelse(
    max(df$datum) > md, 
    md,
    lubridate::make_date(mj + 1, 12, 31)
  ))
  
  df |>
    dplyr::filter(datum <= md) |> 
    dplyr::count(Jahr, tag = md_date(datum, mj + 1), wt = weight) |>
    tidyr::complete(
      Jahr = jahrs,
      tag = seq(
        lubridate::make_date(mj + 1,  1,  1), 
        maxd,
        "day"
      ),
      fill = list(n = 0)
    ) |> 
    dplyr::group_by(Jahr) |> 
    dplyr::mutate(n = cumsum(n)) |> 
    dplyr::ungroup()
}

cumul_data_by_year_filter <- function(df, new_df, ..., maxd, maxj) {
  df <- df |> 
    dplyr::filter(...) |> 
    cumul_data_by_year(md = maxd, mj = maxj)
  
  new_df <- new_df |> 
    dplyr::filter(...) |> 
    cumul_data_by_year(md = maxd, mj = maxj)
  
  df |> rbind(new_df)
}


# Arrows ------------------------------------------------------------------

arrow_coeff <- function(cumul_data, maxd) {
  cumul_data <- cumul_data |>
    dplyr::filter(
      tag >= maxd - lubridate::days(30),
      tag <= maxd
    ) |> 
    dplyr::arrange(tag) |> 
    dplyr::mutate(
      rn = dplyr::row_number()
    )
  
  real_trend <- coef(lm(data = cumul_data, n~rn))[[2]]
  median_trend <- coef(lm(data = cumul_data, Median~rn))[[2]]
  
  coeff <- (real_trend)/(median_trend)
  # message(real_trend)
  # message(median_trend)
  # message(coeff)
  coeff
}
