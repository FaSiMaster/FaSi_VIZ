
bsmUI <- function(id, filters = NULL) {
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        open = F, width = sidebar_width,
        standardFiltersUI(ns("sf"), selected = c("zeitraum", "zone"), filters = filters),
        actionButton(ns("calc"), "Tabelle erstellen")
      ),
      bslib::card(
        bslib::card_header(
          #div(
            #class = "d-flex justify-content-between align-items-center",
            textOutput(ns("bsm_title")),
            infoPop(
              p("Alle Merkmale ausser denen mit der Name Fahrzeug-/Objektart beziehen sich auf die Gesamtzahl der Unfälle: 
                X % der Unfälle betraften Kinder, oder X % der Unfälle werden von Senioren verursacht. Im Gegenteil: X % der beteiligte Fahrzeuge waren Velo und E-Bike."),
              p("Merkmal 'Fahrpraxis' betrachtet die Hauptursache; 'Zustand' und 'Verhalten' betrachten alle mögliche Ursachen."),
              options = list(customClass = "mid-info")
            ),
            class = "d-flex justify-content-between"
          #)
        ),
        add_spinner(DT::DTOutput(ns("bsm_table")))
      )
    )
  )
}

bsmServer <- function(id, res = \(x) NULL) {
  moduleServer(id, function(input, output, session) {
    observeEvent(res(), {
      shinyjs::reset("sidebar")
    }, ignoreInit =  T)
    
    filterOut_unf <- standardFiltersServer("sf", unf_df, selected = c("zeitraum", "zone"))
    filterOut_obj <- standardFiltersServer("sf", obj_df, selected = c("zeitraum", "zone"))
    filterOut_per <- standardFiltersServer("sf", per_df, selected = c("zeitraum", "zone"))
    
    safe_div <- function(num, den) ifelse(den > 0, num / den, NA_real_)
    
    join_obj_tbl <- reactive({
      filterOut_obj$data() |> 
        dplyr::group_by(unf_uid) |> 
        dplyr::summarise(is_alkdrogarzt_2 = any(ursache_2 %in% c("Einwirkung von Alkohol", "Einwirkung von Betäubungsmittel", "Einwirkung von Arzneimittel"), na.rm = T), 
                         is_alkdrogarzt_3 = any(ursache_3 %in% c("Einwirkung von Alkohol", "Einwirkung von Betäubungsmittel", "Einwirkung von Arzneimittel"), na.rm = T),
                         is_nongeschw_2 = any(ursache_2 == "Nichtanpassen an die Strassenverhältnisse (nass, vereist, Rollsplitt, Laub, usw.)", na.rm = T),
                         is_nongeschw_3 = any(ursache_3 == "Nichtanpassen an die Strassenverhältnisse (nass, vereist, Rollsplitt, Laub, usw.)", na.rm = T),
                         is_tel_2 = any(ursache_2 %in% c("Ablenkung durch Bedienung des Telefons", 
                                                         "Ablenkung durch Bedienung technischer Geräte im Fahrzeug (Radio, Navigationssystem, Heizung, usw.)"), na.rm = T),
                         is_tel_3 = any(ursache_3 %in% c("Ablenkung durch Bedienung des Telefons", 
                                                         "Ablenkung durch Bedienung technischer Geräte im Fahrzeug (Radio, Navigationssystem, Heizung, usw.)"), na.rm = T),
                         is_anprall = any(stringr::str_detect(anprall, "Mittelinsel|korrekt parkiertes Fahrzeug|Mauer|Schild|Baum|Böschung"), na.rm = T),
                         .groups = "drop"
        )
    }) |> 
      bindCache(
        list(
          filterOut_obj$zeitraum(),
          filterOut_obj$zone()
        )
      )
    
    baseData_unf <- reactive({
      filterOut_unf$data() |> 
        dplyr::left_join(join_obj_tbl(), by = "unf_uid")
    }) |> 
      bindCache(
        list(
          filterOut_unf$zeitraum(),
          filterOut_unf$zone()
        )
      )
    
    baseData_obj <- reactive({
      filterOut_obj$data() |> 
        dplyr::left_join(filterOut_unf$data() |> dplyr::select(unf_uid, strassenart), by = "unf_uid")
    }) |> 
      bindCache(
        list(
          filterOut_obj$zeitraum(),
          filterOut_obj$zone()
        )
      )
    
    baseData_per <- reactive({
      filterOut_per$data() |>
        dplyr::left_join(filterOut_unf$data() |> dplyr::select(unf_uid, strassenart, kinderunfall, schulweg), by = "unf_uid")
    }) |> 
      bindCache(
        list(
          filterOut_per$zeitraum(),
          filterOut_per$zone()
        )
      )
    
    grp_defs <- tibble::tibble(
      grp = c("allg", "abas", "ao", "io", "haupt", "neb"),
      grp_label = c("Allgemein", "Autobahn/Autostrasse", "Ausserorts", "Innerorts", "Hauptstrassen", "Nebenstrassen"),
      grp_flag  = c(NA, "is_abas", "is_ao", "is_io", "is_haupt", "is_neb")
    )
    
    tableData_unf <- reactive({
      temp <- baseData_unf()
      req(!is.null(temp), nrow(temp) > 0)

      temp <- temp |>
        dplyr::mutate(
          stunde = as.integer(stunde),
          is_io = (ioao == "innerorts"),
          is_ao = (ioao == "ausserorts"),
          is_haupt = (strassenart == "Hauptstrasse"),
          is_neb = (strassenart == "Nebenstrasse"),
          is_wknd = lubridate::wday(datum, week_start = 1) %in% c(6, 7),
          
          is_som  = lubridate::month(datum) %in% c(6, 7, 8),
          is_winter = lubridate::month(datum) %in% c(12, 1, 2),
          
          is_spst = ((6 <= stunde & stunde <= 9) | (16 <= stunde & stunde <= 19)) & !is_wknd,
          is_msp = (6 <= stunde & stunde < 9) & !is_wknd,
          is_asp = (16 <= stunde & stunde < 19) & !is_wknd,
          
          is_schwach = (verkehrsaufkommen == "schwach"),
          is_stau = (verkehrsaufkommen == "stockende Kolonne"),
          
          is_nass    = (strassenzustand %in% c("nass", "feucht")),
          is_schnee  = (strassenzustand %in% c("Schneebedeckt", "vereist")),
          is_mark = (hauptursache == "Mangelhafte Signalisation oder Markierung"),
          
          is_bel = (strassenbeleuchtung %in% c("keine", "ausser Betrieb")),
          
          is_vort = (vortrittsregelung == "Rechtsvortritt"),
          
          is_fgs = (stringr::str_detect(unfallstelle_zus, stringr::fixed("|Fussgängerstreifen|"))),
          is_trott = (stringr::str_detect(unfallstelle_zus, stringr::fixed("|Trottoir|"))),
          is_bau = (stringr::str_detect(unfallstelle_zus, stringr::fixed("|Baustelle|"))),
          #is_anpr = (stringr::str_detect(anprall, "Mittelinsel|Inselpfosten|korrekt parkiertes Fahrzeug|Zaun|Mauer|Schild|Baum|Böschung")),

          is_reg = (witterung == "Regen"),
          is_schneefall = (witterung %in% c("Schneefall", "vereisender Regen")),
          is_dunkel  = (lichtverhaeltnis %in% c("Dämmerung", "Nacht")),
          
          is_alkdrogarzt = (hauptursache %in% c("Einwirkung von Alkohol", "Einwirkung von Betäubungsmittel", "Einwirkung von Arzneimittel") |
                            is_alkdrogarzt_2 |
                            is_alkdrogarzt_3
                            #ursache_2 %in% c("Einwirkung von Alkohol", "Einwirkung von Betäubungsmittel", "Einwirkung von Arzneimittel") |
                            #ursache_3 %in% c("Einwirkung von Alkohol", "Einwirkung von Betäubungsmittel", "Einwirkung von Arzneimittel")
          ),
          is_nongeschw = (hauptursache == "Nichtanpassen an die Strassenverhältnisse (nass, vereist, Rollsplitt, Laub, usw.)" |
                          is_nongeschw_2 |
                          is_nongeschw_3
                          # stringr::str_detect(ursache_2, "Nichtanpassen an die Strassenverhältnisse") |
                          # stringr::str_detect(ursache_3, "Nichtanpassen an die Strassenverhältnisse")
          ),
          is_tel = (hauptursache %in% c("Ablenkung durch Bedienung des Telefons", 
                                        "Ablenkung durch Bedienung technischer Geräte im Fahrzeug (Radio, Navigationssystem, Heizung, usw.)") |
                    is_tel_2 |
                    is_tel_3
                    # ursache_2 %in% c("Ablenkung durch Bedienung des Telefons", 
                    #                  "Ablenkung durch Bedienung technischer Geräte im Fahrzeug (Radio, Navigationssystem, Heizung, usw.)") |
                    # ursache_3 %in% c("Ablenkung durch Bedienung des Telefons", 
                    #                  "Ablenkung durch Bedienung technischer Geräte im Fahrzeug (Radio, Navigationssystem, Heizung, usw.)")
          ),
          is_manfahr = (hauptursache == "Mangelnde Fahrpraxis")
        )

      # Condizioni: puoi ripetere Was e cambiare desc/flag
      cond_defs_unf <- tibble::tibble(
        Was  = c(
          "Sommer",
          "Winter",
          "Spitzenzeiten",
          "Spitzenzeiten",
          "Spitzenzeiten",
          "Wochenende",
          "Verkehrsbedingungen",
          "Verkehrsbedingungen",
          "Zustand Infrastruktur",
          "Zustand Infrastruktur",
          "Zustand Infrastruktur",
          "Beleuchtung",
          "Vortritssregelung",
          "Unfallstelle",
          "Unfallstelle",
          "Unfallstelle",
          "Anprall",
          "Witterung",
          "Witterung",
          "Dunkelheit",
          "Zustand",
          "Verhalten",
          "Verhalten",
          "Fahrpraxis"
        ),
        desc = c(
          "Juni bis August",
          "Dezember bis Februar",
          "Spitzenzeiten (Mo-Fr, 6-9 & 16-19)",
          "MSP (Mo-Fr, 6-8.59)",
          "ASP (Mo-Fr, 16-18.59)",
          "Samstag + Sonntag",
          "Schwach (< 10 Fz/min)",
          "Stockend / Stau",
          "Feucht & Nass",
          "Schneebedeckt & vereist",
          "Mangelnde Signalisation & Markierung",
          "Kein & ausser Betrieb",
          "Rechtsvortritt",
          "Fussgängerstreifen",
          "Trottoir",
          "Baustelle",
          "Kollision mit festem Hindernis",
          "Regen",
          "Schneefall & vereisender Regen",
          "Dämmerung & Nacht",
          "Einwirkung Alkohol, Drogen & Arzneimittel",
          "Nicht anpassen Geschwindigkeit an Situation",
          "Ablenkung Telefon/Geräte",
          "Mangelnde Fahrpraxis"
        ),
        flag = c(
          "is_som",
          "is_winter",
          "is_spst",
          "is_msp",
          "is_asp",
          "is_wknd",
          "is_schwach",
          "is_stau",
          "is_nass",
          "is_schnee",
          "is_mark",
          "is_bel",
          "is_vort",
          "is_fgs",
          "is_trott",
          "is_bau",
          "is_anprall",
          "is_reg", 
          "is_schneefall",
          "is_dunkel",
          "is_alkdrogarzt",
          "is_nongeschw",
          "is_tel",
          "is_manfahr"
        )
      )

      out <- tidyr::expand_grid(cond_defs_unf, grp_defs) |>
        dplyr::rowwise() |>
        dplyr::mutate(
          den = if (is.na(grp_flag)) nrow(temp) else sum(temp[[grp_flag]], na.rm = TRUE),
          num = if (is.na(grp_flag)) sum(temp[[flag]], na.rm = TRUE) else sum(temp[[flag]] & temp[[grp_flag]], na.rm = TRUE),
          pct = safe_div(num, den)
        ) |>
        dplyr::ungroup() |>
        dplyr::mutate(pct = paste0(round(100 * pct), " %")) |>
        dplyr::select(Was, desc, grp_label, pct) |>
        tidyr::pivot_wider(names_from = grp_label, values_from = pct)
      
      grp_cols <- setdiff(names(out), c("Was", "desc"))
      
      header1 <- out[1, ]
      header1$Was  <- "Unfallzeitpunkt"
      header1$desc <- ""
      header1[grp_cols] <- ""
      
      header2 <- out[1, ]
      header2$Was  <- "Infrastruktur"
      header2$desc <- ""
      header2[grp_cols] <- ""
      
      header3 <- out[1, ]
      header3$Was  <- "Umwelt"
      header3$desc <- ""
      header3[grp_cols] <- ""
      
      out <- dplyr::bind_rows(
        header1,
        out[1:6, ],
        header2,
        out[7:17, ],
        header3,
        out[18:nrow(out), ]
      )

      out
    }) |> 
      bindCache(
        list(
          filterOut_unf$zeitraum(),
          filterOut_unf$zone()
        )
      )
    
    tableData_obj <- reactive({
      temp <- baseData_obj()
      req(!is.null(temp), nrow(temp) > 0)
      
      temp <- temp |> 
        dplyr::mutate(
          is_io = (ioao == "innerorts"),
          is_ao = (ioao == "ausserorts"),
          is_haupt = (strassenart == "Hauptstrasse"),
          is_neb = (strassenart == "Nebenstrasse"),
          
          is_fgfäg = (fahrzeugart %in% c("Fussgänger", "FäG")),
          is_veloebike = (fahrzeugart %in% c("Fahrrad", "Schnelles E-Bike", "Langsames E-Bike")),
          is_roll = (fahrzeugart_zus == "|Rollstuhl|"),
          is_mot = (fahrzeugart == "Motorrad"),
          is_schwerverk = (fahrzeugart %in% c("Schwerer Personenwagen", "Schwerer Motorwagen", "Schweres Sattelmotorfahrzeug"))
        )
      
      cond_defs_obj <- tibble::tibble(
        Was  = c(
          "Fahrzeug-/Objektart",
          "Fahrzeug-/Objektart",
          "Fahrzeug-/Objektart",
          "Fahrzeug-/Objektart",
          "Fahrzeug-/Objektart"
        ),
        desc = c(
          "Fussgänger & FäG",
          "Velo & E-Bike",
          "Rollstuhl",
          "Motorrad",
          "Schwerverkehr"
        ),
        flag = c(
          "is_fgfäg",
          "is_veloebike",
          "is_roll",
          "is_mot",
          "is_schwerverk"
        )
      )
      
      out <- tidyr::expand_grid(cond_defs_obj, grp_defs) |>
        dplyr::rowwise() |>
        dplyr::mutate(
          den = if (is.na(grp_flag)) nrow(temp) else sum(temp[[grp_flag]], na.rm = TRUE),
          num = if (is.na(grp_flag)) sum(temp[[flag]], na.rm = TRUE) else sum(temp[[flag]] & temp[[grp_flag]], na.rm = TRUE),
          pct = safe_div(num, den)
        ) |>
        dplyr::ungroup() |>
        dplyr::mutate(pct = paste0(round(100 * pct), " %")) |>
        dplyr::select(Was, desc, grp_label, pct) |>
        tidyr::pivot_wider(names_from = grp_label, values_from = pct)
      
      grp_cols <- setdiff(names(out), c("Was", "desc"))

      header4 <- out[1, ]
      header4$Was  <- "Fahrzeug/Verkehrsteilnehmende"
      header4$desc <- ""
      header4[grp_cols] <- ""
      
      out <- dplyr::bind_rows(
        header4,
        out
      )
    }) |> 
      bindCache(
        list(
          filterOut_obj$zeitraum(),
          filterOut_obj$zone()
        )
      )
    
    tableData_per <- reactive({
      temp <- baseData_per()
      req(!is.null(temp), nrow(temp) > 0)
      
      temp <- temp |> 
        dplyr::mutate(
          is_io = (ioao == "innerorts"),
          is_ao = (ioao == "ausserorts"),
          is_haupt = (strassenart == "Hauptstrasse"),
          is_neb = (strassenart == "Nebenstrasse"),
          
          is_noschutz = (schutzsystem == "kein"),
          is_kindschul = (kinderunfall & schulweg),
          is_jungmr = (16 <= alter & alter <= 18 & fahrzeugart == "Motorrad" & hauptverursacher),
          is_senior = (65 <= alter & hauptverursacher),
          is_nonch = !(wohnland %in% c("Schweiz", "Unbekannt")),
          is_perschade = (schwere %in% c("leicht verletzt", "schwer verletzt", "gestorben"))
        )
      
      cond_defs_per <- tibble::tibble(
        Was  = c(
          "Schutzsystem",
          "Mensch",
          "Mensch",
          "Mensch",
          "Mensch",
          "Ortskenntnis",
          "Verletzte"
        ),
        desc = c(
          "Fehlendes Tragen von Helm/Gurt",
          "Kind, ohne Mitfahrer",
          "Kind auf Schulweg, ohne Mitfahrer",
          "Junge MR-Lenkende (Hauptverursacher)",
          "Senior (Hauptverursacher, Lenker)",
          "Wohnsitz aussehalb Schweiz",
          "Unfälle mit Personenschaden"
        ),
        flag = c(
          "is_noschutz",
          "kinderunfall",
          "is_kindschul",
          "is_jungmr",
          "is_senior",
          "is_nonch",
          "is_perschade"
        )
      )
      
      out <- tidyr::expand_grid(cond_defs_per, grp_defs) |>
        dplyr::rowwise() |>
        dplyr::mutate(
          den = if (is.na(grp_flag)) {dplyr::n_distinct(temp$unf_uid)} else {dplyr::n_distinct(temp$unf_uid[temp[[grp_flag]] %in% TRUE])},
          num = if (is.na(grp_flag)) {dplyr::n_distinct(temp$unf_uid[temp[[flag]] %in% TRUE])} else {dplyr::n_distinct(temp$unf_uid[(temp[[flag]] %in% TRUE) & (temp[[grp_flag]] %in% TRUE)])},
          pct = safe_div(num, den)
        ) |>
        dplyr::ungroup() |>
        dplyr::mutate(pct = paste0(round(100 * pct), " %")) |>
        dplyr::select(Was, desc, grp_label, pct) |>
        tidyr::pivot_wider(names_from = grp_label, values_from = pct)
      
      grp_cols <- setdiff(names(out), c("Was", "desc"))
      header5 <- out[1, ]
      header5$Was  <- "Person(en)"
      header5$desc <- ""
      header5[grp_cols] <- ""
      
      out <- dplyr::bind_rows(
        out[1, ],
        header5,
        out[2:nrow(out), ]
      )
    }) |> 
      bindCache(
        list(
          filterOut_per$zeitraum(),
          filterOut_per$zone()
        )
      )
    
    tableFinal <- reactive({
      tu <- tableData_unf()
      to <- tableData_obj()
      tp <- tableData_per()
      
      req(!is.null(tu), !is.null(to), !is.null(tp))
      
      tmp <- dplyr::bind_rows(tu[1:23, ], to, tp[1:6, ], tu[24:26, ], tp[7:8, ])
    }) |> 
      bindCache(list(filterOut_unf$zeitraum(), filterOut_unf$zone())) |> 
      bindEvent(input$calc, ignoreInit = T)
    
    output$bsm_title <- renderText({
      if(filterOut_unf$zone() == "Gesamte Kanton") plus <- ""
      else plus <- paste0(" (", filterOut_unf$zone(), ")")
      
      paste0("Anteil Unfallumstände am Gesamtunfallgeschehen der Jahre ", 
             filterOut_unf$zeitraum()[1],"–", filterOut_unf$zeitraum()[2], plus)
    }) |> 
      bindEvent(input$calc, ignoreInit = T)
    
    output$bsm_table <- DT::renderDT({
      tf <- tableFinal()
      validate(need(!is.null(tf), "Filter auswählen und Tabelle erstellen"))
      
      DT::datatable(tf, 
                    colnames = c("", "", "Allgemein", "Autobahn/Autostrasse", "Ausserorts", "Innerorts", "Hauptstrassen", "Nebenstrassen"), 
                    options = list(
                      pageLength = nrow(tf),
                      dom = "t",
                      ordering = F,
                      rowCallback = DT::JS("
                        function(row, data, index) {
                          if (data[0] === 'Unfallzeitpunkt' || 
                              data[0] === 'Infrastruktur' || 
                              data[0] === 'Umwelt' || 
                              data[0] === 'Fahrzeug/Verkehrsteilnehmende' || 
                              data[0] === 'Person(en)'
                          ) {
                            $('td', row).css({
                              'font-weight': '700',
                              'text-align': 'left',
                              'border-top': '3px solid black',
                              'border-bottom': '1px solid black'
                            });
                          }
                        }
                      ")
                    ),
                    rownames = F,
                    class = "compact hover"
      )
    })
    
  })
}
