

woche_plot <- function(df, df2, lookback, maxj) {
  df |> 
    plotly::plot_ly(x = ~isowoche) |> 
    plotly::add_bars(
      name = paste0(
        "Mittel ",
        stringr::str_flatten(lookback, collapse = "-")
      ),
      y = ~n, color = I(ktz_palette[19]),
      hovertemplate = paste0(
        "Mittel ", stringr::str_flatten(lookback, collapse = "-"), 
        ": <b>%{y}<b><br>", "Woche: %{x}<extra></extra>"
      )
    ) |> 
    plotly::add_trace(
      legendrank = 1,
      data = df2,
      name = "Laufendes Jahr",
      type = "scatter", mode = "markers+lines",
      color = I(ktz_palette[4]),
      y = ~laufend, marker = marker_style, line = line_style,
      hoverlabel = list(bgcolor = ktz_palette[4]),
      hovertemplate = paste0("Laufendes Jahr ", maxj + 1 ,": <b>%{y}<b><br>", "Woche: %{x}<extra></extra>")
    )
}

woche_einzelne_plot <- function(df, df2, einzelne_df, palette, lookback, maxj) {
  plotly::plot_ly(x = ~isowoche, colors = palette) |>  
    plotly::add_trace(
      legendrank = 2,
      data = einzelne_df,
      type = "scatter", mode = "markers+lines",
      x =~isowoche, y=~n, color = ~isoyear,
      text = ~isoyear,
      # text = ~n, 
      # textposition = "bottom",
      # texttemplate = '%{y:,.0f}',
      # textfont = list(size = 14),
      marker = list(size = 7, color = "white", line = list(width = 3)), 
      line = list(width = 3),
      hovertemplate = paste0("%{text}: <b>%{y}<b><br>", "Woche: %{x}<extra></extra>")
    ) |> 
    plotly::add_bars(
      legendrank = 3,
      data = df,
      name = paste0(
        "Mittel ",
        stringr::str_flatten(lookback, collapse = "-")
      ),
      y = ~n, color = I(ktz_palette[19]),
      hovertemplate = paste0(
        "Mittel ", stringr::str_flatten(lookback, collapse = "-"), 
        ": <b>%{y}<b><br>", "Woche: %{x}<extra></extra>"
      )
    ) |> 
    plotly::add_trace(
      legendrank = 1,
      data = df2,
      name = paste("Laufendes Jahr", maxj + 1),
      # text = ~laufend,
      # textposition = "top",
      # texttemplate = '%{y:,.0f}',
      # textfont = list(size = 14),
      type = "scatter", mode = "markers+lines",
      color = I(ktz_palette[4]),
      y = ~laufend, marker = marker_style, line = line_style,
      hoverlabel = list(bgcolor = ktz_palette[4]),
      hovertemplate = paste0("Laufendes Jahr ", maxj + 1 ,": <b>%{y}<b><br>", "Woche: %{x}<extra></extra>")
    )
}

woche_plot_title <- function(kosten, level, schwere, lookback, years, zone, ioao, faz, maxj) {
  title <- character()
  
  if(lookback[1] != lookback[2]) lookback_text <- paste0(lookback[1], "-", lookback[2])
  else lookback_text <- lookback[1]
  
  # lookback_text <- paste0(lookback_text, " und ", stringr::str_flatten_comma(years))
  
  if(level == "Unfall") {
    
    what <- "Anzahl Unf\u00e4lle"
    modifier <- ""
    
    if(kosten) {
      what <- "Unfallkosten"
      modifier <- "Unfallkosten f\u00fcr "
    }
    
    title <- paste0(
      dplyr::if_else(
        length(schwere) == 0,
        what,
        paste0(modifier, stringr::str_flatten_comma(schwere, last = " und "))
      ),
      dplyr::if_else(
        is.null(faz),
        "",
        paste0(" mit Hauptverursacher ", stringr::str_flatten_comma(faz, last = " oder "))
      ), " ",
      maxj + 1,
      " im Vergleich zu ",
      lookback_text,
      " nach ISO Woche"
    )
  } else if(level == "Objekt") {
    title <- paste(
      dplyr::if_else(
        length(schwere) == 0,
        "Anzahl verunfallte",
        paste("Anzahl", stringr::str_flatten_comma(schwere, last = " und "))
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
      lookback_text,
      " nach ISO Woche"
    )
  } else if(level == "Person") {
    title <- paste0(
      dplyr::if_else(
        length(schwere) == 0,
        "Anzahl verunfallte",
        paste("Anzhal", stringr::str_flatten_comma(schwere, last = " und "))
      ), " ",
      dplyr::if_else(
        is.null(faz),
        "Personen",
        paste(stringr::str_flatten_comma(faz, last = " und "), "Fahrer")
      ), " ",
      maxj + 1,
      " im Vergleich zu ",
      lookback_text,
      " nach ISO Woche"
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