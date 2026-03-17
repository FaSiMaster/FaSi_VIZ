vsBarUI <- function(id, filters = NULL) {
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
        fazFilterUI(
          ns("hur"),
          selected = c("Personenwagen", "Motorrad", "Fahrrad", "Fussgänger"),
          label = "Hauptverursacher wählen" 
        ),
        fazFilterUI(
          ns("bet"),
          selected =  c("Personenwagen", "Motorrad", "Fahrrad", "Fussgänger"),
          label = "Beteiligte wählen" 
        ),
        standardFiltersUI(ns("sf"), filters = filters, selected = c("zone", "ioao"))
      ),
      bslib::card(
        bslib::card_header(
          textOutput(ns("plot_title")),
          uiOutput(ns("bars_info")),
          class = "d-flex justify-content-between"
        ),
        plotly::plotlyOutput(ns("vs_bar_plot"))
      )
    )
  )
}

vsBarServer <- function(id, objDf, objNewDf, maxDate, maxJahr) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(maxJahr(), {
      maxj <- maxJahr()
      updateSliderInput(inputId = "lookback", value = c(maxj-9, maxj), max = maxj)
    })
    
    output$bars_info <- renderUI({
      bars_info(max_date_ = maxDate(), max_jahr_ = maxJahr())
    })
    
    huDf <- reactive({
      hu_df <- objDf() |> 
        dplyr::filter(hauptverursacher) |> 
        dplyr::select(
          unf_uid,
          hur = fahrzeugart,
          hur_grp = fahrzeugart_grp
        )
      
      objDf() |> 
        dplyr::left_join(hu_df, dplyr::join_by(unf_uid))
    })
    
    huNewDf <- reactive({
      hu_new_df <- objNewDf() |> 
        dplyr::filter(hauptverursacher) |> 
        dplyr::select(
          unf_uid,
          hur = fahrzeugart,
          hur_grp = fahrzeugart_grp
        )
      
      objNewDf() |> 
        dplyr::left_join(hu_new_df, dplyr::join_by(unf_uid))
    })
    
    sfOut <- standardFiltersServer("sf", huDf, selected = c("zone", "ioao"))
    sfNewOut <- standardFiltersServer("sf", huNewDf, selected = c("zone", "ioao"))
    
    betOut <- fazFilterServer("bet", sfOut$data)
    betNewOut <- fazFilterServer("bet", sfNewOut$data)
    
    hurVars <- fazFilterServer("hur")
    
    baseName <- reactive({
      paste0("Median ", input$lookback[1], "-", input$lookback[2])
    })
    
    
    laufendName <- reactive({
      if(lubridate::year(maxDate()) == max_jahr+1) {
        paste0("Laufendes Jahr")
      } else {
        paste0(lubridate::year(maxDate()))
      }
    })
    
    huBaseData <- reactive({
      df <- betOut$data()
      
      if((hurVars$grouped())) {
        df <- df |>
          dplyr::mutate(hu = hur_grp)
      } else {
        df <- df |>
          dplyr::mutate(hu = hur)
      }
      
      hu_faz <- hurVars$faz()
      
      if(length(hu_faz) != 0) df <- df |> dplyr::filter(hu %in% hu_faz)
      
      df <- df |>
        dplyr::filter(
          !hauptverursacher,
          lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(maxDate())*100 + lubridate::day(maxDate()),
          Jahr >= input$lookback[1], Jahr <= input$lookback[2]
        ) |> 
        dplyr::mutate(
          hu = factor(hu, levels = hu_faz),
          faz = factor(faz, levels = betOut$faz())
        ) |> 
        dplyr::count(Jahr, hu, faz, .drop = F) |> 
        dplyr::group_by(hu, faz) |> 
        dplyr::summarise(
          n = median(n),
          .groups = "drop"
        )
      
      names(df)[3] <- baseName()
      
      df
    })
    
    huCurrentData <- reactive({
      df <- betNewOut$data()
      
      if((hurVars$grouped())) {
        df <- df |>
          dplyr::mutate(hu = hur_grp)
      } else {
        df <- df |>
          dplyr::mutate(hu = hur)
      }
      
      hu_faz <- hurVars$faz()
      
      if(length(hu_faz) != 0) df <- df |> dplyr::filter(hu %in% hu_faz)
      
      df |>
        dplyr::filter(
          !hauptverursacher,
          lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(maxDate())*100 + lubridate::day(maxDate())
        ) |> 
        dplyr::mutate(
          hu = factor(hu, levels = hu_faz),
          faz = factor(faz, levels = betOut$faz())
        ) |> 
        dplyr::count(hu, faz, .drop = F, name = laufendName())
    })
    
    huData <- reactive({
      huBaseData() |> 
        dplyr::left_join(huCurrentData(), dplyr::join_by(hu, faz)) |> 
        tidyr::pivot_longer(!c(hu, faz)) |> 
        dplyr::mutate(name = factor(name, levels = c(laufendName(), baseName())))
    })
    
    output$plot_title <- renderText({
      
      laufend_name <- ifelse(
        maxJahr() == max_jahr,
        "im laufenden Jahr",
        paste("im Jahr", maxJahr()+1)
      )
      
      title <- paste0(
        "Anzahl der Unfälle nach Hauptverursacher und Beteiligten ",
        laufend_name,
        " im Vergleich zum ",
        baseName()
      )
      
      if(maxJahr() == max_jahr) {
        title <- paste(title, "bis", format(maxDate(), format = "%e. %B"))
      }
      
      title
    })
    
    output$vs_bar_plot <- plotly::renderPlotly({
      req(hurVars$faz(), betOut$faz())
      vs_bar_plot(huData(), hurVars$faz(), betOut$faz())
    })
  })
}
