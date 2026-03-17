
faz_plot <- function(df) {
  minj <- min(df$Jahr)
  maxj <- max(df$Jahr)
  ktz_colors <- factor_to_ktz_palette(df$faz)
  plot <- df |> 
    add_glm_fit(faz) |> 
    plotly::plot_ly(
      x = ~Jahr, y = ~n, color = ~faz, colors = ktz_colors
    ) |> 
    plotly::add_ribbons(
      ymin = ~low, ymax = ~high, legendgroup = ~faz,
      fillcolor = "#00000010", line = list(color = "#00000000"),
      hoverinfo = "skip", showlegend = F
    ) |>
    plotly::add_trace(
      y = ~pred, type = "scatter", legendgroup = ~faz,
      mode = "lines", line = list(dash = "dash"),
      hoverinfo = "skip", showlegend = F
    ) |> 
    plotly::add_trace(
      text = ~faz, legendgroup = ~faz,
      type = "scatter", mode = "lines+markers",
      marker = marker_style, line = line_style,
      hovertemplate = "<b>%{text}</b>\n%{xaxis.title.text}: %{x}\n%{yaxis.title.text}: %{y}<extra></extra>"
    ) |> 
    plotly::layout(
      separators = ".'",
      xaxis = list(tickvals = minj:maxj),
      yaxis = list(title = "Anzahl", hoverformat = ",.0f"),
      legend = list(y = 0.5, title = list(text = "Beteiligte")),
      modebar = list(remove = list("lasso", "select"))
    ) |>
    plotly::config(locale = 'de-ch')
  plot
}

faz_plot_facet <- function(df, input_schwere) {
  if(length(input_schwere) == 0) input_schwere <- levels(obj_df$schwere)[1:4]
  
  pal <- factor_to_ktz_palette(df$faz)
  
  add_trace <- function(df, title, sl = F) {
    minj <- min(df$Jahr)
    maxj <- max(df$Jahr)
    plotly::plot_ly(
      data = df, 
      legendgroup = ~faz, name = ~faz, showlegend = sl,
      type = "scatter", mode = "lines+markers",
      x = ~Jahr, y = ~n, color = ~faz,
      colors = pal,
      marker = marker_style, line = line_style,
      text = ~faz,
      hovertemplate = paste0(
        "<b>%{text}</b>\n",
        "%{xaxis.title.text}: %{x}\n",
        "Anzahl: %{y}<extra></extra>"
      )
    ) |> 
      plotly::layout(
        annotations = list(
          x = 0.01, y = 1.01,
          xref = "paper", yref = "paper", 
          xanchor = "left",
          yanchor = "bottom",
          showarrow = F,
          text = title$schwere
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
    dplyr::filter(schwere %in% input_schwere) |> 
    dplyr::group_by(schwere) |> 
    # last argument makes it so there is only one legend entry per faz
    dplyr::group_map(
      ~add_trace(.x, .y, as.character(.y$schwere) == input_schwere[[1]])
    ) |> 
    plotly::subplot(nrows = length(input_schwere), shareX = T)
}

faz_plot_title <- function(faz, zone, ioao, schwere, facet) {
  what <- ifelse(
    length(faz) == 1,
    faz,
    "Verkehrsobjekten"
  )
  
  if(zone == "Gesamte Kanton") zone <-  NULL
  if(ioao == "Alle") ioao <-  NULL
  
  extras <- c(zone, ioao)
  
  if(!facet) extras <- c(extras, schwere)
  
  plus <- paste0(
    " (",
    stringr::str_flatten_comma(extras),
    ")"
  )
  
  plus <- ifelse(plus == " ()", "", plus)
  
  if(facet) plus <- paste0(" und Schwere",plus)
  
  paste0("Anzahl verunfallte ", what," nach Jahr", plus)
}
