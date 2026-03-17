
vs_plot_title <- function(zone, ioao, schwere) {
  what <- "Anzahl der Unfälle nach Hauptverursacher, Beteiligten und Jahr"
  
  if(zone == "Gesamte Kanton") zone <-  NULL
  if(ioao == "Alle") ioao <-  NULL
  
  plus <- paste0(
    " (",
    stringr::str_flatten_comma(c(zone, ioao, schwere)),
    ")"
  )
  
  plus <- ifelse(plus == " ()", "", plus)
  
  paste0(what, plus)
}

vs_plot <- function(df, hur, bet, hur_grouped = T, bet_grouped = T) {
  make_plot <- function(df, name){
    df |> 
      add_glm_fit() |> 
      plotly::plot_ly(
        x = ~Jahr, y = ~n, color = I(faz_to_color(name$hu, hur_grouped))
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
        type = "scatter",  mode = "lines+markers",
        marker = list(color = faz_to_color(name$faz, bet_grouped), size = 10, line = list(width = 3)),
        line = line_style,
        name = paste(name$hu, name$faz),
        hovertemplate = paste0(
          "Hauptverursacher: ", name$hu, "\n",
          "Beteiligt: ", name$faz, "\n",
          "Jahr: %{x}\n",
          "Anzahl: %{y:,.0f}<extra></extra>"),
        hoverlabel = list(bgcolor = faz_to_color(name$hu, hur_grouped))
      )
    # df |> 
    #   plotly::plot_ly(
    #     x = ~Jahr, y = ~n,
    #     type = "scatter",  mode = "lines+markers",
    #     marker = marker_style, line = line_style,
    #     name = paste(name$hu, name$faz),
    #     hovertemplate = paste0(
    #       "Hauptverursacher: ", name$hu, "\n",
    #       "Beteiligt: ", name$faz, "\n",
    #       "Jahr: %{x}\n",
    #       "Anzahl: %{y:,.0f}<extra></extra>")
    #   ) |> 
    #   plotly::layout(
    #     xaxis = list(visible = T, showgrid = T, title = ""),
    #     yaxis = list(visible = T, showgrid = T, title = "")
    #   )
  }
  
  # Annotations ----
  dx <- 0.007 * stringr::str_length(as.character(max(df$n)))
  
  a <- list(
    list(
      x = -dx-0.01, y = 0.5,
      xref = "paper", yref = "paper",
      xanchor = "right", yanchor = "middle",
      text = "Hauptverursacher", textangle = -90,
      showarrow = F
    ),
    list(
      x = 0.5, y = 1.02,
      xref = "paper", yref = "paper",
      xanchor = "center", yanchor = "bottom",
      text = "Beteiligt",
      showarrow = F
    )
  )
  
  v_space <- 1/length(hur)
  
  i <- 0
  for (h in hur) {
    a[[length(a)+1]] <- list(
      x = -dx, y = 1 - v_space/2 - i * v_space,
      xref = "paper", yref = "paper",
      xanchor = "right", yanchor = "middle",
      text = h, textangle = -90,
      showarrow = F
    )
    i = i + 1
  }
  
  h_space <- 1/length(bet)
  
  i <- 0
  for (b in bet) {
    a[[length(a)+1]] <- list(
      x = h_space/2 + i * h_space, y = 1,
      xref = "paper", yref = "paper",
      xanchor = "center", yanchor = "bottom",
      text = b,
      showarrow = F
    )
    i = i + 1
  }
  
  # Plot ----
  df |> 
    dplyr::group_by(hu, faz) |> 
    dplyr::group_map(
      ~make_plot(.x, .y)
    ) |> 
    plotly::subplot(nrows = length(hur), shareX = T) |> 
    plotly::layout(
      separators = ".'",
      showlegend = F,
      annotations = a,
      margin = list(l = 80, r = 80, t = 80, b = 80),
      modebar = list(remove = list("lasso", "select"))
    ) |>
    plotly::config(locale = 'de-ch')
}




