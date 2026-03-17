
vsUI <- function(id, filters = NULL) {
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        id = ns("sidebar"), width = sidebar_width,
        fazFilterUI(
          ns("hur"),
          selected = filters[["faz"]],
          label = "Hauptverursacher wählen" 
        ),
        fazFilterUI(
          ns("bet"),
          selected = filters[["faz"]],
          label = "Beteiligte wählen" 
        ),
        standardFiltersUI(ns("sf"), filters = filters),
        schwereFilterUI(ns("schwere"), filters = filters)
      ),
      bslib::card(
        bslib::card_header(
          textOutput(ns("plot_title")),
          infoPop(
            p("Die Spalten entsprechen den beteiligten Verkehrsteilnehmern und
              die Zeilen den Hauptverursachern."),
            p("Die Trendlinien wurden mit einem verallgemeinerten linearen 
              Modell mit negativer Binomialverteilung berechnet. Die graue 
              Fl\u00e4che entspricht dem 95%-Konfidenzintervall.")
          ),
          class = "d-flex justify-content-between"
        ),
        plotly::plotlyOutput(ns("vs_plot"))
      )
    )
  )
}

vsServer <- function(id, res = \(x) NULL) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(res(), {
      shinyjs::reset("sidebar")
    })
    
    huDF <- reactive({
      hu_df <- obj_df |> 
        dplyr::filter(hauptverursacher) |> 
        dplyr::select(
          unf_uid,
          hur = fahrzeugart,
          hur_grp = fahrzeugart_grp
        )
      
      hu_df <- obj_df |> 
        dplyr::left_join(hu_df,dplyr::join_by(unf_uid))
    })
    
    
    hurVars <- fazFilterServer("hur")
    
    sfOut <- standardFiltersServer("sf", huDF)
    
    schwereOut <- schwereFilterServer("schwere", reactive_level = reactive({"Objekt"}), levelData = sfOut$data)
    
    betOut <- fazFilterServer("bet", schwereOut$data)
    
    huData <- reactive({
      df <- betOut$data()
      
      if(hurVars$grouped()) {
        df <- df |>
          dplyr::mutate(hu = hur_grp)
      } else {
        df <- df |>
          dplyr::mutate(hu = hur)
      }
      
      hu_faz <- hurVars$faz()
      
      if(length(hu_faz) != 0) df <- df |> dplyr::filter(hu %in% hu_faz)
      
      df <- df |>
        dplyr::filter(!hauptverursacher) |> 
        dplyr::mutate(
          hu = factor(hu, levels = hu_faz),
          faz = factor(faz, levels = betOut$faz())
        ) |> 
        dplyr::count(Jahr, hu, faz) |> 
        tidyr::complete(hu, faz, fill = list(n = 0))
      
      not_enough <- df |> 
        dplyr::count(as.character(hu), as.character(faz)) |> 
        dplyr::filter(n < 3) |> 
        nrow()
      
      if(not_enough > 0) {
        validate("Zu wenig Daten")
      }
      
      df
    })
    
    plotTitle <- reactive({
      if(length(hurVars$faz()) == 0) {
        validate("Bitte w\u00e4hlen Sie mindestens einen Hauptverursacher aus")
      }
      if(length(betOut$faz()) == 0) {
        validate("Bitte w\u00e4hlen Sie mindestens einen Beteiligten aus")
      }
      vs_plot_title(sfOut$zone(), sfOut$ioao(), input$schwere)
    })
    
    output$plot_title <- renderText(plotTitle())
    
    output$vs_plot <- plotly::renderPlotly({
      req(hurVars$faz(), betOut$faz())
      vs_plot(
        huData(), 
        hurVars$faz(), betOut$faz(),
        hurVars$grouped(), betOut$grouped()
      )
    })
  })
}
