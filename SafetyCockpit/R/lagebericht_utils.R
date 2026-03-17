make_pdf_page <- function(dt_widget, table_title, expl, impressum_lines, logo_path) {
  
  logo_src <- base64enc::dataURI(file = logo_path, mime = "image/png")
  
  legend_block <- htmltools::div(
    class = "legend",
    htmltools::div(
      class = "legend-container",
      htmltools::tags$table(
        htmltools::tags$tr(
          htmltools::tags$th("Legende:")
        ),
        htmltools::tags$tr(
          htmltools::tags$td(htmltools::div(class="legend-color", style="background: lightgreen;")),
          htmltools::tags$td("Reduktion"),
          htmltools::tags$td(htmltools::tags$b("Fg")),
          htmltools::tags$td("Fussgänger/-in")
        ),
        htmltools::tags$tr(
          htmltools::tags$td(htmltools::div(class="legend-color", style="background: orange;")),
          htmltools::tags$td("Anstieg nicht signifikant"),
          htmltools::tags$td(htmltools::tags$b("FäG")),
          htmltools::tags$td("Fahrzeugähnliches Gerät")
        ),
        htmltools::tags$tr(
          htmltools::tags$td(htmltools::div(class="legend-color", style="background: red;")),
          htmltools::tags$td("Anstieg signifikant"),
          htmltools::tags$td(htmltools::tags$b("FGS")),
          htmltools::tags$td("Fussgängerstreifen")
        )
      )
    )
  )     
  
  htmltools::tagList(
    htmltools::tags$html(
      htmltools::tags$head(
        htmltools::tags$meta(charset = "utf-8"),
        htmltools::tags$style(htmltools::HTML("
          @page { size: A4 portrait; margin: 10mm; }
          body { font-family: Arial, sans-serif; font-size: 10pt; }

          .topbar {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 6mm;
          }

          .logo { height: 70px; }

          .impressum {
            text-align: right;
            font-size: 8pt;
            line-height: 1.25;
            white-space: pre-line;  /* mantiene le righe */
            max-width: 45%;
          }

          .title {
            color: #1f77b4;
            font-size: 10pt;
            font-weight: 600;
            margin: 0 0 0 0;
          }
          
          .subtitle {
            font-size: 9pt;
            font-weight: 400;
            color: #1f77b4;
            margin: 2mm 0 4mm 0
          }
          
          
          table { width: 100%; border-collapse: collapse; font-size: 9.5px; }
          th, td { border: 1px solid #999; padding: 3px 5px; vertical-align: middle; }
          th { background: #f3f3f3; text-align: center !important; white-space: normal; }
          td { position: relative; text-align: right;}
          td span { position: absolute; inset: 0; display: flex; align-items: center; justify-content: flex-end; }
          td:first-child, th:first-child { white-space: nowrap; }
          th:not(:first-child) { width: 100px; }
          td:not(.first-child) { width: 100px; }
          
          @media print {
          .no-print { display: none !important; }
          * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
          body { padding: 0; }
          }

          .legend { margin-top: 6mm; font-size: 8.5pt; }
          .legend-container { display: flex; gap: 24px; }
          .legend table { border-collapse: collapse; table-layout: fixed; width: auto; }
          .legend th { text-align: center; vertical-align: middle; padding-bottom: 4px; }
          .legend td { text-align: center; vertical-align: middle; padding: 2px 6px; }
          .legend-color { width: 28px; height: 12px; margin: 0 auto; }
          
          .page-footer {
            position: fixed; bottom: 0; left: 0; right: 0; 
            display: flex; justify-content: space-between; align-items:center;
            padding: 6px 12px;
            font-size: 8.5px;
            color: #666;
          }
          
        "))
      ),
      htmltools::tags$body(
        htmltools::div(
          class = "topbar",
          htmltools::tags$img(src = logo_src, class = "logo"),
          htmltools::div(class = "impressum", paste(impressum_lines, collapse = "\n"))
        ),
        htmltools::tags$h1(class = "title", table_title),
        htmltools::tags$div(class = "subtitle", expl),                   
        htmltools::HTML(as.character(dt_widget)),
        legend_block,
        br(),
        htmltools::tags$div(class = "page-footer",
          htmltools::tags$div(class = "footer-left", #style = "margin-top: 30px; color: #666; font-size: 0.85em; text-align: left;", 
                                "Der Bericht wird von SafetyCockpit erstellt und ist nur für den Internen Gebrauch.",
                                tags$br(),
                                "Keine Gewähr auf Vollständigkeit."
          ),
          htmltools::tags$div(
            class = "footer-right",
            #style = "margin-top: 30px; font-size: 0.85em; color: #666; text-align: right;",
            paste0("Erstellt am ", format(Sys.Date(), "%d.%m.%Y"))
          )
        )
      )
    )
  )
}

make_static_table <- function(df,
                              maxjahr,
                              # quali 2 colonne vuoi colorare (quelle “visive”)
                              value_cols,
                              # per ciascuna value_col, qual è la colonna che contiene good/zero/warn/alert
                              status_cols = c("color_flag1", "color_flag2"),
                              drop_cols) {
  
  stopifnot(length(value_cols) == 2, length(status_cols) == 2)
  
  # colori per stato
  status_bg <- c(
    good  = "lightgreen",  # verde chiaro
    zero  = "lightgrey",  # grigio chiaro
    warn  = "orange",  # arancione chiaro
    alert = "red"   # rosso chiaro
  )
  
  # colonne anno da beige (se esistono)
  y1 <- as.character(maxjahr + 1)
  y0 <- as.character(maxjahr)
  beige <- "beige"
  
  # helper: colora una cella in base allo stato
  color_by_status <- function(value, status) {
    s <- tolower(as.character(status))
    bg <- unname(status_bg[s])
    ifelse(is.na(bg),                     # se stato mancante/inaspettato → niente colore
           kableExtra::cell_spec(as.character(value)),
           kableExtra::cell_spec(as.character(value), background = bg))
  }
  
  out <- df
  
  # 1) applica colori alle due colonne “visive” usando le rispettive colonne di stato
  out[[value_cols[1]]] <- mapply(color_by_status, out[[value_cols[1]]], out[[status_cols[1]]])
  out[[value_cols[2]]] <- mapply(color_by_status, out[[value_cols[2]]], out[[status_cols[2]]])
  
  # 2) colora le colonne anno di beige (solo se presenti)
  if (y1 %in% names(out)) out[[y1]] <- kableExtra::cell_spec(as.character(out[[y1]]), background = beige)
  if (y0 %in% names(out)) out[[y0]] <- kableExtra::cell_spec(as.character(out[[y0]]), background = beige)
  
  #out[[1]][11:23] <- kableExtra::cell_spec(out[[1]][11:23], background = "#d1fae5", extra_css = "display: inline; padding: 0; margin: 0;")
  
  out <- out |> dplyr::select(-dplyr::starts_with("chi_squared"), -dplyr::starts_with("color_"), -(drop_cols)) |> 
    dplyr::relocate(as.character(maxjahr + 1), .before = as.character(maxjahr))
  
  # 3) genera tabella HTML statica
  out |> 
    knitr::kable(format = "html", escape = FALSE) |> 
    kableExtra::kable_styling(full_width = TRUE, bootstrap_options = c("striped", "condensed"))
}
