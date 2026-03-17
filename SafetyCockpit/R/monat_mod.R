
monatUI <- function(id, filters = NULL, maxj) {
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        id = ns("sidebar"), width = sidebar_width,
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
      ),
      bslib::card(
        bslib::card_header(textOutput(ns("plot_title"))),
        add_spinner(plotly::plotlyOutput(ns("monat_plotly"))),
        full_screen = T
      )
    )
  )
}

monatServer <- function(id, res = \(x) NULL, unfDf, unfNewDf, objDf, objNewDf, perDf, perNewDf, maxDate, maxJahr) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(res(), {
      shinyjs::reset("sidebar")
      shinyjs::hide(id = "years")
    })
    
    observe({
      shinyjs::toggle(id = "kosten", condition = (input$level == "Unfall"))
    })
    
    # data ----
    
    levelData <- reactive({
      req(input$level)
      level_data(input$level, data = list(unfDf(), objDf(), perDf(), unfNewDf(), objNewDf(), perNewDf())) |> 
        dplyr::mutate(monat = lubridate::month(datum, label = T, abbr = T))
    })
    
    reLevel <- reactive({input$level})
    
    filterOut <- filterServer("filter", levelData, reactive_level = reLevel, selected = c("zone", "ioao"))
    
    baseData <- reactive({
      #req(nrow(filterOut$data()) > 0)
      
      base_data <- filterOut$data()
      if(nrow(base_data) == 0) validate("Keine Basis Daten")
      
      base_data <- base_data |> 
        dplyr::filter(Jahr >= input$lookback[1], Jahr <= input$lookback[2])
      
      
      
      if(input$kosten) {
        base_data <- base_data |>
          dplyr::mutate(weight = kosten12)
      } else {
        base_data <- base_data |>
          dplyr::mutate(weight = 1)
      }
      
      base_data
    })
    
    currentLevelData <- reactive({
      req(input$level)
      tmp <- level_data(input$level, new = T, list(unfDf(), objDf(), perDf(), unfNewDf(), objNewDf(), perNewDf())) |> 
        dplyr::mutate(monat = lubridate::month(datum, label = T, abbr = T)) #|> 
      
      if (maxJahr() == max_jahr) { 
        tmp <- tmp |> dplyr::filter(lubridate::month(datum) < lubridate::month(maxDate())) 
      } else {
        tmp <- tmp |> dplyr::filter(lubridate::month(datum) <= lubridate::month(maxDate()))
      }
      
      tmp
    })
    
    currentFilterOut <- filterServer("filter", data = currentLevelData, reactive_level = reLevel, selected = c("zone", "ioao"))
    
    currentData <- reactive({
      current_data <- currentFilterOut$data()
      
      if(nrow(current_data) == 0) validate("Keine Aktuelle Daten")
      
      if(input$kosten) {
        current_data <- current_data |>
          dplyr::mutate(weight = kosten12)
      } else {
        current_data <- current_data |>
          dplyr::mutate(weight = 1)
      }
      
      current_data
    })
    
    einzelneData <- reactive({
      einz <- filterOut$data()
      
      if(input$kosten) {
        einz <- einz |>
          dplyr::mutate(weight = kosten12)
      } else {
        einz <- einz |>
          dplyr::mutate(weight = 1)
      }
      
      einz <- einz |> 
      dplyr::filter(Jahr %in% input$years) |> 
      dplyr::count(Jahr, monat, .drop = F, wt = weight) |> 
      dplyr::mutate(Jahr = paste("Jahr", as.character(Jahr)))
    })
    
    monatData <- reactive({
      base <- baseData() |> 
        dplyr::count(Jahr, monat, wt = weight, .drop = F) |>
        dplyr::group_by(monat) |> 
        dplyr::summarise(n = mean(n))
      
      st <- as.Date(paste0(maxJahr()+1, "-01-01"))
      en <- lubridate::floor_date(maxDate(), unit = "month") - lubridate::days(1)
      monaten <- seq(st, en, by = "month") |> 
        lubridate::month(label = T, abbr = T) |> 
        as.character()
      
      laufend <- currentData() |> 
        dplyr::count(monat, name = "laufend", wt = weight, .drop = F) |> 
        tidyr::complete(monat) #|> 
      
      if (maxJahr() == max_jahr) { 
        laufend <- laufend |> dplyr::filter(monat %in% monaten)
      }
      
      base |> 
        dplyr::left_join(laufend, dplyr::join_by(monat))
    })
    
    # output ----
    
    plotTitle <- reactive({
      title <- monat_plot_title(
        input$kosten, input$level, filterOut$schwere(), input$lookback, input$years,
        filterOut$zone(), filterOut$ioao(), filterOut$faz(), maxj = maxJahr()
      )
      title
    })
    
    output$plot_title <- renderText(plotTitle())
    
    output$monat_plotly <- plotly::renderPlotly({
      values <- unique(einzelneData()$Jahr)
      range <- (length(ktz_palette)-length(values)):(length(ktz_palette)-1)
      pal <- setNames(ktz_palette[range], values)
      
      if(length(isolate(input$years)) > 0) {
        plot <- monat_einzelne_plot(monatData(), einzelneData(), pal, isolate(input$lookback), maxj = maxJahr())
      } else {
        plot <- monat_plot(monatData(), pal, isolate(input$lookback), maxj = maxJahr())
      }
      
      plot |> 
        plotly::layout(
          separators = ".'",
          xaxis = list(title = "", tickmode = "array", tickvals = levels(monatData()$monat), ticktext = c("Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez")),
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