

ml_plot <- function(data, x_name, x_format) {
  data |> 
    dplyr::mutate(week = paste(prognose_datum, prognose_datum + lubridate::days(6))) |> 
    plotly::plot_ly(
      type = "scatter", mode = "lines",
      x = ~prognose_datum, y = ~pred,
      line = list(color = ktz_palette[1], dash = "dot"),
      name = "Prognose", text = "Prognose",
      hovertemplate = paste0("<b>%{text}</b>\n%{xaxis.title.text}: %{x|",x_format,"}\n%{yaxis.title.text}: %{y}<extra></extra>")
    ) |> 
    plotly::add_trace(
      y = ~n_laufend, line = list(color = ktz_palette[4], dash = "solid"),
      name = "Laufendes Jahr", text = "Laufendes Jahr"
    ) |>
    plotly::add_trace(
      y = ~n, line = list(color = "lightgrey", dash = "solid"),
      name = "Historische Daten", text = "Historische Daten"
    ) |> 
    plotly::layout(
      xaxis = list(title = x_name),
      yaxis = list(title = "Anzahl Unf\u00e4lle"),
      legend = list(y = 0.5)
    ) |> 
    plotly::config(locale = "de-ch") 
}

mlUI <- function(id) {
  ns <- NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      open = F, width = sidebar_width,
      radioButtons(
        ns("approx"), "Zeitgenauigkeit",
        c("Tag" = "day", "Woche" = "week", "Monat" = "month"),
        "week"
      )
    ),
    bslib::card(
      bslib::card_header(
        textOutput(ns("plot_title")),
        infoPop(
          title = "Prognose",
          p("Die Prognose wurde mit einem Random Forest Modell berechnet.
            Als Eingangsdaten werden historische Unfalldaten, Wetterdaten,
            Schulferien und Feiertage verwendet.")
        ),
        class = "d-flex justify-content-between"
      ),
      plotly::plotlyOutput(ns("plot")), full_screen = T
    )
  )
}

mlServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    xName <- reactive({
      switch(
        input$approx,
        "week" = {"Woche"},
        "day" = {"Tag"},
        "month" = {"Monat"}
      )
    })
    
    xFormat <- reactive({
      switch(
        input$approx,
        "week" = {"%V %G"},
        "day" = {"%x"},
        "month" = {"%B '%y"}
      )
    })
    
    plotTitle <- reactive({  
      
      prognose_stand <- paste0(" (Stand: ", strftime(max(prognose_df$erstell_datum), "%d.%m.%Y"),")")
      
      paste0("Anzahl Unfälle nach ", xName(), ", mit 120 Tag Prognose", prognose_stand)
    })
    
    output$plot_title <- renderText(plotTitle())
    
    output$plot <- plotly::renderPlotly({
      ml_plot(ml_data(input$approx),x_name = xName(), x_format = xFormat()) |> 
        plotly::config(toImageButtonOptions = list(
          filename = plotTitle()
        ))
    })
    
  })
}
