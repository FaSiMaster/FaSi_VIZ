
datetime_flatten <- function(datetime, year) {
  lubridate::make_datetime(
    year = year, hour = lubridate::hour(datetime),
    min = lubridate::minute(datetime), sec = lubridate::second(datetime)
  )
}

#' Background Graph for lighting condition
#' @noRd
bg_plotly <- function(start_year, end_year, lat, lng, twilights = F, tz_out = NULL, x_shift = -30, y_shift = -15) {
  
  ref_year <-  end_year
  
  min_date <- lubridate::make_datetime(year = start_year, 1, 1) + lubridate::days(y_shift)
  max_date <- lubridate::make_datetime(year = end_year, 12, 31) + lubridate::days(y_shift)
  
  min_time <- lubridate::make_datetime(year = ref_year) + lubridate::minutes(x_shift)
  max_time <- lubridate::make_datetime(year = ref_year, day = 2) + lubridate::minutes(x_shift)
  
  days <- seq(min_date, max_date, by = "day")
  
  bg_df <- data.frame(date = days) |>
    cbind(sunriset(lat, lng, days, tz_out = tz_out)) |> 
    dplyr::mutate(problematic = F)
  
  if(twilights) {
    bg_df <- bg_df |> 
      cbind(sunriset(lat, lng, days, tz_out = tz_out, h_o_deg = -6, prefix = "civil_")) |> 
      cbind(sunriset(lat, lng, days, tz_out = tz_out, h_o_deg = -12, prefix = "nautical_")) |> 
      cbind(sunriset(lat, lng, days, tz_out = tz_out, h_o_deg = -18, prefix = "astronomical_")) |> 
      dplyr::mutate(problematic = md_date(astronomical_set) > md_date(date))
  }
  
  bg_df <- bg_df |> 
    dplyr::mutate(dplyr::across(!c(date, problematic), ~datetime_flatten(.x, ref_year)))
  
  if(twilights) {
    bg_df <- bg_df |> 
      dplyr::mutate(
        astronomical_set  = dplyr::if_else(
          problematic | astronomical_set >= max_time,
          max_time,
          astronomical_set
        )
      )
  }
  
  night_colors <- colorRamp(c(Infografiken["Dunkelblau"], Infografiken["Blau"]))((0:4)/4)
  night_colors <- rgb(night_colors, maxColorValue = 255)
  
  fig <- bg_df |> 
    dplyr::arrange(date) |> 
    plotly::plot_ly(
      type = "scatter", mode = "lines",
      line = list(color = night_colors[1]),
      x = ~min_time, y = ~date, showlegend = F,
      hoverinfo='skip'
    )
  
  if(twilights) {
    fig <- fig |> 
      plotly::add_trace(
        x = ~astronomical_rise, y = ~date, fill = 'tonextx',
        line = list(color = night_colors[1]),
        fillcolor = night_colors[1]
      ) |> 
      plotly::add_trace(
        x = ~nautical_rise, y = ~date, fill = 'tonextx',
        line = list(color = night_colors[2]),
        fillcolor = night_colors[2]
      ) |> 
      plotly::add_trace(
        x = ~civil_rise, y = ~date, fill = 'tonextx',
        line = list(color = night_colors[3]),
        fillcolor = night_colors[3]
      )
  }
  
  fig <- fig |> 
    plotly::add_trace(
      x = ~rise, y = ~date, fill = 'tonextx',# showlegend = T, name = "Nacht",
      line = list(color = ifelse(twilights, night_colors[4], night_colors[1])),
      fillcolor = ifelse(twilights, night_colors[4], night_colors[1])
    ) |> 
    plotly::add_trace(
      x = ~set, y = ~date, fill = 'tonextx',# showlegend = T, name = "Tag",
      line = list(color = night_colors[5]),
      fillcolor = night_colors[5]
    )
  
  if(twilights) {
    fig <- fig |> 
      plotly::add_trace(
        x = ~civil_set, y = ~date, fill = 'tonextx',
        line = list(color = night_colors[4]),
        fillcolor =  night_colors[4]
      ) |> 
      plotly::add_trace(
        x = ~nautical_set, y = ~date, fill = 'tonextx',
        line = list(color = night_colors[3]),
        fillcolor =  night_colors[3]
      ) |> 
      plotly::add_trace(
        x = ~astronomical_set, y = ~date, fill = 'tonextx',
        line = list(color = night_colors[2]),
        fillcolor =  night_colors[2]
      )
  }
  
  fig |> 
    plotly::add_trace(
      x = ~max_time, y = ~date, fill = 'tonextx',
      line = list(color = night_colors[1]),
      fillcolor = night_colors[1]
    ) |> 
    plotly::layout(
      separators = ".'",
      xaxis = list(
        title = "Stunde",
        range = c(min_time, max_time),
        tickvals = seq(
          min_time + lubridate::minutes(-x_shift), 
          max_time + lubridate::minutes(-x_shift-60), 
          by = "hour"
        ), 
        tickformat = "%H", ticks = ""
      ),
      yaxis = list(
        title = "Monat",
        range = c(min_date, max_date),
        tickvals = seq(
          lubridate::make_date(start_year, 1, 1),
          lubridate::make_date(end_year, 12, 31),
          by = "month"
        ), 
        tickformat = ifelse(start_year == end_year, "%b", "%b %Y"),
        ticks = "", ticksuffix = " "
      )
    ) |>
    plotly::config(
      locale = 'de-ch',
      modeBarButtonsToRemove = c(
        "select2d", "lasso2d", "zoom", "pan", "select", "zoomIn", "zoomOut",
        "autoScale", "hoverClosestCartesian", "hoverCompareCartesian"
      )
    )
}

sunset_plot_title <- function(kosten, level, zeitraum, zone, ioao, schwere, faz) {
  what <- dplyr::case_match(
    level,
    "Unfall" ~ ifelse(kosten, "Unfallkosten", "Anzahl Unf\u00e4lle"),
    "Objekt" ~ "Anzahl verunfallten Verkehrsobjekten",
    "Person" ~ "Anzahl verunfallten Personen"
  )
  
  if(zone == "Gesamte Kanton") zone <-  NULL
  if(ioao == "Alle") ioao <-  NULL
  
  if(zeitraum[1] != zeitraum[2]) zeitraum_text <- paste0(zeitraum[1], "-", zeitraum[2])
  else zeitraum_text <- zeitraum[1]
  
  plus <- paste0(
    " (",
    stringr::str_flatten_comma(c(zeitraum_text, zone, ioao, schwere, faz)),
    ")")
  
  plus <- ifelse(plus == " ()", "", plus)
  
  paste0(what, " nach Monat und Unfallstunde, mit Lichtverhältnis", plus)
}
