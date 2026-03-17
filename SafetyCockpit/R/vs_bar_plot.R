vs_bar_plot <- function(df, hur, bet) {
  # browser()
  bar_plot <- function(df, meta){
    df |> 
      plotly::plot_ly(
        type = "bar",
        x = ~name, y = ~value,
        color = ~name, colors = c(ktz_palette[4], ktz_palette[14]),
        name = paste(meta$hu, meta$faz),
        hovertemplate = paste0(
          "Hauptverursacher: ", meta$hu, "\n",
          "Beteiligt: ", meta$faz, "\n",
          "%{x}: %{y:,.0f}<extra></extra>")
      ) |> 
      plotly::layout(
        bargap = 0.1,
        xaxis = list(visible = T, showgrid = F, title = "", range = list(-1.1, 2.1)),
        yaxis = list(visible = T, showgrid = T, title = "")
      )
  }
  
  # Annotations ----
  dx <- 0.007 * stringr::str_length(as.character(max(df$value)))
  
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
      ~bar_plot(.x, .y)
    ) |> 
    plotly::subplot(nrows = length(hur), shareX = T) |> 
    plotly::layout(
      separators = ".'",
      showlegend = F,
      annotations = a,
      margin = list(l = 80, r = 80, t = 40, b = 40)
    ) |>
    plotly::config(locale = 'de-ch')
}
