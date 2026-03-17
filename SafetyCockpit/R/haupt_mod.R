
hauptUI <- function(id, filters = NULL) {
  filters["level"] <- "Unfall"
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        id = ns("sidebar"), width = sidebar_width,
        #sfiltersUI(id, filters = filters),
        checkBox(ns("kosten"), "Unfallkosten"),
        selectizeInput(
          ns("hauptursache"), label = "Hauptursache ausw\u00e4hlen",
          choices = levels(unf_df$hauptursache),
          selected = filters[["hauptursache"]],
          multiple = T,
          options = list(plugins = list("remove_button"))
        ),
        # selectizeInput(
        #   ns("schwere"), label = span("Schwere", bsicons::bs_icon("filter")),
        #   choices = levels(unf_df$schwere),
        #   selected = translate_schwere(filters[["schwere"]], "Unfall"),
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

hauptServer <- function(id, res = \(x) NULL) {
  moduleServer(id, function(input, output, session) {
    observeEvent(res(), {
      shinyjs::reset("sidebar")
    }, ignoreInit = T)
    
    #fazfiltervars <- fazFilterServer("fazfilter1")
    
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
    
    # levelData <- reactive({
      # req(input$level)
      # level_data(input$level)
    # })
    
    # sfiltersData <- reactive({
    #   condition <- (input$zeitraum[[2]]-input$zeitraum[[1]]) >= 2
    #   shinyFeedback::feedbackWarning(
    #     "zeitraum", show = !condition,
    #     "Bitte wählen Sie einen Zeitraum von mindestens 3 Jahren."
    #   )
    #   req(condition)
    #   sfiltersApply(unf_df, input)
    # })
    # 
    # fazfilterData <- reactive({
    #   fazFilterApply(
    #     sfiltersData(),
    #     fazfiltervars$faz(),
    #     isolate(fazfiltervars$grouped())
    #   )
    # })
    
    filterOut <- filterServer("filter", data = unf_df)
    
    hauptData <- reactive({
      
      condition <- (filterOut$zeitraum()[2] - filterOut$zeitraum()[1]) >= 2
      shinyFeedback::feedbackWarning(
        "zeitraum", show = !condition,
        "Bitte wählen Sie einen Zeitraum von mindestens 3 Jahren."
      )
      req(condition)
      
      if(length(input$hauptursache) == 0) {
        validate("Bitte wählen Sie mindestens eine hauptursache")
      }
      
      level_data <- filterOut$data()
      req(nrow(level_data) > 0)
      
      minj <- min(level_data$Jahr)
      maxj <- max(level_data$Jahr)
      
      if (length(input$hauptursache) > 0) {
        level_data <- level_data |> 
          dplyr::filter(hauptursache %in% input$hauptursache)
      }
      
      # if(length(input$schwere) > 0){
      #   level_data <- level_data |>
      #     dplyr::filter(schwere %in% input$schwere)
      # }
      
      if(nrow(level_data) == 0) validate("Keine Daten")
      
      if(input$kosten) {
        level_data |> 
          dplyr::count(Jahr, hauptursache, wt = kosten12) |> 
          tidyr::complete(Jahr = minj:maxj, tidyr::nesting(hauptursache), fill = list(n = 0))
      } else {
        level_data |>
          dplyr::count(Jahr, hauptursache) |> 
          tidyr::complete(Jahr = minj:maxj, tidyr::nesting(hauptursache), fill = list(n = 0))
      }
    })
    
    plotTitle <- reactive({
      haupt_plot_title(
        input$kosten, filterOut$zone(), filterOut$ioao(), filterOut$faz(), filterOut$schwere()
      )
    })
    
    output$plot_title <- renderText(plotTitle())
    
    output$plot <- plotly::renderPlotly({
      if(nrow(hauptData()) == 0) validate("Keine Daten")
      if(sum(hauptData()$n > 0) < 3) validate("Zu wenige Daten")
      haupt_plot_facet(hauptData())
    })
  })
}
