
sfiltersUI <- function(id, selected = NULL, filters = NULL) {
  ui <- tagList()
  if("zeitraum" %in% selected | is.null(selected)) {
    ui <- tagList(
      ui,
      sliderInput(
        NS(id, "zeitraum"), "Zeitraum",
        min_jahr, max_jahr, value = c(max(min_jahr, filters$minj), min(max_jahr, filters$maxj)),
        sep = "", ticks = F
      )
    )
  }
  
  if("zone" %in% selected | is.null(selected)) {
    ui <- tagList(
      ui,
      selectInput(
        NS(id, "zone"), "Gebiet",
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
        NS(id, "ioao"), "Ort",
        choices = c("Alle", "innerorts", "ausserorts"),
        selected = filters[["ioao"]], selectize = T
      )
    )
  }
  
  return(ui)
}

sfiltersApply <- function(df, input, selected = NULL) {
  
  if("zeitraum" %in% selected | is.null(selected)){
    df <- df |> 
      dplyr::filter(Jahr >= input$zeitraum[1], Jahr <= input$zeitraum[2])
  }
  
  if("zone" %in% selected | is.null(selected)) {
    if(input$zone == "Gesamte Kanton") df <- df
    if(input$zone == "Ohne St\u00e4dte + HLS") df <- df |> dplyr::filter((!is_stadt) | is_abas)
    if(input$zone == "Staatsstrassen") df <- df |> dplyr::filter(is_ksn)
    if(input$zone == "Stadt Z\u00fcrich") df <- df |> dplyr::filter(is_zh & !is_abas)
    if(input$zone == "Stadt Winterthur") df <- df |> dplyr::filter(is_win & !is_abas)
    if(input$zone == "Autobahn") df <- df |> dplyr::filter(is_abas)
  }
  
  if("ioao" %in% selected | is.null(selected)) {
    if((input$ioao) != "Alle"){
      df <- df |> 
        dplyr::filter(ioao == input$ioao)
    }
  }
  
  df
}
