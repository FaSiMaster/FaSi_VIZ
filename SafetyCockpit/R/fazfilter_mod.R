# translate between grouped and ungrouped Fahrzeugart
translator <- list(
  "Fahrrad" = c("Fahrrad","Motorfahrrad (ohne E-Bike)"),
  "Fussg\u00e4nger" = "Fussg\u00e4nger",
  "Fahrzeug\u00e4hnliches Ger\u00e4t" = "F\u00e4G",
  "E-Bike" = c("Schnelles E-Bike", "Langsames E-Bike"),
  "Motorrad" = c(
    "Motorrad", "Kleinmotorrad", "Kleinmotorrad-Dreirad", "Motorrad-Dreirad",
    "Motorrad-Seitenwagen", "Kleinmotorfahrzeug", "Leichtmotorfahrzeug", 
    "Dreir\u00e4driges Motorfahrzeug"
  ),
  "Personenwagen" = c("Personenwagen", "Schwerer Personenwagen"),
  "Personentransport (ohne \u00d6V)" = c(
    "Leichter Motorwagen", "Schwerer Motorwagen", "Gesellschaftswagen",
    "Kleinbus"
  ),
  "\u00d6ffentlicher Verkehr" = c(
    "Gelenkbus", "Trolleybus", "Gelenktrolleybus", "Linienbus", "Tram",
    "Bahn" 
  ),
  "Landwirtschaft" = c(
    "Traktor", "Motorkarren", "Arbeitsmaschine", "Arbeitskarren",
    "Landw. Traktor", "Landw. Arbeitskarren", "Landw. Motorkarren",
    "Landw. Kombinations-Fahrzeug", "Landw. Motoreinachser"
  ),
  "Sachentransport" = c(
    "Lieferwagen", "Lastwagen", "Leichtes Sattelmotorfahrzeug", 
    "Schweres Sattelmotorfahrzeug", "Sattelschlepper"
  ),
  "Andere (motorisiert)" = "andere motorisierte Fahrzeuge",
  "Andere (nicht motorisiert)" = c(
    "andere nicht motorisierte Fahrzeuge", "Sattel-Sachentransportanh\u00e4nger",
    "Sachentransportanh\u00e4nger", "Anh\u00e4nger", "Arbeitsanh\u00e4nger",
    "Sportger\u00e4teanh\u00e4nger" 
  ),
  "Unbekannt" = "unbekannt"
)

to_grp <- function(faz) {
  purrr::map_chr(
    faz,
    \(y) ifelse(
      y %in% names(translator),
      y,
      names(which(sapply(translator, \(x) y %in% x)))
    )
  )
}
to_normal <- function(faz) {
  purrr::map(faz, \(x) translator[[x]]) |> unlist()
}

fazFilterUI <- function(
    id, selected = c("Fahrrad", "Fussg\u00e4nger"),
    label = span("Verkehrsteilnehmende", bsicons::bs_icon("filter"))
  ) {
  ns <- NS(id)
  mpcb <- checkBox(ns("grouped"), "aggregiert", value = T, inline = T) |> 
    bslib::tooltip("Sollen die Verkehrsteilnehmenden zu aussagekr\u00e4ftigen Gruppen aggregiert werden?")
  tagList(
    tags$style(
      HTML("
        .shiny-input-container-inline {
          margin: 0;
        }
      ")
    ),
    selectizeInput(
      ns("faz"), label = tagList(label, br(), mpcb),
      choices = levels(obj_df$fahrzeugart_grp),
      selected = selected,
      multiple = T,
      options = list(plugins = list("remove_button"))
    )
  )
}

fazFilterServer <- function(id, df) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$grouped, {
      if(length(input$grouped) != 0) { 
        if(input$grouped) {
          updateSelectizeInput(
            session, "faz",
            choices = levels(obj_df$fahrzeugart_grp),
            selected = to_grp(isolate(input$faz))
          )
        } else {
          updateSelectizeInput(
            session, "faz",
            choices = levels(obj_df$fahrzeugart),
            selected = to_normal(isolate(input$faz))
          )
        }
      }
    }, ignoreInit = T)
    
    list(
      data = reactive({
        #req(input$grouped)
        # if(is.reactive(df)) df <- df()
        # fazFilterApply(df, input$faz, input$grouped)
        
        if(is.reactive(df)) {
          fazFilterApplyReactive(df, input$faz, input$grouped)
        } else {
          fazFilterApply(df, input$faz, input$grouped)
        }
      }),
      grouped = reactive({input$grouped}),
      faz = reactive({input$faz})
    )
  })
}

fazFilterApply <- function(df, input_faz, grouped) {
  
    if(grouped) {
      df <- df |>
        dplyr::mutate(faz = fahrzeugart_grp)
    } else {
      df <- df |>
        dplyr::mutate(faz = fahrzeugart)
    }

    if(length(input_faz) != 0) df <- df |> dplyr::filter(faz %in% input_faz)
    
    df
}

fazFilterApplyReactive <- function(df, input_faz, grouped) {
  if(grouped) {
    df <- df() |>
      dplyr::mutate(faz = fahrzeugart_grp)
  } else {
    df <- df() |>
      dplyr::mutate(faz = fahrzeugart)
  }
  
  if(length(input_faz) != 0) df <- df |> dplyr::filter(faz %in% input_faz)
  
  df
}


