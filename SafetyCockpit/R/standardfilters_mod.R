
standardFiltersUI <- function(id, selected = NULL, filters = NULL) {
  ns <- NS(id)
  
  ui <- tagList()
  if("zeitraum" %in% selected | is.null(selected)) {
    ui <- tagList(
      ui,
      sliderInput(
        ns("zeitraum"), "Zeitraum",
        min_jahr, max_jahr, value = c(max(min_jahr, filters$minj), min(max_jahr, filters$maxj)),
        sep = "", ticks = F
      )
    )
  }
  
  if("zone" %in% selected | is.null(selected)) {
    ui <- tagList(
      ui,
      selectInput(
        ns("zone"), "Gebiet",
        choices = c("Gesamte Kanton", "Ohne St\u00e4dte + HLS", "Staatsstrassen", 
                    "Stadt Z\u00fcrich", "Stadt Winterthur", "Autobahn"),
        selected = filters[["zone"]], selectize = T
      )
    )
  }
  
  if("ioao" %in% selected | is.null(selected)) {
    ui <- tagList(
      ui,
      selectInput(
        ns("ioao"), "Ort",
        choices = c("Alle", "innerorts", "ausserorts"),
        selected = filters[["ioao"]], selectize = T
      )
    )
  }
  
  ui
}

standardFiltersServer <- function(id, df, selected = NULL) {
  moduleServer(id, function(input, output, session) {
    data <- reactive({
      if(is.reactive(df)) df <- df()
      
      if("zeitraum" %in% selected | is.null(selected)){
        req(input$zeitraum)
        df <- df |> 
          dplyr::filter(Jahr >= input$zeitraum[1], Jahr <= input$zeitraum[2])
      }
      
      if("zone" %in% selected | is.null(selected)) {
        req(input$zone)
        if(input$zone == "Gesamte Kanton") df <- df
        if(input$zone == "Ohne St\u00e4dte + HLS") df <- df |> dplyr::filter((!is_stadt) | is_abas)
        if(input$zone == "Staatsstrassen") df <- df |> dplyr::filter(is_ksn)
        if(input$zone == "Stadt Z\u00fcrich") df <- df |> dplyr::filter(is_zh & !is_abas)
        if(input$zone == "Stadt Winterthur") df <- df |> dplyr::filter(is_win & !is_abas)
        if(input$zone == "Autobahn") df <- df |> dplyr::filter(is_abas)
      }
      
      if("ioao" %in% selected | is.null(selected)) {
        req(input$ioao)
        if((input$ioao) != "Alle"){
          df <- df |> 
            dplyr::filter(ioao == input$ioao)
        }
      }
      
      df
    })
    
    list(
      data = data,
      zeitraum = reactive(input$zeitraum),
      zone = reactive(input$zone),
      ioao = reactive(input$ioao)
    )
    
  })
}