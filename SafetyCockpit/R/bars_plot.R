
unfalltyp_plot <- function(df) {
  df |> 
    dplyr::mutate(
      unfalltyp = stringr::str_wrap(unfalltyp, 20),
      unfalltyp = forcats::fct_inorder(unfalltyp)
    ) |> 
    plotly::plot_ly(
      type = "bar",
      x = ~value, y = ~unfalltyp,
      color = ~name, colors = c(ktz_palette[4], ktz_palette[14]),
      hovertext = ~name,
      hovertemplate = paste0(
        "%{hovertext}\n",
        "Unfalltyp: %{y}\n",
        "Anzahl: %{x:,.0f}<extra></extra>"
      )
    ) |> 
    plotly::layout(
      separators = ".'",
      yaxis = list(title = list(text = NULL), showticklabels = T),
      xaxis = list(title = list(text = NULL)),
      legend = list(orientation = 'h')
    ) |> 
    plotly::config(
      locale = 'de-ch',
      modeBarButtonsToRemove = c(
        "select2d", "lasso2d", "zoom", "pan", "select", "zoomIn", "zoomOut",
        "autoScale", "hoverClosestCartesian", "hoverCompareCartesian"
      )
    )
}

hu_plot <- function(df) {
  df |> 
    dplyr::mutate(
      hauptursache = stringr::str_wrap(hauptursache, 20),
      hauptursache = forcats::fct_inorder(hauptursache)
    ) |> 
    plotly::plot_ly(
      type = "bar",
      x = ~value, y = ~hauptursache,
      color = ~name, colors = c(ktz_palette[4], ktz_palette[14]),
      hovertext = ~name,
      hovertemplate = paste0(
        "%{hovertext}\n",
        "Hauptursache: %{y}\n",
        "Anzahl: %{x:,.0f}<extra></extra>"
      )
    ) |> 
    plotly::layout(
      separators = ".'",
      yaxis = list(title = list(text = NULL), showticklabels = T),
      xaxis = list(title = list(text = NULL)),
      legend = list(orientation = 'h')
    ) |> 
    plotly::config(
      locale = 'de-ch',
      modeBarButtonsToRemove = c(
        "select2d", "lasso2d", "zoom", "pan", "select", "zoomIn", "zoomOut",
        "autoScale", "hoverClosestCartesian", "hoverCompareCartesian"
      )
    )
}

unfallzeit_data <- function(df, new_df, period = "Vergleich Period", max_date_ = NULL) {
  
  if(is.null(max_date_)) max_date_ <- max_date
  
  laufend_name <- if(lubridate::year(max_date_) == max_jahr+1) {
    paste0("Laufendes Jahr")
  } else {
    paste0(lubridate::year(max_date_))
  }
  
  temp <- df |>
    dplyr::filter(lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(max_date_)*100 + lubridate::day(max_date_)) |> 
    dplyr::count(Jahr, unfallzeit = stunde) |> 
    dplyr::filter(!is.na(unfallzeit)) |> 
    dplyr::group_by(unfallzeit) |> 
    dplyr::summarise(n = median(n)) |> 
    dplyr::mutate(name = period)
  
  new_df |>
    dplyr::filter(datum <= max_date_) |> 
    dplyr::mutate(unfallzeit = stunde) |> 
    dplyr::count(unfallzeit) |> 
    dplyr::filter(!is.na(unfallzeit)) |> 
    dplyr::mutate(name = laufend_name) |> 
    rbind(temp) |> 
    dplyr::mutate(name = factor(name, levels = c(laufend_name, period)))
}

unfallzeit_plot <- function(df) {
  df |> 
    plotly::plot_ly(
      type = "bar",
      x = ~unfallzeit, y = ~n, hovertext = ~name,
      color = ~name, colors = c(ktz_palette[4], ktz_palette[14]),
      hovertemplate = paste0(
        "%{hovertext}\n",
        "%{xaxis.title.text}: %{x}\n",
        "Anzahl: %{y:,.0f}<extra></extra>"
      )
    ) |> 
    plotly::layout(
      separators = ".'",
      yaxis = list(title = list(text = NULL)),
      xaxis = list(title = list(text = "Unfallstunde")),
      legend = list(orientation = 'h')
    ) |> 
    plotly::config(
      locale = 'de-ch',
      modeBarButtonsToRemove = c(
        "select2d", "lasso2d", "zoom", "pan", "select", "zoomIn", "zoomOut",
        "autoScale", "hoverClosestCartesian", "hoverCompareCartesian"
      )
    )
}
