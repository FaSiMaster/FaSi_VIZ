mapDensityUI <- function(id) {
  ns <- NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      open = T, width = sidebar_width,
      filterUI(
        ns("filter"), filters = list(minj = max_jahr-9),
        faz_label = span("Fahrzeugart", bsicons::bs_icon("filter")) |> 
          bslib::tooltip("Wird Auf Hauptverusacher filtreiert")),
      actionButton(ns("go"), "Karte erstellen!")
    ),
    bslib::card(
      bslib::card_header(textOutput(ns("title"))),
      #bslib::as_fill_carrier(shinycssloaders::withSpinner(
        leaflet::leafletOutput(ns("map1")),
        #hide.ui = F
      #)),
      full_screen = T
    )
  )
}

mapDensityServer <- function(id, unfDf, unfNewDf, maxDate, maxJahr) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(maxJahr(), {
      maxj <- maxJahr()
      updateSliderInput(inputId = NS("filter")(NS("sf")("zeitraum")), value = c(maxj-9, maxj), max = maxj)
    })

    grid_size <- 40
    area_zh_2056 <- sf::st_transform(canton_zh_no_lakes, 2056)
    r_template <- make_template_lv95(area_zh_2056, grid_size)
    
    #fazfiltervars <- fazFilterServer("fazfilter")
    
    filterOut <- filterServer("filter", unfDf)
    filterOut_new <- filterServer("filter", unfNewDf, selected = c("zone", "ioao"))

    baseData <- reactive({
      # temp <- sfiltersApply(unf_df, input)
      # 
      # if(!is.null(input$schwere)) {
      #   temp <- temp |>
      #     dplyr::filter(schwere %in% input$schwere)
      # }
      # 
      # 
      # temp <- fazFilterApply(
      #   temp, fazfiltervars$faz(), isolate(fazfiltervars$grouped())
      # )
      temp <- filterOut$data()
      temp <- temp |> dplyr::filter(lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(maxDate())*100 + lubridate::day(maxDate()))

      if(nrow(temp) == 0) validate("Keine Basis Daten")

      temp
    }) #|>
      # bindCache(
      #   list(
      #     filterOut$zeitraum(),
      #     filterOut$zone(),
      #     filterOut$ioao(),
      #     filterOut$schwere(),
      #     filterOut$faz(),
      #     isolate(filterOut$faz_grouped()),
      #     max_date
      #   )
      # )

    currentData <- reactive({
      # current_data <- sfiltersApply(unf_new_df, input, selected = c("zone", "ioao"))
      # 
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
      current_data <- filterOut_new$data()
      current_data <- current_data |> dplyr::filter(lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(maxDate())*100 + lubridate::day(maxDate()))

      if(nrow(current_data) == 0) validate("Keine Aktuelle Daten")
      
      current_data
    }) #|>
      # bindCache(
      #   list(
      #     filterOut_new$zeitraum(),
      #     filterOut_new$zone(),
      #     filterOut_new$ioao(),
      #     filterOut_new$schwere(),
      #     filterOut_new$faz(),
      #     isolate(filterOut_new$faz_grouped()),
      #     max_date
      #   )
      # )

    r_final <- reactive({
      mapdensity_data(baseData(), currentData(), r_template, area_zh_2056)
    }) |>
      #bindCache(list(filterOut$zeitraum(), filterOut$zone(), filterOut$ioao(), filterOut$schwere(), filterOut$faz(), filterOut$faz_grouped(), maxDate())) |>
      bindEvent(input$go)

    # output$map1 <- leaflet::renderLeaflet({
    #   withProgress(message = "Die Karte wird erstellt...", value = 0, {
    #     req(r_final())
    #     
    #     rng     <- terra::global(r_final(), fun = "range", na.rm = T)
    #     abs_max <- max(abs(rng))
    #     pal     <- leaflet::colorNumeric("RdBu", domain = c(-abs_max, abs_max),
    #                                      reverse = TRUE, na.color = "transparent")
    #     
    #     pal2     <- leaflet::colorNumeric("RdBu", domain = c(-abs_max, abs_max),
    #                                      reverse = F, na.color = "transparent")
    #     
    #     map <- leaflet::leaflet() |> 
    #       leaflet::addProviderTiles("CartoDB.Positron") |> 
    #       leaflet::addWMSTiles(
    #         group = "Strassennetz",
    #         layerId = "base",
    #         baseUrl = "https://wms.zh.ch/TBAStr1ZHWMS", 
    #         layers = c("TBAStr1ZHWMS"), 
    #         options = leaflet::WMSTileOptions(version = "1.3.0", 
    #                                           transparent = T,
    #                                           format = "image/png")
    #       )
    #     
    #     map <- map |>
    #       leaflet::addPolygons(
    #         data = canton_zh_no_lakes, fillColor = "transparent", 
    #         fillOpacity = 0, color = "#666666", weight = 1, opacity = 1
    #       ) |>
    #       leaflet::addRasterImage(layerId = "density", group = "Densität",
    #         r_final(), colors = pal , opacity = 0.7, project = F
    #       ) |>
    #       leaflet::addLegend(
    #         position = "bottomright",
    #         pal = pal2, values = c(-abs_max, abs_max),
    #         labFormat = function(type, cuts, p) {
    #           c("Mehr Unfälle",
    #             "",
    #             "Keine Differenz",
    #             "",
    #             "Weniger Unfälle")
    #         }
    #       ) |>
    #       leaflet::addScaleBar(position = "bottomleft", options = leaflet::scaleBarOptions(imperial = F)) |> 
    #       leaflet::addLayersControl(
    #         overlayGroups = c("Strassennetz", "Densität"),
    #         options = leaflet::layersControlOptions(autoZIndex = T)
    #       )
    #     
    #     setProgress(1, detail = "Karte bereit!")
    #     
    #     map
    #   })
    # })
    
    output$map1 <- leaflet::renderLeaflet({
      leaflet::leaflet() |>
        leaflet::addProviderTiles("CartoDB.Positron") |>
        leaflet::addWMSTiles(
          group   = "Strassennetz",
          layerId = "base",
          baseUrl = "https://wms.zh.ch/TBAStr1ZHWMS",
          layers  = c("TBAStr1ZHWMS"),
          options = leaflet::WMSTileOptions(
            version     = "1.3.0",
            transparent = TRUE,
            format      = "image/png"
          )
        ) |>
        leaflet::addPolygons(
          data        = canton_zh_no_lakes,
          fillColor   = "transparent",
          fillOpacity = 0,
          color       = "#666666",
          weight      = 1,
          opacity     = 1,
          group       = "Boundary"
        ) |>
        leaflet::addScaleBar(
          position = "bottomleft",
          options  = leaflet::scaleBarOptions(imperial = FALSE)
        ) |>
        leaflet::addLayersControl(
          overlayGroups = c("Strassennetz", "Densität"),
          options       = leaflet::layersControlOptions(autoZIndex = TRUE)
        )
    })
    
    observeEvent(input$go, {
      withProgress(message = "Die Karte wird aktualisiert...", value = 0, {
        
        r <- r_final()
        req(r_final())
      
        rng     <- terra::global(r, fun = "range", na.rm = TRUE)
        abs_max <- max(abs(rng))
        
        pal <- leaflet::colorNumeric(
          palette  = "RdBu",
          domain   = c(-abs_max, abs_max),
          reverse  = TRUE,
          na.color = "transparent"
        )
        
        pal2 <- leaflet::colorNumeric(
          palette  = "RdBu",
          domain   = c(-abs_max, abs_max),
          reverse  = FALSE,
          na.color = "transparent"
        )
        
        setProgress(0.9, detail = "Raster-Layer wird ersetzt...")
        
        leaflet::leafletProxy("map1") |>
          leaflet::clearGroup("Densität") |>
          leaflet::clearControls() |>
          leaflet::addRasterImage(
            r,
            layerId = "density",
            group   = "Densität",
            colors  = pal,
            opacity = 0.7,
            project = FALSE
          ) |>
          leaflet::addLegend(
            position = "bottomright",
            pal      = pal2,
            values   = c(-abs_max, abs_max),
            labFormat = function(type, cuts, p) {
              c("Mehr Unfälle", "", "Keine Differenz", "", "Weniger Unfälle")
            }
          )
        
        setProgress(1, detail = "Karte bereit!")
      })
    }, ignoreInit = TRUE)
    
    
    
    map_plot_title <- function(zone, ioao, faz, schwere, zeitraum, maxj) {
      what <- paste0("Karte der Differenz zwischen den Unfälle des laufenden Jahres (", maxj + 1, ") und dem Median")
      
      if(zone == "Gesamte Kanton") zone <-  NULL
      if(ioao == "Alle") ioao <-  NULL
      
      plus <- paste0(" (",stringr::str_flatten_comma(c(zone, ioao, faz, schwere)),")")
      
      plus <- ifelse(plus == " ()", "", plus)
      
      paste0(what, " von ", zeitraum[1], " bis ", zeitraum[2], plus)
    }
    
    plotTitle <- reactive({
      map_plot_title(filterOut$zone(), filterOut$ioao(), filterOut$faz(), filterOut$schwere(), filterOut$zeitraum(), maxJahr())
    }) |> bindEvent(input$go)
    
    output$title <- renderText({
      plotTitle()
    })
  })
}