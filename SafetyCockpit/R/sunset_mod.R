sunsetUI <- function(id, filters = NULL) {
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
        #   ns("schwere"), label = span("Schwere", bsicons::bs_icon("filter")),
        #   choices = translate_schwere(
        #     c("ss", "lv", "sv", "gt", "un"), filters[["level"]], na.rm = T
        #   ),
        #   selected = translate_schwere(filters[["schwere"]], filters[["level"]]),
        #   multiple = T,
        #   options = list(plugins = list("remove_button"))
        # ),
        # fazFilterUI(ns("fazfilter"), selected = filters[["faz"]])
        filterUI(ns("filter"), filters = filters)
      ),
      bslib::card(
        bslib::card_header(
          textOutput(ns("sun_plot_title")),
          infoPop(
            p("Die Hintergrundfarben entsprechen den Lichtverhältnissen:
              Tag, bürgerliche Dämmerung, nautische Dämmerung, astronomische Dämmerung und Nacht.
              Die Dämmerungsstufen sind wie folgt definiert:"),
            tags$ul(
              tags$li("Bürgerliche Dämmerung: Beginn, wenn die Sonne 6 Grad unter dem Horizont steht."),
              tags$li("Nautische Dämmerung: Beginn, wenn die Sonne zwischen 6 und 12 Grad unter dem Horizont steht."),
              tags$li("Astronomische Dämmerung: Beginn, wenn die Sonne zwischen 12 und 18 Grad unter dem Horizont steht.")
            ),
            options = list(customClass = "mid-info")
          ),
          class = "d-flex justify-content-between"
        ),
        plotly::plotlyOutput(ns("sun_plot"))
      )
    )
  )
}

sunsetServer <- function(id, res = \(x) NULL) {
  moduleServer(id, function(input, output, session) {
    observeEvent(res(), {
      shinyjs::reset("sidebar")
    }, ignoreInit = T)
    
    observe({
      shinyjs::toggle(id = "kosten", condition = (input$level == "Unfall"))
    })
    
    #fazfiltervars <- fazFilterServer("fazfilter")
    
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
    
    reLevel <- reactive(input$level)
    
    filterOut <- filterServer("filter", data = levelData, reactive_level = reLevel)
    
    sunData <- reactive({
      req(nrow(filterOut$data()) > 0)
      filterOut$data() |> 
        dplyr::mutate(
          # lc = lighting_condition(lat, lng, unfallzeit), .after = unfallzeit,
          unfallzeit = datetime_flatten(unfallzeit, filterOut$zeitraum()[2]),
          weight = ifelse(input$kosten, kosten12, 1)
        )
    })
    
    
    
    filteredData <- reactive({
      temp <- sunData()
      # temp <- sfiltersApply(sunData(), input)
      # temp <- fazFilterApply(temp, fazfiltervars$faz(), fazfiltervars$grouped())
      # if(length(input$schwere) != 0) {
      #   temp <- temp |> dplyr::filter(schwere %in% input$schwere)
      # }
      temp
    })
    
    points <- reactive({
      df <- filteredData()
      
      df <- df |> 
        dplyr::mutate(
          unfallzeit = lubridate::floor_date(unfallzeit, "hour"),
          datum = lubridate::floor_date(md_date(datum, filterOut$zeitraum()[2]), "month")
        ) |> 
        dplyr::count(unfallzeit, datum, wt = weight) |> 
        tidyr::complete(
          unfallzeit = seq(
            lubridate::make_datetime(year = filterOut$zeitraum()[2], hour = 0),
            lubridate::make_datetime(year = filterOut$zeitraum()[2], hour = 23),
            "hour"
          ),
          datum = seq(
            lubridate::make_date(year = filterOut$zeitraum()[2]),
            lubridate::make_date(year = filterOut$zeitraum()[2], month = 12, day = 31),
            "month"
          ),
          fill = list(n = 0)
        )
      df <- df |> 
        dplyr::mutate(
          normed_n = log(1 + n),
          normed_n = (normed_n - min(normed_n)) / (max(normed_n) - min(normed_n)), 
          normed_n = 15*(normed_n + 1)
        )
      df
    })
    
    plotTitle <- reactive(sunset_plot_title(
        input$kosten, input$level, filterOut$zeitraum(), filterOut$zone(),
        filterOut$ioao(), NULL, filterOut$faz()
    ))
    
    output$sun_plot_title <- renderText(plotTitle())
    
    output$sun_plot <- plotly::renderPlotly({
      z_name <- ifelse(isolate(input$kosten) & isolate(input$level) == "Unfall", "Kosten (CHF)", "Anzahl")
      bg_plotly(
        filterOut$zeitraum()[2],
        filterOut$zeitraum()[2],
        47.39809, 8.594464,
        twilights = T
      ) |> 
        plotly::add_trace(
          data = points(),
          x =~unfallzeit, y =~datum,
          type = "scatter", mode = "markers+lines", 
          line = list(color = "#00000000"),
          marker = list(
            color = ~n,
            opacity = 1,
            reversescale = F,
            colorscale = "Picnic",
            colorbar = list(title = z_name),
            size = ~normed_n
          ),
          text = ~n,
          hovertemplate = paste0(
            "%{yaxis.title.text}: %{y|%B}\n",
            "%{xaxis.title.text}: %{x}\n",
            "Anzahl: %{text:,.0f}<extra></extra>"
          )
        ) |> 
        plotly::config(toImageButtonOptions = list(
          filename = plotTitle()
        ))
    })
  })
}
