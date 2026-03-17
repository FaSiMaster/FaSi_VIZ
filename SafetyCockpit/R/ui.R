# UI Elements
# NOTE: most of the UI is in safety_cockpit.R or *_mod.R files

navset_hidden_fillable <- function(..., id, padding = 1, gap = 0, header = tagList()) {
  panel <- shiny::tabsetPanel(id = id, type = "hidden", header = header, ...)
  panel$children[[3]] <- bslib:::makeTabsFillable(panel$children[[3]], padding = padding, gap = gap)
  bslib::as_fill_carrier(panel)
}

navset_bar_ktz <- function(id, title, ...) {
  bslib::navset_bar(
    id = id,
    navbar_options = bslib::navbar_options(collapsible = F),
    title = tagList(
      img(src = "www/logo.png", style = "float:left", height = "100px"),
      span(title, style = "margin-left: .5em")
    ),
    ...
  )
}

checkBox <- function(inputId, label, ...) {
  shinyWidgets::prettyCheckbox(
    inputId = inputId, label = label, status = "primary", ...
  )
}

infoPop <- function(..., size = "25px") {
  bsicons::bs_icon("info", size = size) |>
    bslib::popover(...)
}

impressum <- function(style = "font-size: 10pt;", ...){
  div(p(
    span("Kanton Zürich", style = "font-family: 'Arial Black';"), br(),
    "Baudirektion", br(),
    "Tiefbauamt", br(),
    "Strasseninspektorat", br(),
    "Fachstelle Verkehrssicherheit", br(),
    # "Telefon +41 43 259 30 71", br(),
    a(href = "mailto:sicherheit.tba@bd.zh.ch", "sicherheit.tba@bd.zh.ch"), br(),
    a(
      href = "https://www.zh.ch/verkehrssicherheit",
      "www.zh.ch/verkehrssicherheit",
      target ="_blank"
    ),
    ...
  ),
  style = style
  )
}