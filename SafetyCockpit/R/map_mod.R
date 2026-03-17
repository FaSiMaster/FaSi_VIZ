mapUI <- function(id) {
  ns <- NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      open = F, width = sidebar_width,
      filterUI(
        ns("filter"), filters = list(minj = max_jahr - 9),
        faz_label = span("Fahrzeugart", bsicons::bs_icon("filter")) |>
          bslib::tooltip("Wird Auf Hauptverusacher filtreiert")
      )
    ),
    bslib::card(
      add_spinner(leaflet::leafletOutput(ns("map"))), 
      full_screen = T
    )
  )
}

mapServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    filterOut <- filterServer("filter", data = unf_df)
    
    mapData <- reactive({
      map_data <- filterOut$data()
      
      if(nrow(map_data) == 0) validate("Keine Daten")
      
      map_data
    })
    
    output$map <- leaflet::renderLeaflet({
      map_df <- mapData()
      cols <- leaflet::colorFactor(
        palette = schwere_cols[1:4],
        domain = levels(map_df$schwere),
        ordered = T
      )
      leaflet::leaflet(map_df) |> 
        leaflet::addTiles() |> 
        leaflet::addCircleMarkers(clusterId = "unfall",
          lng = ~lng,
          lat = ~lat,
          radius = 5, # could make it proportional to ss_chf
          fillColor = ~cols(schwere),
          fillOpacity = 0.8,
          color = "black",
          opacity = 0.8,
          weight = 1,
          clusterOptions = leaflet::markerClusterOptions(
              spiderfyOnMaxZoom = F,
              disableClusteringAtZoom = floor(log2(nrow(map_df)))
          )
        ) |> 
        leaflet::addLegend(pal = cols, values = ~schwere, group = "circles", position = "bottomright", title = NULL) |> 
        leaflet::addEasyButton(
          leaflet::easyButton(
            states = list(
              leaflet::easyButtonState(
                stateName="cluster-on",
                icon="ion-toggle-filled",
                title="Cluster On",
                onClick = leaflet::JS("function(btn, map) {
                          var clusterManager = map.layerManager.getLayer('cluster', 'unfall')
                          clusterManager.freezeAtZoom(clusterManager._maxZoom + 1);
                          btn.state('cluster-off');
                        }")
              ),
              leaflet::easyButtonState(
                stateName="cluster-off",
                icon="ion-toggle",
                title="Cluster Off",
                onClick = leaflet::JS("function(btn, map) {
                          var clusterManager = map.layerManager.getLayer('cluster', 'unfall')
                          clusterManager.unfreeze();
                          btn.state('cluster-on');
                        }")
              )
            )
          )
        ) |>
        leaflet::addScaleBar(position = "bottomleft", options = leaflet::scaleBarOptions(imperial = F))
    })
  })
}
