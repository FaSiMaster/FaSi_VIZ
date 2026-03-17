
cumul_plotly <- function(cumul_data, plot_title = NULL, maxd, maxj) {
  # Vergleich Daten
  fig <- cumul_data |> 
    plotly::plot_ly(
      x =~tag, type = "scatter", mode = "lines",
      hoverinfo = "x+y+text",
      hovertemplate = "%{text}: %{y:,.0f}<extra></extra>", #\n%{xaxis.title.text}: %{x|%b %d}
      y = ~Minimum, line = list(color = ktz_palette[32], dash = "dot"),
      text = "Minimum", name = "Minimum", showlegend = T
    ) |> 
    plotly::add_trace(
      y = ~`Quantil 25%`, line = list(color = ktz_palette[23], dash = "dash"),
      text = "Quantil 25%", name = "Quantil 25%", showlegend = T
    ) |> 
    plotly::add_trace(
      y = ~Median, line = list(color = ktz_palette[14], dash = "solid"),
      text = "Median", name = "Median", showlegend = T
    ) |> 
    plotly::add_trace(
      y = ~`Quantil 75%`, line = list(color = ktz_palette[23], dash = "dash"),
      text = "Quantil 75%", name = "Quantil 75%", showlegend = T
    ) |> 
    plotly::add_trace(
      y = ~Maximum, line = list(color = ktz_palette[32], dash = "dot"),
      text = "Maximum", name = "Maximum", showlegend = T
    )
  
  # Prognose Daten
  fig <- fig |>  
    plotly::add_trace(
      y = ~low, line = list(color = "#00000000"),
      hoverlabel = list(bgcolor =  paste0(ktz_palette[4], "10")),
      text = "95% KI niedrig", name = "95% KI", showlegend = F, legendgroup = "95% KI",
      yhoverformat = ",.3f"
    ) |> 
    plotly::add_trace(
      y = ~high, line = list(color = "#00000000"),
      fill = "tonexty", fillcolor = paste0(ktz_palette[4], "10"), 
      text = "95% KI hoch", name = "95% KI", showlegend = T, legendgroup = "95% KI"
    ) |> 
    plotly::add_trace(
      y = ~pred, line = list(color = ktz_palette[4], dash = "dot"),
      text = "Prognose", name = "Prognose", showlegend = T
    ) 
  
  # Laufende Daten
  fig <- fig |> 
    plotly::add_trace(
      # mode = "markers+lines", marker = list(color = "#00000000"),
      y = ~n, line = list(color = ktz_palette[4], dash = "solid", width = 2.5),
      text = "Laufendes Jahr", name = "Laufendes Jahr", showlegend = T
    )
  
  x_start_range <- c(
    as.Date(paste0(maxj + 1, "-01-01")),
    min(
      maxd + lubridate::days(60),
      as.Date(paste0(maxj + 1, "-12-31"))
    )
  )
  
  max_y <- cumul_data |> 
    dplyr::filter(tag == x_start_range[[2]]) |> 
    dplyr::select(is.numeric) |>
    as.numeric() |> 
    max(na.rm = T)
  
  y_start_range <- c(0, 1.05*max_y)
  
  # Layout and config
  fig <- fig|> 
    plotly::layout(
      separators = ".'",
      legend = list(y = 0.5, traceorder = "reversed"),
      xaxis = list(
        title = "Datum", tickformat = "%b %d",
        range = x_start_range
      ),
      yaxis = list(
        title = "Kumulierte Summe", hoverformat = ",.0f",
        range = y_start_range
      ),
      title = list(text = plot_title),
      # modebar = list(remove = list("lasso", "select")),
      hovermode = "x unified"
    ) |> 
    plotly::config(locale = "de-CH")
  
  fig
}

cumul_plotly_by_year <- function(cumul_data, plot_title = NULL) {
  
  cumul_data <- cumul_data |> dplyr::mutate(Jahr = as.factor(Jahr))
  
  fig <- plotly::plot_ly(type = "scatter", mode = "lines",
                         cumul_data, x = ~tag, y = ~n, color = ~Jahr,
                         colors = ktz_palette[1:length(unique(cumul_data$Jahr))]
  )
  
  # Layout and config
  fig <- fig|> 
    plotly::layout(
      separators = ".'",
      legend = list(title = list(text = "Jahr"), y = 0.5),
      xaxis = list(title = "Datum", tickformat = "%b %d"),
      yaxis = list(title = "Kumulierte Summe", hoverformat = ",.0f"),
      title = list(text = plot_title),
      # modebar = list(remove = list("lasso", "select")),
      hovermode = "x unified"
    ) |> 
    plotly::config(locale = "de-CH")
  
  fig
}

cumul_plot_title <- function(kosten, level, schwere, lookback, zone, ioao, faz, maxj) {
  title <- character()
  
  what <- "Unf\u00e4lle"
  modifier <- " "
  
  if(kosten) {
    what <- "Unfallkosten"
    modifier <- " Unfallkosten f\u00fcr "
  }
  
  if(lookback[1] != lookback[2]) lookback_text <- paste0(lookback[1], "-", lookback[2])
  else lookback_text <- lookback[1]
  
  if(level == "Unfall") {
    title <- paste0(
      dplyr::if_else(
        length(schwere) == 0,
        paste("Kumulierte", what),
        paste0("Kumulierte", modifier, stringr::str_flatten_comma(schwere, last = " und "))
      ),
      dplyr::if_else(
        is.null(faz),
        "",
        paste0(" mit Hauptverursacher ", stringr::str_flatten_comma(faz, last = " oder "))
      ), " ",
      maxj + 1,
      " im Vergleich zu ",
      lookback_text
    )
  } else if(level == "Objekt") {
    title <- paste(
      dplyr::if_else(
        length(schwere) == 0,
        "Kumulierte verunfallte",
        paste("Kumulierte", stringr::str_flatten_comma(schwere, last = " und "))
      ),
      dplyr::if_else(
        is.null(faz),
        dplyr::if_else(length(schwere) == 0, "Verkehrsobjekten", "Lenker"),
        paste(
          stringr::str_flatten_comma(faz, last = " und "),
          dplyr::if_else(length(schwere) == 0, "", "Lenker")
        )
      ),
      maxj + 1,
      "im Vergleich zu",
      lookback_text
    )
  } else if(level == "Person") {
    title <- paste0(
      dplyr::if_else(
        length(schwere) == 0,
        "Kumulierte verunfallte",
        paste("Kumulierte", stringr::str_flatten_comma(schwere, last = " und "))
      ), " ",
      dplyr::if_else(
        is.null(faz),
        "Personen",
        paste(stringr::str_flatten_comma(faz, last = " und "), "Fahrer")
      ), " ",
      maxj + 1,
      " im Vergleich zu ",
      lookback_text
    )
  }
  
  if(zone == "Gesamte Kanton") zone <-  NULL
  if(ioao == "Alle") ioao <-  NULL
  
  plus <- paste0(" (",stringr::str_flatten_comma(c(zone, ioao)),")")
  
  plus <- ifelse(plus == " ()", "", plus)
  
  title <- paste0(title, plus)
  
  # wrap long titles
  title <- paste(strwrap(title, width = 85), collapse = "\n")
  
  title
}