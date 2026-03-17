
haupt_plot_facet <- function(df) {
  
  lvls <- levels(df$hauptursache)
  pal <- setNames(c(ktz_palette, ktz_palette, ktz_palette, ktz_palette)[1:length(lvls)], lvls)
  
  add_trace <- function(df, title) {
    
    minj <- min(df$Jahr)
    maxj <- max(df$Jahr)
    
    df |> 
      add_glm_fit() |> 
      plotly::plot_ly(
        x = ~Jahr, y = ~n, color = title$hauptursache, colors = pal, showlegend = F
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
        name = title$hauptursache,
        type = "scatter", mode = "lines+markers",
        marker = marker_style, line = line_style,
        text = title$hauptursache,
        hovertemplate = paste0(
          "<b>%{text}</b>\n",
          "%{xaxis.title.text}: %{x}\n",
          "Anzahl: %{y}<extra></extra>"
        )
      )|> 
      plotly::layout(
        annotations = list(
          x = 0.01, y = 1.01,
          xref = "paper", yref = "paper", 
          xanchor = "left",
          yanchor = "bottom",
          showarrow = F,
          text = title$hauptursache
        ),
        separators = ".'",
        xaxis = list(tickvals = minj:maxj),
        yaxis = list(title = "Anzahl", hoverformat = ",.0f"),
        legend = list(y = 0.5, title = list(text = "Beteiligte")),
        modebar = list(remove = list("lasso", "select"))
      ) |>
      plotly::config(locale = 'de-ch')
  }
  df |> 
    dplyr::group_by(hauptursache) |> 
    dplyr::group_map(
      ~add_trace(.x, .y)
    ) |> 
    plotly::subplot(nrows = length(unique(df$hauptursache)), shareX = T)
}

haupt_plot_title <- function(kosten, zone, ioao, faz, schwere) {
  what <- ifelse(kosten, "Unfallkosten", "Anzahl Unf\u00e4lle")
  
  if(zone == "Gesamte Kanton") zone <-  NULL
  if(ioao == "Alle") ioao <-  NULL
  
  plus <- paste0(" (",stringr::str_flatten_comma(c(zone, ioao, faz, schwere)),")")
  
  plus <- ifelse(plus == " ()", "", plus)
  
  paste0(what, " nach Jahr und Hauptursache", plus)
}
