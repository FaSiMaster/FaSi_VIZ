
# Colors and themes -------------------------------------------------------

schwere_cols <- c(
  "Unf\u00e4lle mit Sachschaden"      = "lightsteelblue2",
  "Unf\u00e4lle mit Leichtverletzten" = "gold", #"lightgoldenrod1",
  "Unf\u00e4lle mit Schwerverletzten" = "darkgoldenrod1",
  "Unf\u00e4lle mit Get\u00f6teten"   = "tomato2",
  "nicht verletzt"  = "lightsteelblue2",
  "leicht verletzt" = "gold", #"lightgoldenrod1",
  "schwer verletzt" = "darkgoldenrod1",
  "gestorben"       = "tomato2",
  "unbekannt"       = "grey50"
)

ktz_theme <- function(){
  bslib::bs_theme(
    preset = "journal",
    bg = "white",
    fg = "black",
    primary = Akzentfarben[[1]],
    secondary = Akzentfarben[[2]],
    success = Funktion["Gr\u00fcn"],
    info = Funktion["Cyan"],
    warning = Infografiken["Orange"],
    danger = Funktion["Rot"],
    base_font = "Arial",
    # code_font = NULL,
    heading_font = "Arial Black",
    font_scale = 1.2,
    `btn-font-size` = "12pt",
    `enable-rounded` = FALSE,
    navbar_bg = Akzentfarben[[1]],
    `tooltip-max-width` = "310px",
    `accordion-bg` = "rgb(242, 242, 242)"
  )
}

sidebar_width <- 310

line_style <- list(width = 5)
marker_style <- list(size = 10, color = "white", line = list(width = 3))

