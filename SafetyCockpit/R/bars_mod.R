
bars_info <- function(..., max_date_ = NULL, max_jahr_ = NULL) {
  if(is.null(max_date_)) max_date_ <- max_date
  if(is.null(max_jahr_)) max_jahr_ <- max_jahr
  
  laufend_name <- ifelse(
    max_jahr_ == max_jahr,
    "im laufenden Jahr",
    paste("im Jahr", max_jahr_+1)
  )
  
  bis_text <- ifelse(
    max_jahr_ == max_jahr,
    paste(
      " bis zum ",
      strftime(max_date_, format = "%e. %B")
    ),
    ""
  )
  
  infoPop(
    paste0(
      "Die Histogramme zeigen die Anzahl der Unfälle ",
      laufend_name,
      " und den Median der Unfälle im Vergleichszeitraum",
      bis_text,"."
    ), br(),
    "Dadurch ist ein aussagekräftiger Vergleich möglich.",
    ...,
    options = list(customClass = "mid-info")
  )
}

barsUI <- function(id, filters = NULL) {
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
        filterUI(ns("filter"), filters = filters, selected = c("zone", "ioao"))
      ),
      bslib::layout_columns(
        col_widths = 6,
        bslib::card(
          bslib::card_header(
            "Anzahl Unfälle nach Unfallstunde",
            uiOutput(ns("bars_info_unfallzeit")),
            class = "d-flex justify-content-between"
          ),
          plotly::plotlyOutput(ns("unfallzeit_plot"))
        ),
        bslib::layout_columns(
          col_widths = 12,
          bslib::card(
            bslib::card_header(
              "Anzahl Unfälle nach Unfalltyp (Top 5)",
              uiOutput(ns("bars_info_unfalltyp")),
              class = "d-flex justify-content-between"
            ),
            plotly::plotlyOutput(ns("unfalltyp_plot"))
          ),
          bslib::card(
            bslib::card_header(
              "Anzahl Unfälle nach Hauptursache (Top 5)",
              uiOutput(ns("bars_info_hu")),
              class = "d-flex justify-content-between"
            ),
            plotly::plotlyOutput(ns("hu_plot"))
          ) 
        )
      )
    )
  )
}

barsServer <- function(id, unfDf, unfNewDf, maxDate, maxJahr) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(maxJahr(), {
      maxj <- maxJahr()
      updateSliderInput(inputId = "lookback", value = c(maxj-9, maxj), max = maxj)
    })
    
    output$bars_info_unfallzeit <- renderUI({
      bars_info(max_date_ = maxDate(), max_jahr_ = maxJahr())
    })
    
    output$bars_info_unfalltyp <- renderUI({
      bars_info(
        max_date_ = maxDate(), max_jahr_ = maxJahr(),
        br(), "Unter Unfalltyp ist hier die Unfalltypengruppe zu verstehen."
      )
    })
    
    output$bars_info_hu <- renderUI({
      bars_info(
        max_date_ = maxDate(), max_jahr_ = maxJahr(),
        br(), "Unter Unfalltyp ist hier die Unfalltypengruppe zu verstehen."
      )
    })
    
    filterOut <- filterServer("filter", data = unfDf, selected = c("zone", "ioao"))$data
    baseData <- reactive({
      filterOut() |>
        dplyr::filter(Jahr >= input$lookback[1], Jahr <= input$lookback[2])
    })
    
    currentData <- filterServer("filter", data = unfNewDf, selected = c("zone", "ioao"))$data
    
    minmax <- reactive(paste0("Median ",input$lookback[1], "-", input$lookback[2]))
    
    unfalltypData <- reactive({
      bars_data(baseData(), currentData(), unfalltyp, minmax(), max_date_ = maxDate())
    })
    
    output$unfalltyp_plot <- plotly::renderPlotly({
      unfalltyp_plot(unfalltypData())
    })
    
    huData <- reactive({
      bars_data(baseData(), currentData(), hauptursache, minmax(), max_date_ = maxDate())
    })
    
    output$hu_plot <- plotly::renderPlotly({
      hu_plot(huData())
    })
    
    unfallzeitData <- reactive({
      unfallzeit_data(
        baseData(), currentData(), 
        period = minmax(), maxDate()
      )
    })
    
    output$unfallzeit_plot <- plotly::renderPlotly({
      unfallzeit_plot(unfallzeitData())
    })
  })
}
