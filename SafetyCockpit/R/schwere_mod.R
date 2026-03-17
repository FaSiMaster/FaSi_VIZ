
schwereUI <- function(id, filters = NULL) {
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        id = ns("sidebar"), width = sidebar_width,
        #sfiltersUI(id, filters = filters),
        selectInput(
          ns("level"), "Kategorie",
          choices = c("Unfall", "Objekt", "Person"),
          selected = filters[["level"]], selectize = T
        ),
        checkBox(ns("kosten"), "Unfallkosten"),
        # selectizeInput(
        #   ns("schwere"), label = "Schwere ausw\u00e4hlen",
        #   choices = levels(unf_df$schwere),
        #   selected = translate_schwere(filters[["schwere"]]),
        #   multiple = T,
        #   options = list(plugins = list("remove_button"))
        # ),
        # fazFilterUI(ns("fazfilter1"), selected = filters[["faz"]])
        filterUI(ns("filter"), filters = filters)
      ),
      bslib::card(
        bslib::card_header(
          textOutput(ns("plot_title")),
          infoPop(
            title = "Trendlinie",
            p("Die Trendlinien wurden mit einem verallgemeinerten linearen 
              Modell mit negativer Binomialverteilung berechnet. Die graue 
              Fl\u00e4che entspricht dem 95%-Konfidenzintervall.")
          ),
          class = "d-flex justify-content-between"
        ),
        plotly::plotlyOutput(ns("plot")),
        full_screen = T
      )
    )
  )
}

schwereServer <- function(id, res = \(x) NULL) {
  moduleServer(id, function(input, output, session) {
    observeEvent(res(), {
      shinyjs::reset("sidebar")
    }, ignoreInit = T)
    
    #fazfiltervars <- fazFilterServer("fazfilter1")
    
    observe({
      shinyjs::toggle(id = "kosten", condition = (input$level == "Unfall"))
    })
    
    # observeEvent(input$level, {
    #   prev_schwere <- input$schwere
    #   prev_level <- ifelse(any(stringr::str_detect(prev_schwere, "Unf\u00e4lle")), "Unfall", "")
    #   current_level <- input$level
    #   current_schwere <- translate_schwere(
    #     encode_schwere(prev_schwere, prev_level),
    #     current_level
    #   )
    #   updateSelectizeInput(
    #     session, "schwere",
    #     choices = levels(levelData()$schwere),
    #     selected = current_schwere
    #   )
    # })
    
    levelData <- reactive({
      req(input$level)
      level_data(input$level)
    })
    
    reLevel <- reactive({input$level})
    
    filterOut <- filterServer("filter", data = levelData, reactive_level = reLevel)
    
    # currentLevelData <- reactive({
    #   req(input$level)
    #   tmp <- level_data(input$level, new = T) |> 
    #     dplyr::filter(md_date(datum) <= md_date(max_date))
    # })
    # 
    # filterOut_new <- filterServer("filter", data = currentLevelData, reactive_level = reLevel)
    
    # sfiltersData <- reactive({
    #   condition <- (filterOut$zeitraum()[2]-filterOut$zeitraum) >= 2
    #   shinyFeedback::feedbackWarning(
    #     "zeitraum", show = !condition,
    #     "Bitte wählen Sie einen Zeitraum von mindestens 3 Jahren."
    #   )
    #   req(condition)
    #   sfiltersApply(levelData(), input)
    # })
    # 
    # fazfilterData <- reactive({
    #   fazFilterApply(
    #     sfiltersData(),
    #     fazfiltervars$faz(),
    #     isolate(fazfiltervars$grouped())
    #   )
    # })
    
    schwereData <- reactive({
      condition <- (filterOut$zeitraum()[2] - filterOut$zeitraum()[1]) >= 2
      shinyFeedback::feedbackWarning(
        "zeitraum", show = !condition,
        "Bitte wählen Sie einen Zeitraum von mindestens 3 Jahren."
      )
      req(condition)
      
      level_data <- filterOut$data() #dplyr::bind_rows(filterOut$data(), filterOut_new$data())
      
      #req(nrow(level_data) > 0)
      if(nrow(level_data) == 0) validate("Keine Daten")
      
      minj <- min(level_data$Jahr)
      maxj <- max(level_data$Jahr)
      
      
      
      if(input$kosten) {
        level_data |> 
          dplyr::count(Jahr, schwere, wt = kosten12) |> 
          tidyr::complete(Jahr = minj:maxj, schwere, fill = list(n = 0))
      } else {
        level_data |>
          dplyr::count(Jahr, schwere) |> 
          tidyr::complete(Jahr = minj:maxj, schwere, fill = list(n = 0))
      }
    })
    
    plotTitle <- reactive({
      schwere_plot_title(
        input$level, input$kosten, filterOut$zone(), filterOut$ioao(), filterOut$faz()
      )
    })
    
    output$plot_title <- renderText(plotTitle())
    
    yName <- reactive({
      y_name <- "Anzahl"
      if(length(input$kosten) != 0) {
        y_name <- ifelse(input$kosten & input$level == "Unfall", "Kosten", "Anzahl")
      }
      y_name
    })
    output$plot <- plotly::renderPlotly({
      schwere_plot(schwereData(), isolate(yName()), encode_schwere(filterOut$schwere(), input$level)) |> 
        plotly::config(toImageButtonOptions = list(
            filename = plotTitle()
        ))
    })
  })
}
