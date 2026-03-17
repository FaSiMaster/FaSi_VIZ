
gauge_info <- function(...) {
  infoPop(
    "Die Messuhren stellen die Verteilung der Anzahl Unfälle in den Vergleichsjahren bis zum",
    strftime(max_date, format = "%e. %B")," dar.", br(),
    "Die angegebenen Zahlen sind die Quartile (Minimum, 25%, Median, 75% und
    Maximum), die grosse Zahl in der Mitte entspricht der Anzahl Unfälle im aktuellen Jahr bis zum",
    strftime(max_date, format = "%e. %B"), 
    "mit der prozentualen Abweichung vom Median.", br(),
    "Der Median ist zusätzlich durch eine graue Linie gekennzeichnet.",
    ...,
    options = list(customClass = "mid-info")
  )
}

gaugeUI <- function(id, filters = NULL) {
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        open = F, width = sidebar_width,
        sliderInput(
          ns("lookback"), "Vergleich Period",
          min = min_jahr, max = max_jahr, value = c(max_jahr - 9, max_jahr),
          sep = "", ticks = F
        ),
        standardFiltersUI(ns("sf"), filters = filters, selected = c("zone", "ioao"))
      ),
      bslib::layout_columns(
        col_widths = c(3,3,3,3, 4,4,4, 4,4,4),
          bslib::card(
            bslib::card_header(
              "Kinderunf\u00e4lle (0-14)", gauge_info(),
              class = "d-flex justify-content-between"
            ),
            plotly::plotlyOutput(ns("kinder_gauge"))
          ),
          bslib::card(
            bslib::card_header("Jugendunf\u00e4lle (15-17)", gauge_info(),
                               class = "d-flex justify-content-between"),
            plotly::plotlyOutput(ns("jugend_gauge"))
          ),
          bslib::card(
            bslib::card_header("Junge Erwachsene Unf\u00e4lle (18-24)", gauge_info(),
                               class = "d-flex justify-content-between"),
            plotly::plotlyOutput(ns("junge_erw_gauge"))
          ),
          bslib::card(
            bslib::card_header("Seniorenunf\u00e4lle (65+)", gauge_info(),
                               class = "d-flex justify-content-between"),
            plotly::plotlyOutput(ns("senioren_gauge"))
          ),
          bslib::card(
            bslib::card_header(
              "Schulwegunf\u00e4lle",
              gauge_info(br(), "Hier werden nur Unfälle mit Fahrzweck Schulweg oder Schülertransport berücksichtigt."),
              class = "d-flex justify-content-between"
            ),
            plotly::plotlyOutput(ns("schulweg_gauge"))
          ),
          bslib::card(
            bslib::card_header(
              "Alkoholunf\u00e4lle",
              gauge_info(
                br(), "Hier werden nur Unfälle mit Hauptursache Einwirkung von Alkohol berücksichtigt."
              ),
              class = "d-flex justify-content-between"
            ),
            plotly::plotlyOutput(ns("alk_gauge"))
          ),
          bslib::card(
            bslib::card_header("Geschwindigkeitunf\u00e4lle", gauge_info(),
                               class = "d-flex justify-content-between"),
            plotly::plotlyOutput(ns("geschw_gauge"))
          ),
          bslib::card(
            bslib::card_header(
              "Unf\u00e4lle auf Baustellen",
              gauge_info(
                br(), "Hier werden nur Unfälle mit Hauptursache Untergruppe Geschwindigkeit berücksichtigt."
              ),
              class = "d-flex justify-content-between"
            ),
            plotly::plotlyOutput(ns("baustelle_gauge"))
          ),
          bslib::card(
            bslib::card_header("Unf\u00e4lle auf Fussgängerstreifen", gauge_info(),
                               class = "d-flex justify-content-between"),
            plotly::plotlyOutput(ns("streifen_gauge"))
          ),
          bslib::card(
            bslib::card_header("Baumunf\u00e4lle", gauge_info(
              br(), "Hier werden nur Unfälle mit Baumanprall betrachtet."
              ),
              class = "d-flex justify-content-between"),
            plotly::plotlyOutput(ns("baum_gauge"))
          )
        
      )
    )
  )
}

gaugeServer <- function(id, unfDf, unfNewDf, maxDate, maxJahr) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(maxJahr(), {
      maxj <- maxJahr()
      updateSliderInput(inputId = "lookback", value = c(maxj-9, maxj), max = maxj)
    })
    
    baseData <- standardFiltersServer("sf", df = unfDf, selected = c("zone", "ioao"))$data
    currentData <- standardFiltersServer("sf", df = unfNewDf, selected = c("zone", "ioao"))$data
    
    output$kinder_gauge <- plotly::renderPlotly({
      gauge_plot_filter(
        baseData(), currentData(), 
        kinderunfall,
        minj = input$lookback[1], maxj = input$lookback[2],
        max_date_ = maxDate()
      )
    })
    
    output$jugend_gauge <- plotly::renderPlotly({
      gauge_plot_filter(
        baseData(), currentData(), 
        jugendunfall,
        minj = input$lookback[1], maxj = input$lookback[2],
        max_date_ = maxDate()
      )
    })
    
    output$junge_erw_gauge <- plotly::renderPlotly({
      gauge_plot_filter(
        baseData(), currentData(), 
        junge_erw_unfall,
        minj = input$lookback[1], maxj = input$lookback[2],
        max_date_ = maxDate()
      )
    })
    
    output$senioren_gauge <- plotly::renderPlotly({
      gauge_plot_filter(
        baseData(), currentData(), 
        seniorenunfall,
        minj = input$lookback[1], maxj = input$lookback[2],
        max_date_ = maxDate()
      )
    })
    
    output$alk_gauge <- plotly::renderPlotly({
      gauge_plot_filter(
        baseData(), currentData(), 
        hauptursache == "Einwirkung von Alkohol",
        minj = input$lookback[1], maxj = input$lookback[2],
        max_date_ = maxDate()
      )
    })
    
    output$geschw_gauge <- plotly::renderPlotly({
      gauge_plot_filter(
        baseData(), currentData(), 
        hauptursache_unter_grp == "Geschwindigkeit",
        minj = input$lookback[1], maxj = input$lookback[2],
        max_date_ = maxDate()
      )
    })
    
    output$schulweg_gauge <- plotly::renderPlotly({
      gauge_plot_filter(
        baseData(), currentData(),
        schulweg,
        minj = input$lookback[1], maxj = input$lookback[2],
        max_date_ = maxDate()
      )
    })
    
    output$baustelle_gauge <- plotly::renderPlotly({
      gauge_plot_filter(
        baseData(), currentData(),
        stringr::str_detect(unfallstelle_zus, "Baustelle"),
        minj = input$lookback[1], maxj = input$lookback[2],
        max_date_ = maxDate()
      )
    })
    
    output$streifen_gauge <- plotly::renderPlotly({
      gauge_plot_filter(
        baseData(), currentData(),
        stringr::str_detect(unfallstelle_zus, "Fussg\u00e4ngerstreifen"),
        minj = input$lookback[1], maxj = input$lookback[2],
        max_date_ = maxDate()
      )
    })
    
    output$baum_gauge <- plotly::renderPlotly({
      gauge_plot_filter(
        baseData(), currentData(),
        baum,
        minj = input$lookback[1], maxj = input$lookback[2],
        max_date_ = maxDate()
      )
    })
  })
}
