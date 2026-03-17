
cumulUI <- function(id, filters = NULL, maxj) {
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        id = ns("sidebar"), width = sidebar_width,
        # standardFiltersUI(ns("std"), selected = c("zone", "ioao"), filters),
        selectInput(
          ns("level"), "Kategorie",
          choices = c("Unfall", "Objekt", "Person"),
          selected = filters[["level"]], selectize = T
        ),
        checkBox(ns("kosten"), "Unfallkosten"),
        checkBox(ns("by_year"), "Einzelne Jahre", value = filters[["by_year"]]),
        shinyjs::hidden(selectizeInput(
          ns("years"), "Gew\u00fcnschte Jahre",
          choices = (maxj+1):min_jahr,
          selected = c(maxj, maxj+1),
          multiple = T,
          options = list(plugins = list("remove_button"))
        )),
        sliderInput(
          ns("lookback"), "Vergleichszeitraum",
          min = min_jahr, max = maxj, value = c(maxj - 9, maxj),
          sep = "", ticks = F
        ),
        filterUI(
          ns("filter"), selected = c("zone", "ioao"), filters = filters
        )
      ),
      bslib::layout_columns(
        bslib::card(
          bslib::card_header(
            textOutput(ns("plot_title")),
            infoPop(
              title = "Prognose", id = ns("prognose_info"),
              p("Die Prognose wird auf der Grundlage der Vergleichsperiode berechnet."),
              p("Es handelt sich um ein arithmetisches Mittel der Unf\u00e4lle pro Tag \u00fcber die gew\u00fcnschten Vergleichsjahre. Dieser wird dann kumuliert."),
              p("Der 95%-Konfidenzintervall wird aus der Standardabweichung der Stichprobe berechnet. Es wird davon ausgegangen, dass die Verteilung der kumulierten t\u00e4glichen Unf\u00e4lle \u00fcber die Jahre normal ist.")
            ),
            class = "d-flex justify-content-between"
          ),
          add_spinner(plotly::plotlyOutput(ns("cumul_plotly"))),
          full_screen = T
        ),
        bslib::layout_columns(
          bslib::value_box(
            id = ns("current_box"),
            title = paste0("Laufendes Jahr (", maxj + 1, ")"),
            value = textOutput(ns("current_value")),
            showcase = bsicons::bs_icon("graph-up")
          ),
          bslib::value_box(
            id = ns("median_box"),
            title = textOutput(ns("min_max_jahr")),
            value = textOutput(ns("median_value")),
            showcase = bsicons::bs_icon("align-center") # "plus-slash-minus")
          ),
          bslib::card(id = ns("ampel_card"), htmlOutput(ns("ampel"))),
          col_widths = 12
        ),
        col_widths = c(9,3)
      )
    )
  )
}

cumulServer <- function(id, res = \(x) NULL, unfDf, unfNewDf, objDf, objNewDf, perDf, perNewDf, maxDate, maxJahr) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(res(), {
      shinyjs::reset("sidebar")
      shinyjs::hide(id = "years")
    }, ignoreInit = T)
    
    observe({
      shinyjs::toggle(id = "kosten", condition = (input$level == "Unfall"))
    })
    
    observeEvent(input$by_year, {
      shinyjs::toggle(id = "years", condition = (input$by_year))
      shinyjs::toggle(id = "lookback", condition = (input$by_year == F))
      
      shinyjs::toggle(id = "current_box", condition = (input$by_year == F))
      shinyjs::toggle(id = "median_box", condition = (input$by_year == F))
      shinyjs::toggle(id = "ampel_card", condition = (input$by_year == F))
      shinyjs::toggle(id = "prognose_info", condition = (input$by_year == F))
    }, ignoreInit = T)
    
    
    
    # data ----
    
    levelData <- reactive({
      req(input$level)
      d <- level_data(input$level, data = list(unfDf(), objDf(), perDf(), unfNewDf(), objNewDf(), perNewDf()))
      req(!is.null(d), nrow(d) > 0)
      d
    })
    
    reLevel <- reactive({input$level})
    
    filterOut <- filterServer("filter", data = levelData, reactive_level = reLevel, selected = c("zone", "ioao"))
    
    baseData <- reactive({
      base_data <- filterOut$data()
      #req(nrow(base_data) > 0)
      
      if(nrow(base_data) == 0) validate("Keine Basis Daten")
      
      if(!input$by_year) {
        base_data <- base_data |> 
          dplyr::filter(Jahr >= input$lookback[1], Jahr <= input$lookback[2])
      }
      
      
      
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
      level_data(input$level, new = T, data = list(unfDf(), objDf(), perDf(), unfNewDf(), objNewDf(), perNewDf())) 
    })
    
    currentFilterOut <- filterServer("filter", data = currentLevelData, reactive_level = reLevel, selected = c("zone", "ioao"))
    
    currentData <- reactive({
      req(currentLevelData())
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
    
    cumulData <- reactive({
      if(isolate(input$by_year)) {
        cumul_data_by_year_filter(baseData(), currentData(), Jahr %in% input$years, maxd = maxDate(), maxj = maxJahr())
      } else {
        cumul_data_filter(baseData(), currentData(), maxd = maxDate(), maxj = maxJahr())
      }
    })
    
    # output ----
    
    plotTitle <- reactive({
      title <- cumul_plot_title(
        input$kosten, input$level, filterOut$schwere(),
        input$lookback,
        filterOut$zone(),
        filterOut$ioao(),
        filterOut$faz(),
        maxj = maxJahr()
      )
      if(input$by_year){
        title <- stringr::str_replace(
          title,
          "[0-9]+ im Vergleich zu [0-9]+(-[0-9]+)?",
          stringr::str_flatten_comma(input$years, last = " und ")
        )
      }
      title
    })
    
    output$plot_title <- renderText(plotTitle())
    
    output$cumul_plotly <- plotly::renderPlotly({
      if(isolate(input$by_year)){
        cumul_plotly_by_year(cumulData()) |> 
          plotly::config(toImageButtonOptions = list(
            filename = plotTitle()
          ))
      } else {
        cumul_plotly(cumulData(), maxd = maxDate(), maxj = maxJahr()) |> 
          plotly::config(toImageButtonOptions = list(
            filename = plotTitle()
          ))
      }
    })
    
    value <- reactive({
      req(!input$by_year)
      cumulData() |>
        dplyr::filter(tag == maxDate()) |>
        dplyr::pull(n)
    })
    
    quartiles <- reactive({
      if(input$by_year) {
        cumulData() |> 
          dplyr::filter(tag == maxDate(), Jahr != maxJahr()+1) |> 
          dplyr::summarise(
            `Quantil 25%` = quantile(n, 0.25),
            Median = median(n),
            `Quantil 75%` = quantile(n, 0.75)
          ) |> 
          as.numeric() |> 
          dplyr::coalesce(0)
      } else {
        cumulData() |>
          dplyr::filter(tag == maxDate()) |> 
          dplyr::select(`Quantil 25%`, Median, `Quantil 75%`) |> 
          as.numeric() |> 
          dplyr::coalesce(0)
      }
    })
    
    medianValue <- reactive({
      quartiles()[2]
    })
    
    output$current_value <- renderText({
      if(value() < 1e6) format(value(), big.mark = "'")
      else nearest_pow3(value())
    })
    
    output$min_max_jahr <- renderText({
      if(input$lookback[1] != input$lookback[2]) {
        paste0("Median ", input$lookback[1], "-", input$lookback[2])
      } else {
        paste0("Anzahl ",input$lookback[1])
      }
    })
    
    output$median_value <- renderText({
      if(medianValue() < 1e6) format(medianValue(), big.mark = "'", digits = 1)
      else nearest_pow3(medianValue())
    })
    
    arrowType <- reactive({
      req(!input$by_year)
      sens <- 0.1
      ac <- arrow_coeff(cumulData(), maxd = maxDate())
      dplyr::case_when(
        ac-1 > sens                 ~ "arrow-up-right",
        sens >= ac-1 & ac-1 > -sens ~ "arrow-right",
        ac-1 < -sens                ~ "arrow-down-right"
      )
    })
    
    color <- reactive({
      get_ampel_color(value(), quartiles())
    })
    
    output$ampel <- renderUI({
      ampel_html2(color(), icon = arrowType())
    })
  })
}
