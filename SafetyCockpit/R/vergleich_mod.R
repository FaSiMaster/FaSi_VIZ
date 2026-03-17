# TODO 
# - refactor tableData to be only the composition of two other reactives (year1 and year2)
# - rename year1 and year2

interpreter <- setNames(
  c("Total Unf\u00e4lle", "Unf\u00e4lle mit Personenschaden",
    "Unf\u00e4lle ohne Personenschaden", "Unf\u00e4lle mit Leichtverletzten",
    "Unf\u00e4lle mit Schwerverletzten", "T\u00f6dliche Unf\u00e4lle",
    "Leicht verletzte Personen", "Schwer verletzte Personen",
    "Get\u00f6tete", "Verletzte Personen",  "Unf\u00e4lle innerorts",
    "Unf\u00e4lle innerorts mit Personenschaden", "Unf\u00e4lle ausserorts",
    "Unf\u00e4lle ausserorts mit Personenschaden",
    "Unf\u00e4lle auf einer Autobahn", "Unf\u00e4lle auf einer Autobahn mit Personenschaden",
    "Kinderunf\u00e4lle auf dem Schulweg", "Velounf\u00e4lle",
    "Unf\u00e4lle mit Hauptursache Alkohol",
    "Unf\u00e4lle mit Hauptursache erh\u00f6hten Geschwindigkeit",
    "Unf\u00e4lle mit Hauptursache Alkohol oder erh\u00f6hten Geschwindigkeit",
    "Get\u00f6tete E-Bikers"),
  c("total", "ps", "ss", "lv", "sv", "gt", "lv_personen", "sv_personen", 
    "gt_personen", "v_personen", "io", "io_ps", "ao", "ao_ps", "abas", 
    "abas_ps", "schulweg", "velo", "hu_alk", "hu_geschw", "hu_alkgeschw", 
    "gt_ebikers")
)

vergleichUI <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        open = F,
        width = sidebar_width,
        numericInput(NS(id, "year"), "Jahr", max_jahr, min_jahr, max_jahr),
        sliderInput(
          NS(id, "cperiod"), "Vergleichszeitraum", min_jahr, max_jahr-1,
          c(max_jahr-4, max_jahr - 1),
          sep = "", ticks = F
        ),
        standardFiltersUI(ns("sf"), selected = "zone"),
        downloadButton(NS(id, "download_table"), label = "Download")
      ),
      bslib::card(
        div(infoPop(
          p("Der lineare Trend wird für den gewählten Vergleichszeitraum und das 
          gewählte Jahr durch lineare Regression berechnet."),
          p("Die Änderung zum Ø entspricht der prozentualen Abweichung vom Durchschnitt der Vergleichsperiode."),
          options = list(customClass = "mid-info")
          ),
          style = "text-align: right;"
        ),
        DT::DTOutput(ns("vergleich_table"))
      )
    )
  )
}

vergleichServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$year, {
      req(input$year)
      # input validation
      shinyFeedback::hideFeedback("year")
      if((input$year < min_jahr) | (input$year > max_jahr)) {
        shinyFeedback::feedbackWarning(
          "year", T,
          paste("Bitte w\u00e4hlen Sie ein Jahr zwischen", min_jahr, "und", max_jahr, "aus"),
          color = unname(bslib::bs_get_variables(bslib::bs_current_theme(), "warning"))
        )
      } else if (!is.integer(input$year)) {
        shinyFeedback::feedbackWarning(
          "year", T, "Bitte geben Sie eine ganze Zahl ein",
          color = unname(bslib::bs_get_variables(bslib::bs_current_theme(), "warning"))
        )
      }
      updateSliderInput(
        inputId = "cperiod", max = min(input$year-1, max_jahr-1),
        value = c(
          max(min(input$year-1, max_jahr-1)-3, min_jahr),
          min(input$year-1, max_jahr - 1)
        )
      )
    }, ignoreInit = T)
    
    sfOut <- standardFiltersServer("sf", df = unf_df, selected = "zone")
    
    zoneData <- reactive({
      sfOut$data()
    })
    
    yearData <- reactive({
      year_data <- zoneData() |> 
        dplyr::filter(Jahr == input$year)|>
        dplyr::group_by(Jahr) |> 
        ze_summary() |>
        tidyr::pivot_longer(!Jahr, names_to = "Was", values_to = "year") |> 
        dplyr::select(!Jahr) |> 
        dplyr::mutate(year = as.integer(year))
      
      if(nrow(year_data) == 0) validate("Keine Daten")
      
      year_data
    })
    
    cperiodData <- reactive({
      cperiod_data <- purrr::map_dfc(
        input$cperiod[1]:input$cperiod[2], 
        \(x) zoneData() |> 
          dplyr::filter(Jahr == x) |> 
          dplyr::group_by(Jahr) |> 
          ze_summary() |>
          tidyr::pivot_longer(!Jahr, values_to = as.character(x)) |>
          dplyr::select(!c(Jahr, name))
      )
      cperiod_data <- cperiod_data |> 
        # dplyr::mutate(Was = year_1$Was) |> 
        # dplyr::relocate(Was) |> 
        dplyr::rowwise() |> 
        dplyr::mutate(
          period_mean = mean(dplyr::c_across(dplyr::where(is.numeric)))
        )
      
      if(nrow(cperiod_data) == 0) validate("Keine Daten")
      
      cperiod_data
    })
    
    tableData <- reactive({
      # browser()
      table_data <-  
        cbind(cperiodData(), isolate(yearData())) |> 
        dplyr::relocate(Was) |>
        dplyr::mutate(
          "Änderung zum Ø" = (year - period_mean) / year,
        ) |>  
        tidyr::pivot_longer(!c(Was, period_mean, `Änderung zum Ø`)) |>
        dplyr::mutate(
          number = dplyr::if_else(name == "year", as.character(isolate(input$year)), name),
          number = as.numeric(number)
        ) |> 
        dplyr::group_by(Was) |>
        dplyr::mutate(`Linearer Trend` = lm(value~number)$coefficients[2]) |>
        dplyr::select(!number) |> 
        tidyr::pivot_wider(names_from = name, values_from = value)
      
      table_data <- table_data |> 
        dplyr::rename(Durchschnitt = period_mean) |> 
        dplyr::relocate(5:(ncol(table_data)-1), .after = Was) |> 
        dplyr::relocate(ncol(table_data), .after = Durchschnitt)
      
      table_data
    })
    
    output$vergleich_table <- DT::renderDT({
      
      DT::datatable(
        tableData(),
        style = "bootstrap",
        fillContainer = T,
        options = list(
          dom = 'ft', pageLength = nrow(tableData()),
          columnDefs = list(
            list(visible = F, targets = "Was"),
            list(searchable = F, targets = 2:ncol(tableData()))
          ),
          language = list(search = "Suche:")
        ),
        rownames = interpreter,
        colnames = setNames(
          c("year"),
          c(isolate(input$year))
        ),
        selection = list(target = "cell", mode = "single")
        # caption = htmltools::tags$caption("INFO", infoPop("MORE INFO"), style = 'caption-side: top;')
        # caption = tags$caption(("Info"), style = 'caption-side: top; text-align: center; color:black;  font-size:200% ;')
      ) |>
        DT::formatRound(2:(ncol(tableData())-2), digits = 0, mark = "'") |>
        DT::formatRound(c(ncol(tableData())-3, ncol(tableData())), digits = 1, mark = "'") |>
        DT::formatStyle(c(ncol(tableData())-3, ncol(tableData())-2), fontWeight = "bold") |> 
        DT::formatPercentage(ncol(tableData())-1, digits = 2) |>
        DT::formatStyle(
          c(ncol(tableData())-1, ncol(tableData())),
          color = DT::styleInterval(0, c(Infografiken["Gr\u00fcn"], Infografiken["Rot"]))
        )
    })
    
    output$download_table <- downloadHandler(
      filename = function() {
        paste0("Vergleich_Tabelle_", sfOut$zone(), "_", input$year, "_", input$cperiod[1], "-",input$cperiod[2],".xlsx")
      },
      content = function(file) {
        pretty_table_data <- tableData() |> 
          dplyr::rename(!!as.character(input$year) := year) |> 
          dplyr::mutate(Was = interpreter[[Was]])
        writexl::write_xlsx(pretty_table_data, file)
      }
    )
  })
}
