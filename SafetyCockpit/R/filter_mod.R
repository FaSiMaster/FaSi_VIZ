
filterUI <- function(
    id,
    selected = NULL,
    filters = NULL,
    faz_label = span("Verkehrsteilnehmende", bsicons::bs_icon("filter")),
    schwere_label = span("Schwere", bsicons::bs_icon("filter")),
    open = T
) {
  ns <- NS(id)
  bslib::accordion(
    open = open,
    bslib::accordion_panel(
      "Allgemeinen Filter",
      standardFiltersUI(ns("sf"), selected = selected, filters = filters),
      fazFilterUI(ns("faz"), selected = filters[["faz"]], label = faz_label),
      schwereFilterUI(ns("schwere"), filters = filters, label = schwere_label)
    )
  )
}

filterServer <- function(id, data, selected = NULL, reactive_level = reactive("Unfall")) {
  moduleServer(id, function(input, output, session) {
    
    sfOut <- standardFiltersServer("sf", df = data, selected = selected)
    
    fazOut <- fazFilterServer("faz", df = sfOut$data)
    
    schwereOut <- schwereFilterServer("schwere", reactive_level = reactive_level, levelData = fazOut$data)
    
    list(
      data_faz = fazOut$data,
      data = schwereOut$data,
      zeitraum = sfOut$zeitraum,
      zone = sfOut$zone,
      ioao = sfOut$ioao,
      schwere = schwereOut$schwere,
      level = schwereOut$level,
      faz = fazOut$faz,
      faz_grouped = fazOut$grouped
    )
    
  })
}
