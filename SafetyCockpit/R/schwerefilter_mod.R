schwereFilterUI <- function(
    id, filters = NULL,
    label = span("Schwere", bsicons::bs_icon("filter"))
) {
  ns <- NS(id)
  tagList(selectizeInput(
      ns("schwere"), label = label,
      choices = translate_schwere(
        c("ss", "lv", "sv", "gt", "un"), filters[["level"]], na.rm = T
      ),
      selected = translate_schwere(filters[["schwere"]], filters[["level"]]),
      multiple = T,
      options = list(plugins = list("remove_button"))
    )
  )
}

schwereFilterServer <- function(id, reactive_level = reactive("Unfall"), levelData = reactive(unf_df)) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(reactive_level(), {
      prev_schwere <- input$schwere
      prev_level <- ifelse(any(stringr::str_detect(prev_schwere, "Unf\u00e4lle")), "Unfall", "")
      current_level <- reactive_level()
      current_schwere <- translate_schwere(
        encode_schwere(prev_schwere, prev_level),
        current_level
      )
      updateSelectizeInput(
        session, "schwere",
        choices = levels(levelData()$schwere),
        selected = current_schwere
      )
    }, ignoreInit = T)
    
    outData <- reactive({
      if(!is.null(input$schwere)) {
        levelData() |> 
          dplyr::filter(schwere %in% input$schwere)
      } else {
        levelData()
      }
    })
    
    list(
      data = outData,
      schwere = reactive(input$schwere),
      level = reactive_level
    )
  })
}
