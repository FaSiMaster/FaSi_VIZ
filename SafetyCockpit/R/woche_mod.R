
wocheUI <- function(id, filters = NULL, maxj) {
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        id = ns("sidebar"), width = sidebar_width,
        #sfiltersUI(id, selected = c("zone", "ioao"), filters),
        selectInput(
          ns("level"), "Kategorie",
          choices = c("Unfall", "Objekt", "Person"),
          selected = filters[["level"]], selectize = T
        ),
        checkBox(ns("kosten"), "Unfallkosten"),
        selectizeInput(
          ns("years"), "Einzelne Jahre",
          choices = (maxj):min_jahr,
          selected = c(maxj),
          multiple = T,
          options = list(plugins = list("remove_button"))
        ),
        sliderInput(
          ns("lookback"), "Vergleichszeitraum",
          min = min_jahr, max = maxj, value = c(maxj - 9, maxj),
          sep = "", ticks = F
        ),
        filterUI(ns("filter"), selected = c("zone", "ioao"), filters = filters)
        # selectizeInput(
        #   ns("schwere"), label = span("Schwere", bsicons::bs_icon("filter")),
        #   choices = translate_schwere(
        #     c("ss", "lv", "sv", "gt", "un"), filters[["level"]], na.rm = T
        #   ),
        #   selected = translate_schwere(filters[["schwere"]], filters[["level"]]),
        #   multiple = T,
        #   options = list(plugins = list("remove_button"))
        # ),
        # fazFilterUI(
        #   ns("fazfilter1"), selected = filters[["faz"]], 
        #   label = span("Verkehrsteilnehmende", bsicons::bs_icon("filter"))
        # )
      ),
      bslib::card(
        bslib::card_header(textOutput(ns("plot_title"))),
        add_spinner(plotly::plotlyOutput(ns("woche_plotly"))),
        full_screen = T
      )
    )
  )
}

wocheServer <- function(id, res = \(x) NULL, unfDf, unfNewDf, objDf, objNewDf, perDf, perNewDf, maxDate, maxJahr) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(res(), {
      shinyjs::reset("sidebar")
      shinyjs::hide(id = "years")
    }, ignoreInit = T)
    
    observe({
      shinyjs::toggle(id = "kosten", condition = (input$level == "Unfall"))
    })
    
    #fazfiltervars <- fazFilterServer("fazfilter1")
    
    # Update Schwere input based on level
    # observeEvent(input$level, {
    #   prev_schwere <- input$schwere
    #   prev_level <- dplyr::if_else(any(stringr::str_detect(prev_schwere, "Unf\u00e4lle")), "Unfall", "")
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
    
    # data ----
    
    levelData <- reactive({
      req(input$level)
      level_data(input$level, data = list(unfDf(), objDf(), perDf(), unfNewDf(), objNewDf(), perNewDf())) |> 
        #sfiltersApply(input = input, selected = c("zone", "ioao")) |> 
        dplyr::mutate(isoyear = lubridate::isoyear(datum), isowoche = lubridate::isoweek(datum))
    })
    
    reLevel <- reactive({input$level})
    
    filterOut <- filterServer("filter", levelData, reactive_level = reLevel, selected = c("zone", "ioao"))
    
    baseData <- reactive({
      base_data <- filterOut$data()
      
      # base_data <- fazFilterApply(
      #   base_data, fazfiltervars$faz(), isolate(fazfiltervars$grouped())
      # )
      # 
      # input_schwere <- input$schwere
      # 
      # if(length(input_schwere) == 0) input_schwere <- levels(base_data$schwere)
      # 
      # base_data <- base_data |> 
      #   dplyr::filter(
      #     schwere %in% input_schwere
      #   )
      
      base_data <- base_data |> 
        dplyr::filter(isoyear >= input$lookback[1], isoyear <= input$lookback[2])
      
      if(nrow(base_data) == 0) validate("Keine Basis Daten")
      
      base_data
    })
    
    currentLevelData <- reactive({
      req(input$level)
      tmp <- level_data(input$level, new = T, data = list(unfDf(), objDf(), perDf(), unfNewDf(), objNewDf(), perNewDf())) |> 
        dplyr::mutate(isoyear = lubridate::isoyear(datum), isowoche = lubridate::isoweek(datum)) #|>
      
      if(maxJahr() == max_jahr){
        tmp <- tmp |> dplyr::filter(lubridate::isoweek(datum) <= lubridate::isoweek(lubridate::floor_date(maxDate(), "week", week_start = 1) - lubridate::days(1)))
      } 
      
      tmp
    })
    
    currentFilterOut <- filterServer("filter", data = currentLevelData, reactive_level = reLevel, selected = c("zone", "ioao"))
    
    currentData <- reactive({
      current_data <- currentFilterOut$data()
      
      # current_data <- fazFilterApply(
      #   current_data, fazfiltervars$faz(), isolate(fazfiltervars$grouped())
      # )
      # 
      # input_schwere <- input$schwere
      # 
      # if(length(input_schwere) == 0) input_schwere <- levels(current_data$schwere)
      # 
      # current_data <- current_data |> 
      #   dplyr::filter(
      #     schwere %in% input_schwere
      #   )
      
      if(nrow(current_data) == 0) validate("Keine Aktuelle Daten")
      
      current_data
    })
    
    einzelneData <- reactive({
      req(input$years)
      #req(nrow(filterOut$data()) > 0)
      
      einzelne_data <- filterOut$data()
      
      if(nrow(einzelne_data) == 0) validate("Keine Einzelne Jahre Daten")
      
      einzelne_data <- einzelne_data |> 
        dplyr::filter(isoyear %in% input$years) |> 
        dplyr::group_by(isoyear, isowoche) |> 
        dplyr::summarise(
          n = dplyr::if_else(input$kosten, sum(kosten12), dplyr::n())
        ) |> 
        dplyr::group_by(isoyear) |> 
        dplyr::mutate(max_woche = lubridate::isoweek(as.Date(paste0(isoyear, "-12-28"), format = "%Y-%m-%d"))) |> 
        tidyr::complete(isowoche = 1:dplyr::first(max_woche), fill = list(n = 0)) |>
        dplyr::select(-max_woche) |> 
        dplyr::mutate(isoyear = paste("Jahr", as.character(isoyear)))
      
      
    })
    
    wocheData <- reactive({
        base <- baseData() |> 
          dplyr::filter(isoyear != (maxJahr() + 1)) |> 
          dplyr::group_by(isoyear, isowoche) |>
          dplyr::summarise(
            n = dplyr::if_else(input$kosten, sum(kosten12), dplyr::n())
          ) |>
          dplyr::group_by(isoyear) |>
          dplyr::mutate(max_woche = lubridate::isoweek(as.Date(paste0(isoyear, "-12-28"), format = "%Y-%m-%d"))) |>
          tidyr::complete(isowoche = 1:max(max_woche, na.rm = T), fill = list(n = 0)) |>
          dplyr::select(-max_woche) |> 
          dplyr::group_by(isowoche) |> 
          dplyr::summarise(n = mean(n, na.rm = T))
    })
    
    wocheData_lauf <- reactive({
      week_now <- dplyr::if_else(maxJahr() == max_jahr, 
                                 lubridate::isoweek(lubridate::floor_date(maxDate(), "week", week_start = 1) - lubridate::days(1)), 
                                 lubridate::isoweek(as.Date(paste0(maxJahr() + 1, "-12-28")))
      ) #max(lubridate::isoweek(maxDate()) - 1, 1)
      
      laufend <- currentData() |>
        #dplyr::group_by(isoyear, isowoche) |>
        dplyr::filter(isoyear != (maxJahr() + 2)) |>
        dplyr::group_by(isowoche) |>
        dplyr::summarise(
          laufend = dplyr::if_else(input$kosten, sum(kosten12), dplyr::n())
        ) |> 
        tidyr::complete(isowoche = 1:week_now, fill = list(laufend = 0))
    })
    
    # output ----
    
    plotTitle <- reactive({
      title <- woche_plot_title(
        input$kosten, input$level, filterOut$schwere(), input$lookback, input$years,
        filterOut$zone(), filterOut$ioao(), filterOut$faz(), maxj = maxJahr()
      )
      title
    })
    
    output$plot_title <- renderText(plotTitle())
    
    output$woche_plotly <- plotly::renderPlotly({
      
      if(length(input$years) > 0) {
        values <- unique(einzelneData()$isoyear)
        range <- (length(ktz_palette)-length(values)):(length(ktz_palette)-1)
        pal <- setNames(ktz_palette[range], values)
        plot <- woche_einzelne_plot(wocheData(), wocheData_lauf(), einzelneData(), pal, isolate(input$lookback), maxj = maxJahr())
      } else {
        plot <- woche_plot(wocheData(), wocheData_lauf(), isolate(input$lookback), maxj = maxJahr())
      }
      
      plot |>
        plotly::layout(
          separators = ".'",
          xaxis = list(title = "", tickvals = c(1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50)),
          yaxis = list(title = "", hoverformat = ",.0f"),
          legend = list(y = 0.5, title = NULL),
          modebar = list(remove = list("lasso", "select"))
        ) |>
        plotly::config(locale = 'de-ch') |>
        plotly::config(toImageButtonOptions = list(
          filename = plotTitle()
        ))
      
    })
  })
}