
schwere_plot <- function(df, y_name, schwere = NULL) {
  
  if(is.null(schwere)) schwere <- c("ss", "lv", "sv", "gt")
  
  minj <- min(df$Jahr)
  maxj <- max(df$Jahr)
  
  base_plot_filter <- function(df, ..., yn = y_name) {
    df |> 
      dplyr::filter(...) |> 
      add_glm_fit(schwere) |> 
      plotly::plot_ly(
        x = ~Jahr, y = ~n, color = ~schwere, colors = schwere_cols
      ) |>
      plotly::add_ribbons(
        ymin = ~low, ymax = ~high,
        fillcolor = "#00000010", line = list(color = "#00000000"),
        hoverinfo = "skip"
      ) |>
      plotly::add_trace(
        y = ~pred, type = "scatter", mode = "lines", line = list(dash = "dash"),
        hoverinfo = "skip"
      ) |> 
      plotly::add_trace(
        type = "scatter", mode = "lines+markers", text = ~schwere,
        marker = marker_style, line = line_style,
        hovertemplate = paste0("<b>%{text}</b>\n%{xaxis.title.text}: %{x}\n",yn,": %{y}<extra></extra>")
      )
  }
  
  add_layout <- function(fig, yn = y_name) {
    fig |> 
      plotly::layout(
        annotations = list(
          x = 0.01, y = 1.01,
          xref = "paper", yref = "paper", 
          xanchor = "left",
          yanchor = "bottom",
          showarrow = F,
          text = ~schwere
          # align = "center"
          # valign = "middle"
        ),
        showlegend = F,
        separators = ".'",
        xaxis = list(tickvals = minj:maxj),
        yaxis = list(title = yn, hoverformat = ",.0f"),
        # legend = list(y = 0.5),
        # legend = list(x = 0.1, y = .9, orientation = "v", xanchor = "right", bgcolor = "#ffffff80"),
        modebar = list(remove = list("lasso", "select"))
      ) |>
      plotly::config(locale = 'de-ch')
  }
  
  plots <- list()
  
  if("ss" %in% schwere) {
    ss <- base_plot_filter(
      df,
      stringr::str_detect(schwere, "(Sachschade)|(nicht verletzt)")
    ) |> 
      add_layout()
    plots[["ss"]] <- ss
  }
  
  if("lv" %in% schwere) {  
    lv <- base_plot_filter(
      df,
      stringr::str_detect(schwere, "[Ll]eicht ?verletzt")
    ) |> 
      add_layout()
    plots[["lv"]] <- lv
  }
  
  if("sv" %in% schwere) {
    sv <- base_plot_filter(
      df,
      stringr::str_detect(schwere, "[Ss]chwer ?verletzt")
    ) |> 
      add_layout()
    plots[["sv"]] <- sv
  }
  
  if("gt" %in% schwere) {
    gt <- base_plot_filter(
      df,
      stringr::str_detect(schwere, "(Get\u00f6tet)|(gestorben)")
    ) |> 
      add_layout()
    plots[["gt"]] <- gt
  }
  
  if("un" %in% schwere) {
    un <- base_plot_filter(
      df,
      stringr::str_detect(schwere, "unbekannt")
    ) |> 
      add_layout()
    plots[["un"]] <- un
  }
  
  if(length(plots) == 0) return(plotly::plotly_empty())
  
  plotly::subplot(plots, nrows = length(plots), shareX = T, margin = 0.02) |> 
    plotly::layout(margin = list(r = 40))
}

schwere_plot_title <- function(level, kosten, zone, ioao, faz) {
  what <- dplyr::case_match(
    level,
    "Unfall" ~ ifelse(kosten, "Unfallkosten", "Anzahl Unf\u00e4lle"),
    "Objekt" ~ "Anzahl verunfallten Verkehrsobjekten",
    "Person" ~ "Anzahl verunfallten Personen"
  )
  
  if(zone == "Gesamte Kanton") zone <-  NULL
  if(ioao == "Alle") ioao <-  NULL
  
  plus <- paste0(" (",stringr::str_flatten_comma(c(zone, ioao, faz)),")")
  
  plus <- ifelse(plus == " ()", "", plus)
  
  paste0(what, " nach Jahr und Schwere", plus)
}
