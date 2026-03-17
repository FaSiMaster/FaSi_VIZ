kapoberichtUI <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        open = T,
        width = sidebar_width,
        standardFiltersUI(ns("sfilters"), selected = "zone"),
        sliderInput(NS(id, "zehnjahr"), "Ende des Zehnjahreszeitraum", min = 2013, max = max_jahr + 1, value = max_jahr + 1, step = 1, ticks = F, sep = ""),
        sliderInput(NS(id, "monatperiod"), "Monate die berücksichtigt werden müssen", min = 1, max = 12, value = c(1, 12), step = 1, ticks = F),
        br(),
        actionButton(NS(id, "Do"), "Tabelle erstellen"),
        downloadButton(NS(id, "dl_xlsx"), label = "Download Bericht .xlsx")
      ),
      bslib::card(
        div(infoPop(
          p("Das ausgewählte Jahr markiert das Ende eines (10 Jahre) Zeitraums, über den die Analyse durchgeführt wird."),
          p("Die Daten werden immer durch die ausgewählten Monate begrenzt und falls das richtige laufende Jahr (graue Spalte) enthalten ist, sie werden aus Gründen der statistischen Korrektheit auch den aktuellen Stand berücksichtigen"),
          p("Die Durchschnitt (\u2205) wird anhand der letzten 5 Jahre berechnet."),
          p("Eventuelle Abkürzungen finden Sie im Wiki"),
          options = list(customClass = "mid-info")
        ),
        style = "text-align: right;"
        ),
        add_spinner(DT::DTOutput(ns("kapotabelle")))
      )
    )
  )
}

kapoberichtServer <- function(id, unfDf, unfNewDf, objDf, objNewDf, perDf, perNewDf, maxDate, maxJahr) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(list(maxJahr(), maxDate()), {
      maxj <- maxJahr()
      maxd <- maxDate()
      updateSliderInput(inputId = "zehnjahr", value = maxj + 1, max = maxj + 1)
      updateSliderInput(inputId = "monatperiod", value = c(1, lubridate::month(maxd)))
    })
    
    
    standard_out <- list(
      unf = standardFiltersServer("sfilters", unfDf, selected = "zone")$data,
      unf_new = standardFiltersServer("sfilters", unfNewDf, selected = "zone")$data,
      obj = standardFiltersServer("sfilters", objDf, selected = "zone")$data,
      obj_new = standardFiltersServer("sfilters", objNewDf, selected = "zone")$data,
      per = standardFiltersServer("sfilters", perDf, selected = "zone")$data,
      per_new = standardFiltersServer("sfilters", perNewDf, selected = "zone")$data,
      zone = standardFiltersServer("sfilters", unfDf, selected = "zone")$zone
    )
    
    unf_data <- reactive({
      tmp <- standard_out$unf()
      tmp <- tmp |> 
        dplyr::filter(Jahr %in% (input$zehnjahr - 9):input$zehnjahr) |>
        dplyr::filter(lubridate::month(datum) %in% input$monatperiod[1]:input$monatperiod[2])
      
      if(input$zehnjahr == (maxJahr() + 1)){
        tmp <- tmp |> 
          dplyr::bind_rows(standard_out$unf_new()) |>
            dplyr::filter(lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(maxDate())*100 + lubridate::day(maxDate())) |> 
            dplyr::filter(lubridate::month(datum) %in% input$monatperiod[1]:input$monatperiod[2])
      }
      tmp
    }) |>
      bindCache(
        list(
          standard_out$zone(),
          input$zehnjahr,
          input$monatperiod,
          maxDate(),
          maxJahr()
        )
      )
    
    obj_data <- reactive({
      tmp <- standard_out$obj()
      tmp <- tmp |> 
        dplyr::filter(Jahr %in% (input$zehnjahr - 9):input$zehnjahr) |> 
        dplyr::filter(lubridate::month(datum) %in% input$monatperiod[1]:input$monatperiod[2])
      
      if(input$zehnjahr == (maxJahr() + 1)){
        tmp <- tmp |>
          dplyr::bind_rows(standard_out$obj_new() |>
                             dplyr::mutate(fahrzeugart_zus = dplyr::na_if(fahrzeugart_zus, "|N/A|")))|>
            dplyr::filter(lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(maxDate())*100 + lubridate::day(maxDate())) |> 
            dplyr::filter(lubridate::month(datum) %in% input$monatperiod[1]:input$monatperiod[2])
      }
      tmp
    }) |> 
      bindCache(
        list(
          standard_out$zone(),
          input$zehnjahr,
          input$monatperiod,
          maxDate(),
          maxJahr()
        )
      )
    
    per_data <- reactive({
      tmp <- standard_out$per()
      tmp <- tmp |> 
        dplyr::filter(Jahr %in% (input$zehnjahr - 9):input$zehnjahr) |>
        dplyr::filter(lubridate::month(datum) %in% input$monatperiod[1]:input$monatperiod[2])
      
      if(input$zehnjahr == (maxJahr() + 1)){
        tmp <- tmp |>
          dplyr::bind_rows(standard_out$per_new()) |>
            dplyr::filter(lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(maxDate())*100 + lubridate::day(maxDate())) |> 
            dplyr::filter(lubridate::month(datum) %in% input$monatperiod[1]:input$monatperiod[2])
      }
      tmp <- tmp |> 
        dplyr::left_join(obj_data() |> dplyr::select(obj_uid, fahrzeugart_zus), by = "obj_uid") |> 
        dplyr::left_join(unf_data() |> dplyr::select(unf_uid, unfallstelle_zus, kinderunfall, seniorenunfall), by = "unf_uid")
    }) |> 
      bindCache(
        list(
          standard_out$zone(),
          input$zehnjahr,
          input$monatperiod,
          maxDate(),
          maxJahr()
        )
      )
    
    tbl_final <- reactive({
      summary1 <- unf_data() |> 
        dplyr::group_by(Jahr) |> 
        dplyr::summarise('Total Unfälle' = dplyr::n_distinct(unf_uid),
                         'Unfälle mit Sachschaden' = sum(ss, na.rm = T),
                         'Unfälle mit Personenschaden' = sum(ps, na.rm = T), 
                         'Total Verletzte' = sum(v_personen), 
                         Leichtverletzte = sum(lv_personen), 
                         Schwerverletzte = sum(sv_personen), 
                         Getötete = sum(gt_personen), 
        ) |> 
        tidyr::pivot_longer(cols = -Jahr, 
                            names_to = "Abfrage", 
                            values_to = "Anzahl"
        ) |> 
        tidyr::pivot_wider(names_from = Jahr, 
                           values_from = Anzahl
        ) 
      
      summary2 <- per_data() |> 
        dplyr::group_by(Jahr) |> 
        dplyr::summarise(
          'Fussgänger/FäG Unfälle' = dplyr::n_distinct(unf_uid[fahrzeugart %in% c("Fussgänger", "FäG")], na.rm = T),
          'Fussgänger / FäG Verunfallte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fussgänger", "FäG") & 
                                                                                          schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
          'Fussgänger / FäG Leichtverletzte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fussgänger", "FäG") & 
                                                                                            schwere %in% c("leicht verletzt")], na.rm = T),
          'Fussgänger / FäG Schwerverletzte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fussgänger", "FäG") & 
                                                                                            schwere %in% c("schwer verletzt")], na.rm = T),
          'Fussgänger / FäG Getötete (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fussgänger", "FäG") & 
                                                                                            schwere %in% c("gestorben")], na.rm = T),
          'E-Trottinett Unfälle' = dplyr::n_distinct(unf_uid[stringr::str_detect(fahrzeugart_zus, stringr::fixed("Elektro-Trottinett"))], na.rm = T),
          'E-Trottinett Verunfallte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[stringr::str_detect(fahrzeugart_zus, stringr::fixed("Elektro-Trottinett")) &
                                                                   schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
          'E-Trottinett Leichtverletzte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[stringr::str_detect(fahrzeugart_zus, stringr::fixed("Elektro-Trottinett")) &
                                                                   schwere %in% c("leicht verletzt")], na.rm = T),
          'E-Trottinett Schwerverletzte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[stringr::str_detect(fahrzeugart_zus, stringr::fixed("Elektro-Trottinett")) &
                                                                   schwere %in% c("schwer verletzt")], na.rm = T),
          'E-Trottinett Getötete (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[stringr::str_detect(fahrzeugart_zus, stringr::fixed("Elektro-Trottinett")) &
                                                                   schwere %in% c("gestorben")], na.rm = T),
          'Velo Unfälle (Lenker & Mitfahren)' = dplyr::n_distinct(unf_uid[fahrzeugart == "Fahrrad"], na.rm = T),
          'Velo Verunfallte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart == "Fahrrad" & 
                                                                              schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
          'Velo Leichtverletzte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart == "Fahrrad" & 
                                                                                    schwere %in% c("leicht verletzt")], na.rm = T),
          'Velo Schwerverletzte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart == "Fahrrad" & 
                                                                                    schwere %in% c("schwer verletzt")], na.rm = T),
          'Velo Getötete (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart == "Fahrrad" & 
                                                                                    schwere %in% c("gestorben")], na.rm = T),
          'E-Bike Unfälle (Lenker & Mitfahren)' = dplyr::n_distinct(unf_uid[fahrzeugart_grp == "E-Bike"], na.rm = T),
          'E-Bike Verunfallte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart_grp == "E-Bike" &
                                                                                  schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
          'E-Bike Leichtverletzte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart_grp == "E-Bike" &
                                                                                  schwere %in% c("leicht verletzt")], na.rm = T),
          'E-Bike Schwerverletzte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart_grp == "E-Bike" &
                                                                                  schwere %in% c("schwer verletzt")], na.rm = T),
          'E-Bike Getötete (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart_grp == "E-Bike" &
                                                                                  schwere %in% c("gestorben")], na.rm = T),
          'Motorrad Unfälle (Lenker & Mitfahren)' = dplyr::n_distinct(unf_uid[fahrzeugart == "Motorrad"], na.rm = T),
          'Motorrad Verunfallte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart == "Motorrad" &
                                                                                    schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
          'Motorrad Leichtverletzte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart == "Motorrad" &
                                                                                    schwere %in% c("leicht verletzt")], na.rm = T),
          'Motorrad Schwerverletzte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart == "Motorrad" &
                                                                                    schwere %in% c("schwer verletzt")], na.rm = T),
          'Motorrad Getötete (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart == "Motorrad" &
                                                                                    schwere %in% c("gestorben")], na.rm = T),
          'Personenwagen Unfälle' = dplyr::n_distinct(unf_uid[fahrzeugart == "Personenwagen"], na.rm = T),
          'Personenwagen Verunfallte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart == "Personenwagen" &
                                                                                         schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
          'Personenwagen Leichtverletzte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart == "Personenwagen" &
                                                                                         schwere %in% c("leicht verletzt")], na.rm = T),
          'Personenwagen Schwerverletzte (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart == "Personenwagen" &
                                                                                         schwere %in% c("schwer verletzt")], na.rm = T),
          'Personenwagen Getötete (Lenker & Mitfahren)' = dplyr::n_distinct(per_uid[fahrzeugart == "Personenwagen" &
                                                                                         schwere %in% c("gestorben")], na.rm = T)
        ) |> 
        tidyr::pivot_longer(cols = -Jahr,
                            names_to = "Abfrage",
                            values_to = "Anzahl"
        ) |> 
        tidyr::pivot_wider(names_from = Jahr, 
                           values_from = Anzahl
        )
      
      summary3 <- unf_data() |> 
        dplyr::group_by(Jahr) |> 
        dplyr::summarise(
          'Hochleistungsstrassen' = sum(is_abas, na.rm = T),
          'Baustellen' = sum(stringr::str_detect(unfallstelle_zus, stringr::fixed("Baustelle")), na.rm = T)
        ) |> 
        tidyr::pivot_longer(cols = -Jahr,
                            names_to = "Abfrage",
                            values_to = "Anzahl"
        ) |> 
        tidyr::pivot_wider(names_from = Jahr, 
                           values_from = Anzahl
        )
      
      summary4 <- per_data() |> 
        dplyr::group_by(Jahr) |> 
        dplyr::summarise(
          'Kinder Unfälle (FG & Lenker, ohne Mitfahrer)' = dplyr::n_distinct(unf_uid[alter <= 14 & personenart %in% c("Lenker/in", "Fussgänger/in", "FäG")], na.rm = T),
          'Kinder Verunfallte (FG & Lenker, ohne Mitfahrer)' = dplyr::n_distinct(per_uid[alter <= 14 & personenart %in% c("Lenker/in", "Fussgänger/in", "FäG") & schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
          'Kinder Leichtverletzte (FG & Lenker, ohne Mitfahrer)' = dplyr::n_distinct(per_uid[alter <= 14 & personenart %in% c("Lenker/in", "Fussgänger/in", "FäG") & schwere %in% c("leicht verletzt")], na.rm = T),
          'Kinder Schwerverletzte (FG & Lenker, ohne Mitfahrer)' = dplyr::n_distinct(per_uid[alter <= 14 & personenart %in% c("Lenker/in", "Fussgänger/in", "FäG") & schwere %in% c("schwer verletzt")], na.rm = T),
          'Kinder Getötete (FG & Lenker, ohne Mitfahrer)' = dplyr::n_distinct(per_uid[alter <= 14 & personenart %in% c("Lenker/in", "Fussgänger/in", "FäG") & schwere %in% c("gestorben")], na.rm = T),
          'Senioren Unfälle (FG & Lenker, ohne Mitfahrer)' = dplyr::n_distinct(unf_uid[alter >= 65 & personenart %in% c("Lenker/in", "Fussgänger/in", "FäG")], na.rm = T),
          'Senioren Verunfallte (FG & Lenker, ohne Mitfahrer)' = dplyr::n_distinct(per_uid[alter >= 65 & personenart %in% c("Lenker/in", "Fussgänger/in", "FäG") & schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
          'Senioren Leichtverletzte (FG & Lenker, ohne Mitfahrer)' = dplyr::n_distinct(per_uid[alter >= 65 & personenart %in% c("Lenker/in", "Fussgänger/in", "FäG") & schwere %in% c("leicht verletzt")], na.rm = T),
          'Senioren Schwerverletzte (FG & Lenker, ohne Mitfahrer)' = dplyr::n_distinct(per_uid[alter >= 65 & personenart %in% c("Lenker/in", "Fussgänger/in", "FäG") & schwere %in% c("schwer verletzt")], na.rm = T),
          'Senioren Getötete (FG & Lenker, ohne Mitfahrer)' = dplyr::n_distinct(per_uid[alter >= 65 & personenart %in% c("Lenker/in", "Fussgänger/in", "FäG") & schwere %in% c("gestorben")], na.rm = T),
          'Fussgänger/FäG Unfälle auf FGS' = dplyr::n_distinct(unf_uid[fahrzeugart %in% c("Fussgänger", "FäG") & stringr::str_detect(unfallstelle_zus, stringr::fixed("Fussgängerstreifen"))], na.rm = T),
          'Fussgänger/FäG Verunfallte auf FGS (FG, Lenker & Mitfahrer)' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fussgänger", "FäG") & schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben") & stringr::str_detect(unfallstelle_zus, stringr::fixed("Fussgängerstreifen"))], na.rm = T),
          'Fussgänger/FäG Leichtverletzte auf FGS (FG, Lenker & Mitfahrer)' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fussgänger", "FäG") & schwere %in% c("leicht verletzt") & stringr::str_detect(unfallstelle_zus, stringr::fixed("Fussgängerstreifen"))], na.rm = T),
          'Fussgänger/FäG Schwerverletzte auf FGS (FG, Lenker & Mitfahrer)' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fussgänger", "FäG") & schwere %in% c("schwer verletzt") & stringr::str_detect(unfallstelle_zus, stringr::fixed("Fussgängerstreifen"))], na.rm = T),
          'Fussgänger/FäG Getötete auf FGS (FG, Lenker & Mitfahrer)' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fussgänger", "FäG") & schwere %in% c("gestorben") & stringr::str_detect(unfallstelle_zus, stringr::fixed("Fussgängerstreifen"))], na.rm = T)
        ) |> 
        tidyr::pivot_longer(cols = -Jahr,
                            names_to = "Abfrage",
                            values_to = "Anzahl"
        ) |> 
        tidyr::pivot_wider(names_from = Jahr, 
                           values_from = Anzahl
        )
      
      tbl <- tibble::tibble(dplyr::bind_rows(summary1, summary2, summary3, summary4)) |> 
        dplyr::rowwise() |>
        dplyr::mutate(
          '\u2205 5J' = round(mean(dplyr::c_across(as.character((input$zehnjahr - 4):input$zehnjahr)), na.rm = T), 0)
        ) |>
        dplyr::ungroup() |>
        dplyr::mutate(
          "Differenz zum \u2205" = round(.data[[as.character(input$zehnjahr)]] - .data[['\u2205 5J']], 0)
        ) |>
        dplyr::mutate(
          "Differenz zum \u2205 [%]" = dplyr::if_else(.data[['\u2205 5J']] == 0, NA, round((.data[[as.character(input$zehnjahr)]] - .data[['\u2205 5J']]) * 100 / .data[['\u2205 5J']], 1))
        ) |>
        dplyr::mutate(
          "Differenz zum Vorjahr" = round(.data[[as.character(input$zehnjahr)]] - .data[[as.character(input$zehnjahr - 1)]], 0)
        ) |> 
        dplyr::mutate(
          "Differenz zum Vorjahr [%]" = dplyr::if_else(.data[[as.character(input$zehnjahr - 1)]] == 0, NA, round((.data[[as.character(input$zehnjahr)]] - .data[[as.character(input$zehnjahr - 1)]]) * 100 / .data[[as.character(input$zehnjahr - 1)]], 1))
        )
      
      tbl_dt <- DT::datatable(tbl, 
                              options = list(
                                pageLength = nrow(tbl),
                                dom = "t",
                                ordering = F
                              ),
                              rownames = F,
                              class = "cell-border compact hover"
      ) |> 
        DT::formatString(
          columns = c("Differenz zum \u2205 [%]", "Differenz zum Vorjahr [%]"),
          suffix = "%"
        ) |> 
        DT::formatCurrency(
          columns = c(2:13, 15),
          currency = "",
          interval = 3,
          mark = "&#39;",
          digits = 0
        )
      
      if (as.character(max_jahr + 1) %in% names(tbl)) {
        tbl_dt <- tbl_dt |> 
          DT::formatStyle(
            columns = c(as.character(max_jahr + 1)),
            backgroundColor = "lightgrey"
          )
      }
      
      list(tib = tbl, dt = tbl_dt)
    }) |> 
      bindCache(list(standard_out$zone(), input$zehnjahr, input$monatperiod, maxDate(), maxJahr())) |> 
      bindEvent(input$Do, ignoreInit = T)
    
    output$kapotabelle <- DT::renderDT({
      tmp <- tbl_final()
      req(tmp$dt)
      tmp$dt
    })
    
    output$dl_xlsx <- downloadHandler(
      filename = function() {
        paste0("Lagebericht_", 
               standard_out$zone(), "_", 
               input$zehnjahr - 9, "-", input$zehnjahr, "_", 
               input$monatperiod[1], "-", input$monatperiod[2], ".xlsx"
        )
      },
      content = function(file) {
        tmp <- tbl_final()
        req(tmp$tib)
        
        wb <- openxlsx::createWorkbook()
        openxlsx::addWorksheet(wb, "Daten")
        openxlsx::writeData(wb, "Daten", tmp$tib)
        
        openxlsx::setColWidths(wb, "Daten", cols = 1, widths = "57.00")
        openxlsx::setColWidths(wb, "Daten", cols = 2:ncol(tmp$tib), widths = "10.00")
        #openxlsx::setRowHeights(wb, "Daten", rows = c(9,40,43), heights = 7, wrap = TRUE)
        
        style_rechts <- openxlsx::createStyle(halign = "right")
        openxlsx::addStyle(wb, "Daten", style_rechts, rows = 1:(nrow(tmp$tib) + 1), cols = 2:16, gridExpand = TRUE, stack = TRUE)
        
        style_allgemein1 <- openxlsx::createStyle(fgFill = "#A6A6A6")
        style_allgemein2 <- openxlsx::createStyle(fgFill = "#F2F2F2")
        style_fussgaenger1 <- openxlsx::createStyle(fgFill = "#C6E0B4")
        style_fussgaenger2 <- openxlsx::createStyle(fgFill = "#E2EFDA")
        style_etrotti1 <- openxlsx::createStyle(fgFill = "#F4B084")
        style_etrotti2 <- openxlsx::createStyle(fgFill = "#F8CBAD")
        style_velo1 <- openxlsx::createStyle(fgFill = "#B4C6E7")
        style_velo2 <- openxlsx::createStyle(fgFill = "#D9E1F2")
        style_ebike1 <- openxlsx::createStyle(fgFill = "#FFE699")
        style_ebike2 <- openxlsx::createStyle(fgFill = "#FFF2CC")
        style_motorrad1 <- openxlsx::createStyle(fgFill = "#ACB9CA")
        style_motorrad2 <- openxlsx::createStyle(fgFill = "#D6DCE4")
        style_pw1 <- openxlsx::createStyle(fgFill = "#F8CBAD")
        style_pw2 <- openxlsx::createStyle(fgFill = "#FCE4D6")
        style_kinder1 <- openxlsx::createStyle(fgFill = "#A9D08E")
        style_kinder2 <- openxlsx::createStyle(fgFill = "#C6E0B4")
        style_senioren1 <- openxlsx::createStyle(fgFill = "#8EA9DB")
        style_senioren2 <- openxlsx::createStyle(fgFill = "#B4C6E7")
        style_fgfgs1 <- openxlsx::createStyle(fgFill = "#FFD966")
        style_fgfgs2 <- openxlsx::createStyle(fgFill = "#FFE699")
        style_divider <- openxlsx::createStyle(border = "bottom", borderStyle = "thick", borderColour = "black")
        style_perc <- openxlsx::createStyle(numFmt = "0.0\"%\"")
        
        openxlsx::addStyle(wb, "Daten", style_divider, rows = c(8,38,40), cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_allgemein1, rows = c(2,5,8), cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_allgemein2, rows = c(3,4,6,7), cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_fussgaenger1, rows = 9, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_fussgaenger2, rows = 10:13, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_etrotti1, rows = 14, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_etrotti2, rows = 15:18, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_velo1, rows = 19, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_velo2, rows = 20:23, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_ebike1, rows = 24, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_ebike2, rows = 25:28, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_motorrad1, rows = 29, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_motorrad2, rows = 30:33, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_pw1, rows = 34, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_pw2, rows = 35:38, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_kinder1, rows = 41, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_kinder2, rows = 42:45, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_senioren1, rows = 46, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_senioren2, rows = 47:50, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_fgfgs1, rows = 51, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_fgfgs2, rows = 52:55, cols = 1:16, gridExpand = TRUE, stack = TRUE)
        openxlsx::addStyle(wb, "Daten", style_perc, rows = 2:55, cols = c(14, 16), gridExpand = T, stack = T)
        
        openxlsx::saveWorkbook(wb, file, overwrite = TRUE)
      }
    )
  })
}