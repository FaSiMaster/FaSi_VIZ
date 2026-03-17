
gauge_plot <- function(quartiles, current_value) {
  quartiles <- round(quartiles)
  
  bar_color <- ifelse(
    current_value <= quartiles["q25"],
    Infografiken["Gr\u00fcn"],
    ifelse(
      current_value <= quartiles["q75"],
      # Infografiken["Orange"],
      ktz_palette[2],
      Infografiken["Rot"]
    )
  )
  
  a_min <- min(quartiles["min"], current_value)
  a_max <- max(quartiles["max"], current_value)
  
  delta <- (a_max - a_min)/8
  
  a_min <- round(a_min - delta)
  a_max <- round(a_max + delta)

  plotly::plot_ly(
    domain = list(x = c(0, 1), y = c(0, 1)),
    value = current_value,
    # title = list(text = df$name),
    type = "indicator",
    mode = "gauge+number+delta",
    delta = list(
      reference = quartiles["q50"],
      increasing = list(color = Infografiken["Rot"]),
      decreasing = list(color = Infografiken["Gr\u00fcn"]),
      relative = TRUE,
      valueformat = ".1%"
    ),
    number = list(valueformat = ",.0f"),
    gauge = list(
      axis = list(
        range = list(a_min, a_max),
        tickvals = c(a_min, unname(quartiles), a_max),
        ticktext = c(
          a_min,
          paste(
            c("min", "q25", "median", "q75", "max"),
            paste0("<b>", quartiles, "</b>"),
            sep = "\n"
          ),
          a_max
        ),
        tickangle = 0
      ),
      bar = list(color = bar_color),
      steps = list(
        list(
          color = AkzentfarbenSoft["Softgrün"],
          range = c(a_min, quartiles["q25"])
        ),
        list(
          color = "#FFF5CC", # AkzentfarbenSoft["Softgelb"],
          range = c(quartiles["q25"], quartiles["q75"])
        ),
        list(
          color = "#ffd5cc", # AkzentfarbenSoft["Softrot"],
          range = c(quartiles["q75"], a_max)
        )
      ),
      threshold = list(
        line = list(color = "grey", width = 4),
        thickness = 0.75,
        value = quartiles["q50"]
      )
    )
  ) |>
    plotly::layout(
      margin = list(r = 60, b = 10, t = 40),
      separators = ".'"
    ) |>
    plotly::config(locale = 'de-ch')
}

gauge_plot_filter <- function(df, new_df, ..., minj = NULL, maxj = NULL, max_date_ = NULL) {
  if(is.null(max_date_)) max_date_ <- max_date
  quartiles <- df |> dplyr::filter(...) |> ampel_summary(T, minj, maxj, max_date_)
  value <-  new_df |> dplyr::filter(..., lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(max_date_)*100 + lubridate::day(max_date)) |> nrow()
  gauge_plot(quartiles, value)
}
