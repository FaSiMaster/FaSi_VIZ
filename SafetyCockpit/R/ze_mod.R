
zeTableUI <- function(id, filters = NULL) {
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        open = F,
        width = sidebar_width,
        standardFiltersUI(
          ns("sf"), selected = c("zone", "zeitraum"),
          filters = filters
        ),
        downloadButton(NS(id, "download_table"), label = "Download")
      ),
      bslib::layout_columns(
        bslib::card(htmlOutput(NS(id, "ze_phrase"))),
        bslib::card(
          DT::DTOutput(NS(id, "ze_table"))
        ),
        col_widths = c(12, 12),
        row_heights = c(1, 11)
      )
    )
  )
}

zeTableServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    sfOut <- standardFiltersServer("sf", df = unf_df, selected = c("zone", "zeitraum"))
    
    zeitraumString <- reactive({
      if(sfOut$zeitraum()[1] == sfOut$zeitraum()[2]) {
        as.character(sfOut$zeitraum()[1])
      } else {
        paste(sfOut$zeitraum()[1], sfOut$zeitraum()[2], sep="-")
      }
    })
    
    where <- reactive({
      switch(
        sfOut$zone(),
        "Gesamte Kanton"    = c("im Kanton ZH", "auf Z\u00fcrcher Strassen"),
        "Ohne St\u00e4dte"  = paste(
          c("im Kanton ZH", "auf Z\u00fcrcher Strassen"),
          "ausser Z\u00fcrich und Winterthur"
        ),
        "Staatsstrassen"    = rep("auf Kantonsstrassen ausser Z\u00fcrich und Winterthur", 2),
        "Stadt Z\u00fcrich" = c("in der Stadt Z\u00fcrich", "auf Strassen in der Stadt Z\u00fcrich"),
        "Stadt Winterthur"  = c("in der Stadt Winterthur", "auf Strassen in der Stadt Winterthur"),
        "Autobahn"          = rep("auf den Autobahnen und Autostrassen des Kantons Z\u00fcrich", 2)
      )
    })
    
    zeTableData <- reactive({
      # Standard filters
      ze_data <- sfOut$data()
      
      ze_data <- ze_data |> 
        ze_summary() |>
        tidyr::pivot_longer(tidyr::everything(), names_to = "Was", values_to = "current") |> 
        dplyr::mutate(current = as.integer(current))
      
      if(nrow(ze_data) == 0) {
        validate("Keine Daten")
      }
      
      ze_data <- ze_data |> 
        dplyr::mutate(
          # diff_prz = (current - comp) / (comp),
          `Pro Tag` = current / n_days(sfOut$zeitraum()[1], sfOut$zeitraum()[2]),
          `Pro Stunde` = `Pro Tag` / 24,
          `Pro Minute` = `Pro Stunde` / 60,
          `Alle x Tage` = 1 / `Pro Tag`,
          `Alle x Stunden` = 1 / `Pro Stunde`,
          `Alle x Minuten` = 1 / `Pro Minute`,
        )
      
      ze_data
    })
    
    output$ze_table <- DT::renderDT({
      DT::datatable(
        zeTableData(),
        # class = list(stripe = F),
        style = "bootstrap",
        fillContainer = T,
        options = list(
          dom = 'ft', pageLength = nrow(zeTableData()),
          columnDefs = list(list(visible = F, targets = 1), list(searchable = F, targets = 2:8)),
          language = list(search = "Suche:")
        ),
        rownames = c("Total Unf\u00e4lle", "Unf\u00e4lle mit Personenschaden", 
                     "Unf\u00e4lle ohne Personenschaden", "Unf\u00e4lle mit Leichtverletzten",
                     "Unf\u00e4lle mit Schwerverletzten", "T\u00f6dliche Unf\u00e4lle", 
                     "Leicht verletzte Personen", "Schwer verletzte Personen",
                     "Get\u00f6tete Personen", "Verletzte Personen",  "Unf\u00e4lle innerorts",
                     "Unf\u00e4lle innerorts mit Personenschaden", "Unf\u00e4lle ausserorts",
                     "Unf\u00e4lle ausserorts mit Personenschaden", 
                     "Unf\u00e4lle auf einer Autobahn", "Unf\u00e4lle auf einer Autobahn mit Personenschaden",
                     "Kinderunf\u00e4lle auf dem Schulweg", "Velounf\u00e4lle",
                     "Unf\u00e4lle mit Hauptursache Alkohol",
                     "Unf\u00e4lle mit Hauptursache erh\u00f6hten Geschwindigkeit",
                     "Unf\u00e4lle mit Hauptursache Alkohol oder erh\u00f6hten Geschwindigkeit",
                     "Get\u00f6tete E-Bikers"),
        colnames = setNames(
          c(1, 3),
          c("Was", paste0("Anzahl (", zeitraumString(), ")"))
        ),
        selection = list(target = "cell", mode = "single")
      ) |>
        DT::formatRound(3:8, digits = 1, mark = "'") |> 
        DT::formatRound(2, digits = 0, mark = "'")
    })
    
    output$ze_phrase <- renderText({
      value <- input$ze_table_cell_clicked$value
      
      if(is.null(value)) validate("W\u00e4hlen Sie eine Zelle aus, um einen Satz dar\u00fcber anzuzeigen")
      
      value <- format(value, digits = 3, big.mark = "'", scientific = F)
      
      row_name <- zeTableData()[[input$ze_table_cell_clicked$row, 1]]
      if(input$ze_table_cell_clicked$col == 0) col_name <- names(zeTableData())[1]
      else col_name <- names(zeTableData())[input$ze_table_cell_clicked$col]
      
      phrase <- paste0(p(tags$b(value)))
      
      if(stringr::str_starts(col_name, "Alle")) {
        passiert <- switch(
          row_name,
          total = paste("wird ein Unfall", sample(where(), 1), "durch die Polizei erfasst"),
          ps = paste("wird ein Unfall mit Personenschaden", sample(where(), 1), "durch die Polizei erfasst"),
          ss = paste("wird ein Unfall ohne Personenschaden", sample(where(), 1), "durch die Polizei erfasst"),
          lv = paste("wird ein Unfall mit leichtverletzten Personen", sample(where(), 1), "durch die Polizei erfasst"),
          sv = paste("wird ein Unfall mit schwerverletzten Personen", sample(where(), 1), "durch die Polizei erfasst"),
          gt = paste("wird ein t\u00f6dliche Unfall", sample(where(), 1), "durch die Polizei erfasst"),
          lv_personen = paste("wird jemand", where()[2], "leicht verletzt"),
          sv_personen = paste("wird jemand", where()[2], "schwer verletzt"),
          gt_personen = paste("stirbt jemand", where()[2]),
          v_personen = paste("wird jemand", where()[2], "verletzt"),
          io = paste("wird innerorts", where()[1] ,"ein Unfall durch die Polizei erfasst"),
          io_ps = paste("wird innerorts", where()[1] ,"ein Unfall mit Personenschaden durch die Polizei erfasst"),
          ao = paste("wird ausserorts", where()[1] ,"ein Unfall durch die Polizei erfasst"),
          ao_ps = paste("wird ausserorts", where()[1] ,"ein Unfall mit Personenschaden polizeilich aufgenommen"),
          abas = paste("wird auf einer Autobahn", where()[1] ,"ein Unfall durch die Polizei erfasst"),
          abas_ps = paste("wird auf einer Autobahn", where()[1] ,"ein Unfall mit Personenschaden polizeilich erfasst"),
          schulweg = paste("verunfallt", where()[1] ,"ein Kind auf dem Schulweg"),
          velo = paste("verunfallt", where()[2],"ein Velofahrer"),
          hu_alk = paste("gibt es einen Unfall wegen Alkohol", where()[2]),
          hu_geschw = paste("gibt es einen Unfall wegen erh\u00f6hten Geschwindigkeit", where()[2]),
          hu_alkgeschw = paste("gibt es einen Unfall wegen Alkohol oder erh\u00f6hten Geschwindigkeit", where()[2]),
          gt_ebikers = paste("stirbt ein E-Biker", where()[2]),
          row_name
        )
        phrase <- paste0(p(
          "Alle", tags$b(value, stringr::str_extract(col_name, "x\\s*(.+)", group = 1)), passiert
        ))
      } else if(stringr::str_starts(col_name, "Pro") | col_name == "current") {
        start <- dplyr::case_match(
          col_name,
          "Pro Tag"    ~ "An einem Tag gibt es",
          "Pro Stunde" ~ "Jede Stunde gibt es",
          "Pro Minute" ~ "Pro Minute gibt es",
          "current" ~ "Es gab",
          .default = paste(col_name, "gibt es")
        )
        typ <- switch(
          row_name,
          total = "Unf\u00e4lle",
          ps = "Unf\u00e4lle mit Personenschaden",
          ss = "Unf\u00e4lle ohne Personenschaden",
          lv = "Unf\u00e4lle mit Leichtverletzten",
          sv = "Unf\u00e4lle mit Schwerverletzten",
          gt = "T\u00f6dliche Unf\u00e4lle",
          lv_personen = "Leicht verletzte Personen",
          sv_personen = "Schwer verletzte Personen",
          gt_personen = "Get\u00f6tete Personen",
          v_personen = "Verletzte Personen",
          io = "Unf\u00e4lle innerorts",
          io_ps = "Unf\u00e4lle innerorts mit Personenschaden",
          ao = "Unf\u00e4lle ausserorts",
          ao_ps = "Unf\u00e4lle ausserorts mit Personenschaden",
          abas = "Unf\u00e4lle auf einer Autobahn",
          abas_ps = "Unf\u00e4lle auf einer Autobahn mit Personenschaden",
          schulweg = "Kinderunf\u00e4lle auf dem Schulweg",
          velo = "Velounf\u00e4lle",
          hu_alk = "Unf\u00e4lle mit Hauptursache Alkohol",
          hu_geschw = "Unf\u00e4lle mit Hauptursache erh\u00f6hten Geschwindigkeit",
          hu_alkgeschw = "Unf\u00e4lle mit Hauptursache Alkohol oder erh\u00f6hten Geschwindigkeit",
          gt_ebikers = "Get\u00f6tete E-Bikers",
          row_name
        )
        when <- dplyr::if_else(
          col_name == "current",
          dplyr::if_else(
            sfOut$zeitraum()[1] == sfOut$zeitraum()[2],
            paste("in", sfOut$zeitraum()[1]),
            paste("zwischen", sfOut$zeitraum()[1], "und", sfOut$zeitraum()[2])
          ),
          ""
        )
        phrase <- paste0(p(
          start, tags$b(value), typ, sample(where(), 1), when
        ))
      }
      phrase
    })
    
    output$download_table <- downloadHandler(
      filename = function() {
        paste0("Zeiteinheiten_", zeitraumString(),".xlsx")
      },
      content = function(file) {
        writexl::write_xlsx(zeTableData(), file)
      }
    )
  })
}