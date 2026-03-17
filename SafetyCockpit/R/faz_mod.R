
fazUI <- function(id, filters = NULL) {
  filters["level"] <- "Objekt"
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        id = ns("sidebar"),
        width = sidebar_width,
        # sfiltersUI(id, filters = filters),
        # fazFilterUI(ns("fazfilter1"), selected = filters[["faz"]]),
        # selectizeInput(
        #   NS(id, "schwere"), label = span("Schwere", bsicons::bs_icon("filter")),
        #   choices = levels(obj_df$schwere),
        #   selected = translate_schwere(filters[["schwere"]], "Objekt"),
        #   multiple = T,
        #   options = list(plugins = list("remove_button"))
        # ),
        checkBox(ns("facet"), "Nach Schwere trennen"),
        # standardFiltersUI(ns("sf"), filters = filters),
        # fazFilterUI(ns("faz"), selected = filters[["faz"]], label = span("Verkehrsteilnehmende", bsicons::bs_icon("filter"))),
        # schwereFilterUI(ns("schwere"), filters = filters, label = span("Schwere", bsicons::bs_icon("filter")))
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
        plotly::plotlyOutput(NS(id, "faz_plot")),
        full_screen = T
      )
    )
  )
}


fazServer <- function(id, res = \(x) NULL) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(res(), {
      shinyjs::reset("sidebar")
    }, ignoreInit = T)
    
    #fazfiltervars <- fazFilterServer("fazfilter1")
    
    # standardFilterOut <- standardFiltersServer("sf", df = obj_df)
    # fazFilterOut <- fazFilterServer("faz", df = standardFilterOut$data)
    # schwereFilterOut <- schwereFilterServer("schwere", reactive_level = reactive("Objekt"), levelData = fazFilterOut$data)
    filterOut <- filterServer("filter", data = obj_df, reactive_level = reactive("Objekt"))
    
    fazData <- reactive({
      #req(fazfiltervars$faz())
      # if(length(fazfiltervars$faz()) == 0) validate("Bitte w\u00e4hlen Sie mindestens einen Verkehrsteilnehmer")
      
      # faz_data <- obj_df |> 
      #   sfiltersApply(input) |>
      #   dplyr::select(Jahr, fahrzeugart, fahrzeugart_grp, schwere)
      # 
      # 
      # faz_data <- fazFilterApply(
      #     faz_data, fazfiltervars$faz(), isolate(fazfiltervars$grouped())
      #   ) |> 
      #   dplyr::select(Jahr, faz, schwere)
      # |>
      #   dplyr::mutate(faz = factor(faz, fazfiltervars$faz()))
      
      # input_schwere <- input$schwere
      # 
      # if(length(input_schwere) == 0) input_schwere <- levels(obj_df$schwere)
      
      faz_data <- filterOut$data_faz()
      
      req(nrow(faz_data) > 0)
      
      minj <- min(faz_data$Jahr)
      maxj <- max(faz_data$Jahr)
      
      if(input$facet) {
        if(nrow(faz_data) == 0) validate("Keine Daten")
        
        faz_data |> 
          dplyr::count(Jahr, faz, schwere) |>
          dplyr::group_by(faz) |> 
          tidyr::complete(Jahr = min(Jahr):max(Jahr), schwere, fill = list(n = 0)) |> 
          dplyr::ungroup() |> 
          dplyr::arrange(desc(Jahr), desc(n))
      } else {
        faz_data <- filterOut$data()
        # faz_data <- faz_data |> 
        #   dplyr::filter(
        #     schwere %in% input_schwere
        #   )
        
        if(nrow(faz_data) == 0) validate("Keine Daten")
        
        faz_data |> 
          dplyr::count(Jahr, faz) |>
          dplyr::group_by(faz) |>
          tidyr::complete(Jahr = min(Jahr):max(Jahr), fill = list(n = 0)) |>
          dplyr::ungroup() |>
          dplyr::arrange(desc(Jahr), desc(n))
      }
    })
    
    plotTitle <- reactive({
      if(length(filterOut$faz()) == 0) {
        validate("Bitte w\u00e4hlen Sie mindestens einen Verkehrsteilnehmenden aus")
      }
      faz_plot_title(
        filterOut$faz(), filterOut$zone(), filterOut$ioao(), filterOut$schwere(), input$facet
      )
    })
    
    output$plot_title <- renderText(plotTitle())
    
    output$faz_plot <- plotly::renderPlotly({
      req(fazData())
      if(nrow(fazData()) == 0) validate("Keine Daten")
      if(input$facet) {
        faz_plot_facet(fazData(), filterOut$schwere()) |> 
          plotly::config(toImageButtonOptions = list(
            filename = plotTitle()
          ))
      } else {
        faz_plot(fazData()) |> 
          plotly::config(toImageButtonOptions = list(
            filename = plotTitle()
          ))
      }
    })
  })
}
