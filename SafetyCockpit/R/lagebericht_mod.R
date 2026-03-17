lageberichtUI <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        open = T,
        width = sidebar_width,
        standardFiltersUI(ns("sfilters"), selected = "zone"),
        sliderInput(NS(id, "year"), "Beginn des Vergleichszeitraums", min = min_jahr, max = max_jahr, value = max_jahr - 2, step = 1, ticks = F, sep = ""),
        br(),
        actionButton(NS(id, "Do"), "Tabelle erstellen"),
        br(),
        br(),
        downloadButton(NS(id, "dl_xlsx"), label = "Download Excel"),
        downloadButton(NS(id, "dl_html"), label = "Download HTML File"),
        helpText("Um die PDF-Datei herunterzuladen, zuerst das HTML Dokument herunterladen, öffnen und als PDF speichern")
        
      ),
      bslib::card(
        div(infoPop(
          p("Die Änderung zum \u2205 entspricht der prozentualen Abweichung vom Durchschnitt der Vergleichsperiode. 
            Die Daten der Vorjahre werden immer gefiltert, um das aktualisierte Datum der aktuellen Daten zu berücksichtigen."),
          p("Die Farben entsprechen der Art der dargestellten Daten: Grün für negative Unterschiede (gut), Orange für nicht signifikante Unterschiede und Rot für signifikante Unterschiede.
            Die Signifikanz ist hier berechnet, gemäss eines Indikators, der aus der Chi-Quadrat-Statistik für den Vergleich zweier Zählungen abgeleitet wird und deren asymptotisches Verhalten approximiert."),
          p("Eventuelle Abkürzungen finden Sie im Wiki"),
          options = list(customClass = "mid-info")
        ),
        style = "text-align: right;"
        ),
        add_spinner(DT::DTOutput(ns("vergleichsbericht")))
      )
    )
  )
}

lageberichtServer <- function(id, unfDf, unfNewDf, objDf, objNewDf, perDf, perNewDf, maxDate, maxJahr) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(maxJahr(), {
      maxj <- maxJahr()
      #maxj <- max(unfNewDf()$Jahr)-1
      updateSliderInput(inputId = "year", value = maxJahr() - 2, max = maxj)
    })
    
    standard_out <- list(
      unf = standardFiltersServer("sfilters", unfDf, selected = "zone")$data,
      unf_new = standardFiltersServer("sfilters", unfNewDf, selected = "zone")$data,
      obj = standardFiltersServer("sfilters", objDf, selected = "zone")$data,
      obj_new = standardFiltersServer("sfilters", objNewDf, selected = "zone")$data,
      per = standardFiltersServer("sfilters", perDf, selected = "zone")$data,
      per_new = standardFiltersServer("sfilters", perNewDf, selected = "zone")$data,
      zone = standardFiltersServer("sfilters", unf_df, selected = "zone")$zone
    )
    
    unf_data <- reactive({
      tmp <- standard_out$unf()
      tmp <- tmp |> 
        dplyr::filter(Jahr >= input$year) |> 
        dplyr::bind_rows(standard_out$unf_new()) |>
        dplyr::filter(lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(maxDate())*100 + lubridate::day(maxDate()))
    }) |>
      bindCache(
        list(
          standard_out$zone(),
          input$year,
          maxDate(),
          maxJahr()
        )
      )
    
    obj_data <- reactive({
      tmp <- standard_out$obj()
      tmp <- tmp |> 
        dplyr::filter(Jahr >= input$year)|> 
        dplyr::bind_rows(standard_out$obj_new() |> dplyr::mutate(fahrzeugart_zus = dplyr::na_if(fahrzeugart_zus, "|N/A|"))) |>
        dplyr::filter(lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(maxDate())*100 + lubridate::day(maxDate()))
    }) |> 
      bindCache(
        list(
          standard_out$zone(),
          input$year,
          maxDate(),
          maxJahr()
        )
      )
    
    per_data <- reactive({
      tmp <- standard_out$per()
      tmp <- tmp |> 
        dplyr::filter(Jahr >= input$year)|> 
        dplyr::bind_rows(standard_out$per_new()) |>
        dplyr::filter(lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(maxDate())*100 + lubridate::day(maxDate()))
      
      tmp <- tmp |> 
        dplyr::left_join(obj_data() |> dplyr::select(obj_uid, fahrzeugart_zus), by = "obj_uid") |> 
        dplyr::left_join(unf_data() |> dplyr::select(unf_uid, schulweg, unfallstelle_zus), by = "unf_uid")
    }) |> 
      bindCache(
        list(
          standard_out$zone(),
          input$year,
          maxDate(),
          maxJahr()
        )
      )
    
    # end <- reactive({
    #   2 + maxJahr() - input$year - 1
    # })
      
    tbl_final <- reactive({
      end <- 2 + maxJahr() - input$year - 1
      
      summary1 <- unf_data() |> 
          dplyr::group_by(Jahr) |> 
          dplyr::summarise('Total Unfälle' = dplyr::n_distinct(unf_uid),
                           'Unfälle mit Sachschaden' = sum(ss, na.rm = T),
                           'Unfälle mit Personenschaden' = sum(ps, na.rm = T), 
                           'Verunfallte Personen' = sum(v_personen), 
                           Leichtverletzte = sum(lv_personen), 
                           Schwerverletzte = sum(sv_personen), 
                           Getötete = sum(gt_personen) 
                           # 'Unfälle mit Kindern' = sum(kinderunfall), 
                           # 'Unfälle mit Kindern auf Schulweg' = sum(kinderunfall & schulweg), 
                           # 'Unfälle mit Senioren' = sum(seniorenunfall)
          ) |> 
          tidyr::pivot_longer(cols = -Jahr, 
                              names_to = "Kategorie", 
                              values_to = "Anzahl"
          ) |> 
          tidyr::pivot_wider(names_from = Jahr, 
                             values_from = Anzahl
          ) 
      
      # summary2 <- obj_data() |> 
      #     dplyr::group_by(Jahr) |> 
      #     dplyr::summarise(
      #       'Unfälle mit Mofa/Velo/E-Bike' = dplyr::n_distinct(unf_uid[fahrzeugart_grp %in% c("Fahrrad", "E-Bike") & is.na(fahrzeugart_zus)], na.rm = T),
      #       '- Unfälle mit Velo' = dplyr::n_distinct(unf_uid[fahrzeugart == "Fahrrad"], na.rm = T),
      #       '- Unfälle mit E-Bike' = dplyr::n_distinct(unf_uid[fahrzeugart_grp == "E-Bike"], na.rm = T)
      #     ) |> 
      #     tidyr::pivot_longer(cols = -Jahr,
      #                         names_to = "Kategorie",
      #                         values_to = "Anzahl"
      #     ) |> 
      #     tidyr::pivot_wider(names_from = Jahr, 
      #                        values_from = Anzahl
      #     ) 
      
      summary3 <- per_data() |> 
          dplyr::group_by(Jahr) |> 
          dplyr::summarise(
            'Verunfallte Kinder' = dplyr::n_distinct(per_uid[alter <= 14 & schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
            'Verunfallte Kinder auf Schulweg' = dplyr::n_distinct(per_uid[alter <= 14 & schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben") & schulweg], na.rm = T),
            'Verunfallte Senioren' = dplyr::n_distinct(per_uid[alter >= 65 & schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
            'Verunfallte mit Velo/E-Bike' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fahrrad", "Langsames E-Bike", "Schnelles E-Bike") & 
                                                                        schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
            '- Leichtverletzte' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fahrrad", "Langsames E-Bike", "Schnelles E-Bike") & 
                                                              schwere %in% c("leicht verletzt")], na.rm = T),
            '- Schwerverletzte' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fahrrad", "Langsames E-Bike", "Schnelles E-Bike") & 
                                                              schwere %in% c("schwer verletzt")], na.rm = T),
            'Verunfallte Elektrotrottinett' = dplyr::n_distinct(per_uid[stringr::str_detect(fahrzeugart_zus, stringr::fixed("Elektro-Trottinett")) &
                                                                          schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
            'Verunfallte Fussgänger und FäG' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fussgänger", "FäG") & 
                                                                           schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
            '- Verunfallte Fussgänger (ohne FäG)' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fussgänger") & 
                                                                                schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
            '- Verunfallte FäG' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("FäG") & 
                                                              schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben")], na.rm = T),
            'Verunfallte Fg und FäG auf FGS' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fussgänger", "FäG") & 
                                                                           schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben") & 
                                                                           stringr::str_detect(unfallstelle_zus, stringr::fixed("Fussgängerstreifen"))], na.rm = T),
            '- Verunfallte Fg auf FGS' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("Fussgänger") & 
                                                                     schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben") & 
                                                                     stringr::str_detect(unfallstelle_zus, stringr::fixed("Fussgängerstreifen"))], na.rm = T),
            '- Verunfallte FäG auf FGS' = dplyr::n_distinct(per_uid[fahrzeugart %in% c("FäG") & 
                                                                      schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben") & 
                                                                      stringr::str_detect(unfallstelle_zus, stringr::fixed("Fussgängerstreifen"))], na.rm = T)
            
          ) |> 
          tidyr::pivot_longer(cols = -Jahr,
                              names_to = "Kategorie",
                              values_to = "Anzahl"
          ) |> 
          tidyr::pivot_wider(names_from = Jahr,
                             values_from = Anzahl
          ) 
      
      summary4 <- obj_data() |> 
          dplyr::left_join(unf_data() |> dplyr::select(unf_uid, unfallstelle_zus), by = "unf_uid") |> 
          dplyr::group_by(Jahr) |> 
          dplyr::summarise(
            # 'Unfälle mit Elektrotrotinett' = dplyr::n_distinct(unf_uid[stringr::str_detect(fahrzeugart_zus, "Elektro-Trottinett")], na.rm = T),
            # 'Unfälle mit FG (inkl. FäG)' = dplyr::n_distinct(unf_uid[fahrzeugart %in% c("Fussgänger", "FäG")], na.rm = T),
            # '- Unfälle mit FG (ohne FäG)' = dplyr::n_distinct(unf_uid[fahrzeugart == "Fussgänger"], na.rm = T),
            # '- Unfälle mit FäG' = dplyr::n_distinct(unf_uid[fahrzeugart == "FäG"], na.rm = T),
            # 'Unfälle mit FG auf FGS (inkl. FäG)' = dplyr::n_distinct(unf_uid[stringr::str_detect(unfallstelle_zus, "Fussgängerstreifen") & fahrzeugart %in% c("Fussgänger", "FäG")], na.rm = T),
            # '- Unfälle mit FG auf FGS (ohne FäG)' = dplyr::n_distinct(unf_uid[stringr::str_detect(unfallstelle_zus, "Fussgängerstreifen") & fahrzeugart %in% c("Fussgänger")], na.rm = T),
            # '- Unfälle mit FG auf FGS mit FäG' = dplyr::n_distinct(unf_uid[stringr::str_detect(unfallstelle_zus, "Fussgängerstreifen") & fahrzeugart %in% c("FäG")], na.rm = T),
            'Unfälle mit Tram' = dplyr::n_distinct(unf_uid[fahrzeugart == "Tram"], na.rm = T),
            'Unfälle mit Motorrad (inkl. Kleinmotorrad' = dplyr::n_distinct(unf_uid[fahrzeugart %in% c("Motorrad", "Kleinmotorrad")], na.rm = T),
            'Unfälle mit Personenwagen' = dplyr::n_distinct(unf_uid[fahrzeugart_grp == "Personenwagen"], na.rm = T)
          ) |> 
          tidyr::pivot_longer(cols = -Jahr,
                              names_to = "Kategorie",
                              values_to = "Anzahl"
          ) |> 
          tidyr::pivot_wider(names_from = Jahr,
                             values_from = Anzahl
          ) 
      
      summary5 <- unf_data() |> 
          dplyr::group_by(Jahr) |> 
          dplyr::summarise(
            'Unfälle in Tempo-30-Zonen' = dplyr::n_distinct(unf_uid[zonensignalisation == "Tempo-30-Zone"], na.rm = T),
            'Unfälle in Begegnungs-Zonen' = dplyr::n_distinct(unf_uid[zonensignalisation == "Begegnungszone"], na.rm = T),
            'Unfälle mit Hauptursache Alkohol' = dplyr::n_distinct(unf_uid[hauptursache == "Einwirkung von Alkohol"], na.rm = T),
            'Unfälle mit Hauptursache Geschwindigkeit' = dplyr::n_distinct(unf_uid[hauptursache_unter_grp == "Geschwindigkeit"], na.rm = T),
            'Unfälle Hauptursache Unaufmerk./Ablenkung' = dplyr::n_distinct(unf_uid[hauptursache_unter_grp == "Unaufmerksamkeit und Ablenkung"], na.rm = T)
          ) |> 
          tidyr::pivot_longer(cols = -Jahr,
                              names_to = "Kategorie",
                              values_to = "Anzahl"
          ) |> 
          tidyr::pivot_wider(names_from = Jahr,
                             values_from = Anzahl
          ) 

      tbl <- tibble::tibble(dplyr::bind_rows(summary1, summary3, summary4, summary5)) |> 
        dplyr::mutate(
          !!paste0("Differenz (%) ", maxJahr() + 1, " zu ", maxJahr()) := dplyr::if_else(.data[[as.character(maxJahr())]] == 0, round(.data[[as.character(maxJahr() + 1)]] * 100), round((.data[[as.character(maxJahr() + 1)]] - .data[[as.character(maxJahr())]]) * 100 / .data[[as.character(maxJahr())]], 0))
        ) |> 
        dplyr::rowwise() |> 
        dplyr::mutate(
          !!paste0("\u2205 ", input$year, "-", maxJahr()) := round(mean(dplyr::c_across(2:(2 + maxJahr() - input$year)), na.rm = T), 0)
        ) |> 
        dplyr::ungroup() |> 
        dplyr::mutate(
          !!paste0("Differenz (%) ", maxJahr() + 1, " zu ", "\u2205 ", input$year, "-", maxJahr()) := dplyr::if_else(.data[[paste0("\u2205 ", input$year, "-", maxJahr())]] == 0, round(.data[[as.character(maxJahr() + 1)]] * 100), round((.data[[as.character(maxJahr() + 1)]] - .data[[paste0("\u2205 ", input$year, "-", maxJahr())]]) * 100 / .data[[paste0("\u2205 ", input$year, "-", maxJahr())]], 0)) 
        ) |> 
        dplyr::mutate(
          chi_squared1 = (.data[[as.character(maxJahr() + 1)]] - .data[[as.character(maxJahr())]])^2 / (.data[[as.character(maxJahr() + 1)]] + .data[[as.character(maxJahr())]]), 
          color_flag1 = dplyr::case_when(
            .data[[paste0("Differenz (%) ", maxJahr() + 1, " zu ", maxJahr())]] < 0 ~ "good",
            .data[[paste0("Differenz (%) ", maxJahr() + 1, " zu ", maxJahr())]] == 0 ~ "zero",
            .data[[paste0("Differenz (%) ", maxJahr() + 1, " zu ", maxJahr())]] > 0 & chi_squared1 <= 3.84 ~ "warn",
            .data[[paste0("Differenz (%) ", maxJahr() + 1, " zu ", maxJahr())]] > 0 & chi_squared1 > 3.84 ~ "alert"
          ),
          .after = !!paste0("Differenz (%) ", maxJahr() + 1, " zu ", maxJahr())
        ) |> 
        dplyr::mutate(
          !!paste0("Differenz ", maxJahr() + 1, " zu ", maxJahr()) := .data[[as.character(maxJahr() + 1)]] - .data[[as.character(maxJahr())]],
          .before = as.character(paste0("Differenz (%) ", maxJahr() + 1, " zu ", maxJahr()))
        ) |> 
        dplyr::mutate(
          !!paste0("Differenz ", maxJahr() + 1, " zu ", "\u2205 ", input$year, "-", maxJahr()) := .data[[as.character(maxJahr() + 1)]] - .data[[paste0("\u2205 ", input$year, "-", maxJahr())]],
          .before = paste0("Differenz (%) ", maxJahr() + 1, " zu ", "\u2205 ", input$year, "-", maxJahr())
        ) |>
        dplyr::mutate(
          chi_squared2 = ((3 * .data[[as.character(maxJahr() + 1)]] - (rowSums(dplyr::pick(2:(end + 1)))))^2) / (3 * rowSums(dplyr::pick(2:(end + 2))))
        ) |> 
        dplyr::mutate(
          color_flag2 = dplyr::case_when(
            .data[[paste0("Differenz (%) ", maxJahr() + 1, " zu ", "\u2205 ", input$year, "-", maxJahr())]] < 0 ~ "good",
            .data[[paste0("Differenz (%) ", maxJahr() + 1, " zu ", "\u2205 ", input$year, "-", maxJahr())]] == 0 ~ "zero",
            .data[[paste0("Differenz (%) ", maxJahr() + 1, " zu ", "\u2205 ", input$year, "-", maxJahr())]] > 0 & chi_squared2 <= 3.84 ~ "warn",
            .data[[paste0("Differenz (%) ", maxJahr() + 1, " zu ", "\u2205 ", input$year, "-", maxJahr())]] > 0 & chi_squared2 > 3.84 ~ "alert"
          )
        )
      
      tbl_dt <- DT::datatable(tbl |> dplyr::relocate(as.character(maxJahr() + 1), .before = as.character(maxJahr())), 
                              options = list(
                                columnDefs = list(
                                  list(visible = F, targets = c("color_flag1", "color_flag2", "chi_squared1", "chi_squared2")),
                                  list(visible = F, targets = which(names(tbl) %in% as.character(input$year:(maxJahr() - 1)) & suppressWarnings(as.numeric(names(tbl))) < maxJahr()) - 1)
                                ),
                                pageLength = 35,
                                dom = "t",
                                ordering = F
                              ),
                              rownames = F,
                              class = "cell-border compact hover"
      ) |> DT::formatStyle(
        columns = c(as.character(maxJahr() + 1), as.character(maxJahr())),
        backgroundColor = "beige"
      ) |> 
        DT::formatStyle(
          columns = c(as.character(paste0("Differenz (%) ", maxJahr() + 1, " zu ", maxJahr()))),
          backgroundColor = DT::styleEqual(
            c("good", "zero", "warn", "alert"), 
            c("lightgreen", "lightgrey", "orange", "red")
          ),
          valueColumns = "color_flag1"
        ) |> 
        DT::formatStyle(
          columns = c(as.character(paste0("Differenz (%) ", maxJahr() + 1, " zu ", "\u2205 ", input$year, "-", maxJahr()))),
          backgroundColor = DT::styleEqual(
            c("good", "zero", "warn", "alert"), 
            c("lightgreen", "lightgrey", "orange", "red")
          ),
          valueColumns = "color_flag2"
        )|> 
        DT::formatString(
          columns = c(as.character(paste0("Differenz (%) ", maxJahr() + 1, " zu ", maxJahr())), as.character(paste0("Differenz (%) ", maxJahr() + 1, " zu ", "\u2205 ", input$year, "-", maxJahr()))),
          suffix = "%"
        ) |> 
        DT::formatCurrency(
          columns = c(as.character(maxJahr() + 1), 
                      as.character(maxJahr()), 
                      paste0("Differenz ", maxJahr() + 1, " zu ", maxJahr()),
                      paste0("\u2205 ", input$year, "-", maxJahr()),
                      paste0("Differenz ", maxJahr() + 1, " zu ", "\u2205 ", input$year, "-", maxJahr())
          ),
          currency = "",
          interval = 3,
          mark = "&#39;",
          digits = 0
        )
      
      list(tib = tbl, dt = tbl_dt)
    }) |> 
      bindCache(list(standard_out$zone(), input$year, maxDate(), maxJahr())) |> 
      bindEvent(input$Do, ignoreInit = T)
      
    output$vergleichsbericht <- DT::renderDT({
      tmp <- tbl_final()
      req(tmp$dt)
      tmp$dt
    })
    
    output$dl_xlsx <- downloadHandler(
      filename = function() {
        paste0("Lagebericht_VSI_", standard_out$zone(), "_", input$year, "_", maxDate(), ".xlsx")
      },
      content = function(file) {
        tmp <- tbl_final()
        req(tmp$tib)
        writexl::write_xlsx(tmp$tib, file)
      }
    )
    
    output$dl_html <- downloadHandler(
      filename = function() {
        paste0("Lagebericht_VSI_", standard_out$zone(), "_", input$year, "_", maxDate(), ".html")
      },
      content = function(file) {
        logo_path <- file.path(getwd(), "www", "logo_lagebericht.png")
        tmp <- tbl_final()
        req(tmp$tib)
        
        page <- make_pdf_page(
          dt_widget = make_static_table(tmp$tib, 
                                        maxjahr = maxJahr(), 
                                        value_cols = c(paste0("Differenz (%) ", maxJahr() + 1, " zu ", maxJahr()), 
                                                       paste0("Differenz (%) ", maxJahr() + 1, " zu ", "\u2205 ", input$year, "-", maxJahr())
                                        ), 
                                        drop_cols = which(names(tmp$tib) %in% as.character(input$year:(maxJahr() - 1)) & suppressWarnings(as.numeric(names(tmp$tib))) < maxJahr())
          ),
          table_title = paste0("Lagebericht Verkehrssicherheit zuhanden der Sicherheitsvorsteherin (VSI) 01.01.", 
                               input$year, "-", format(maxDate(), "%d.%m.%Y")
          ),
          expl = "(Jedes Jahr ist durch das relevante Daten Stand begrenzt)",
          impressum_lines = c(
            "Stadt Zürich",
            "Dienstabteilung Verkehr",
            "Verkehrssicherheit",
            "Mühlegasse 18/22",
            "8021 Zürich",
            " ",
            "T +41 44 411 88 01",
            "stadt-zuerich.ch/dav",
            " ",
            "Ihre Kontaktperson:",
            "Wernher Brucks",
            "D +41 44 411 88 63",
            "wernher.brucks@zuerich.ch"
          ),
          logo_path = logo_path
        )
        
        htmltools::save_html(page, file)
        
      }
    )
  })
}