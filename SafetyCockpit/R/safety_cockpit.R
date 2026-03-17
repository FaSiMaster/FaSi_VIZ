
# TODO
# Paridigm shift -> unf_df etc are bassed as reatives
# This allows the Year filter at the app level.




#' Safety Cockpit
#' 
#' Launches the Safety cockpit 
#' @param ... Arguments passed on to shiny::ShinyApp()
#' @param load_data Whether to load the data from the SQL Server (useful if the data is already loaded).
#' @param skip_login Whether to skip the log in page (useful while working locally).
#' 
#' @return An object that represents the app.
#' 
#' @export
SafetyCockpit <- function(..., load_data = T, skip_login = F) {
  
  options(shiny.host = "0.0.0.0")
  options(shiny.port = 4629)
  
  addResourcePath("www", system.file("www", package = "SafetyCockpit"))
  

  # Get/Prepare data --------------------------------------------------------

  if(load_data) {  
    credentials <- config::get(file = "conf/credentials.yml")
    
    baud_azure <- DBI::dbConnect(
      drv = odbc::odbc(),
      driver = "SQL Server",
      server = credentials$server,
      uid = credentials$user,
      pwd = credentials$pwd,
      database = "sqldb-baudi-data"
    )
    
    baud_azure |> data_prep_auto()
    baud_azure |> data_prep_new_auto()
    #wetter_df <<- get_wetter(baud_azure)
    prognose_df <<- get_prognose(baud_azure)
    stand <<- get_stand(baud_azure)
    
    DBI::dbDisconnect(baud_azure)
  }
  
  # Global Vars -------------------------------------------------------------
  
  min_jahr <<- min(unf_df |> dplyr::pull(Jahr))
  # avoids porblems when the historical data is updated to the new year but the laufend aren't
  max_jahr <<- min(max(unf_df$Jahr), max(unf_new_df$Jahr)-1)
  
  unf_new_df$Jahr
  
  max_date <<- min(
    # cut out data in the next year
    # (only relevant before the new historical data is ready, i.e. March)
    as.Date(paste0(max_jahr+1, "-12-31")),
    as.Date(stand - lubridate::days(30))
  )
  
  # UI ----------------------------------------------------------------------
  
  ui <- bslib::page_fillable(
    fillable_mobile = T,
    shinyjs::useShinyjs(),
    shinyFeedback::useShinyFeedback(),
    tags$head(tags$script(src = "rclipboard/clipboard.min.js")),
    padding = 0, gap = 0,
    title = "SafetyCockpit",
    theme = ktz_theme(),
    navset_hidden_fillable(
      header = tagList(
        tags$link(rel='icon', type='image/gif/png', href='www/logo_small.png'),
        tags$link(rel="stylesheet", type="text/css", href="www/custom.css")
      ),
      id = "navigation",
      bslib::nav_panel_hidden(
        "login",
        tags$div(
          style="align-self: center",
          shinyauthr::loginUI(id = "login"),
          impressum(
            style = "padding-left: 20px",
            tags$br(),
            tags$a(
              href = "https://wiki.roadsafety.ch/index.php?title=Hauptseite",
              target="_blank",
              "Wiki Seite des SafetyCockpits"
            )
          )
        )
      ),
      bslib::nav_panel_hidden(
        value = "pass_change",
        bslib::layout_columns(
          col_widths = c(4, 4, 4),
          
          NULL,
          bslib::card(
            bslib::card_header(
              tagList(
                tags$strong("Neues Password setzen")
              )
            ),
            bslib::card_body(
              passwordInput("new_pwd1", "Neues Passwort"),
              passwordInput("new_pwd2", "Neues Passwort wiederholen"),
              
              actionButton("save_new_pwd", "Speichern"),
                
              tags$div(style = "margin-top: 0.75rem;", uiOutput("pwd_msg"))
            )
          ),
          NULL
        )
      ),
      bslib::nav_panel_hidden(
        "home",
        navset_bar_ktz(
          "home_nav",
          title = "SafetyCockpit",
          bslib::nav_panel(
            "Dashboard",
            add_spinner(uiOutput("ampel_ui"))
          ),
          bslib::nav_panel(
            "Modell 120d",
            mlUI("ml")
          ),
          bslib::nav_menu(
            "Karten",
            bslib::nav_panel(
              "Cluster",
              mapUI("map")
            ),
            bslib::nav_panel(
              "Heatmap",
              mapDensityUI("mapdensity")
            )
          ),
          bslib::nav_menu(
            "VUSTA",
            bslib::nav_panel(
              "Historische Daten",
              historyUI("history")
            ),
            bslib::nav_panel(
              "Zeiteinheiten ZH",
              zeTableUI("zetable", list(minj = max_jahr-9))
            ),
            bslib::nav_panel(
              "Jahresauswertung ZH",
              vergleichUI("vergleich")
            )
          ),
          bslib::nav_menu(
            "Berichte",
            bslib::nav_panel(
              "Lagebericht VSI",
              lageberichtUI("lage")
            ),
            bslib::nav_panel(
              "Lagebericht",
              kapoberichtUI("kapo")
            )
          ),
          bslib::nav_menu(
            "Weitere Themen",
            bslib::nav_panel(
              "Messuhren",
              gaugeUI("gauge", list(minj = max_jahr-9))
            ),
            bslib::nav_panel(
              "Histogramme",
              barsUI("bars", list(minj = max_jahr-9))
            ),
            bslib::nav_panel(
              "Kollision",
              vsBarUI("vs_bar", list(minj = max_jahr-9))
            ),
            bslib::nav_panel(
              "Kennzahlen BSM",
              bsmUI("bsm", list(minj = max_jahr-9))
            ),
            bslib::nav_panel(
              "Anomalien",
              anomalUI("anomal")
            )
          ),
          bslib::nav_spacer(),
          bslib::nav_item(textOutput("laufjahr")),
          bslib::nav_item(
            tags$a(
              href = "https://wiki.roadsafety.ch/index.php?title=Hauptseite",
              target = "_blank",
              class = "nav-link",
              style = "display: inline-flex; align-items: center;",
              bsicons::bs_icon("book", size = "1.25em")
            )
          ),
          bslib::nav_item(uiOutput("stand_pop")),
          bslib::nav_item(
            bsicons::bs_icon("gear", size = "2em") |>
              bslib::popover(
                selectInput(
                  "v_jahr", label = "Laufendes Jahr ändern",
                  choices = (min_jahr+10):(max_jahr+1),
                  selected = max_jahr+1, width = 175
                ),
                
                actionButton("force_update", NULL, icon = icon("arrows-rotate")) |> 
                  bslib::tooltip("Aktualisierung Laufende Daten"),
                
                shinyauthr::logoutUI(
                  id = "logout",
                  label = NULL, icon = icon("arrow-right-from-bracket"), class = NULL
                ) |>
                  bslib::tooltip("Log out"),
                
                options = list(customClass = "big-info")
              )
          )
        )
      ),
      bslib::nav_panel_hidden(
        "report",
        add_spinner(
          uiOutput("report_ui", fill = T)
        )
      )
    )
  )
  
  
  # Server ------------------------------------------------------------------
  
  server <- function(input, output, session) {
    
    # update Laufende Daten in every new session
    # (conditional on core.laufend_stand > stand)
    if(load_data) {
      update_laufend()
    }
    
    # Login stuff ----
    if(!skip_login){
      # update Userbase in every new session
      load_users(schema = "core")
      
      logout_init <- shinyauthr::logoutServer(
        id = "logout",
        active = reactive(current_user()$user_auth)
      )
  
      current_user <- shinyauthr::loginServer(
        id = "login",
        data = user_df,
        user_col = sc_user,
        pwd_col = sc_password,
        sodium_hashed = T,
        log_out = reactive(logout_init())
      )
  
      observe({
        if(current_user()$user_auth) {
          if(current_user()$info$make_new_password == 1) {
            bslib::nav_select("navigation", "pass_change")
          } else {
          db_log_login(current_user()$info$sc_user, schema = "core")
          bslib::nav_select("navigation", "home")
          }
        } else {
          bslib::nav_select("navigation", "login")
        }
      })
      
      observeEvent(input$save_new_pwd, {
        req(isTRUE(current_user()$user_auth))
        
        u <- current_user()$info$sc_user
        p1 <- input$new_pwd1
        p2 <- input$new_pwd2
        
        if (is.null(p1)) {
          output$pwd_msg <- renderUI(div(style="color:#b00020;", "Kein Passwort gegeben!"))
          return()
        }
        if (!identical(p1, p2)) {
          output$pwd_msg <- renderUI(div(style="color:#b00020;", "Die beiden Passwörter sind nicht identisch!"))
          return()
        }
        
        db_set_new_pwd(u, p1, schema = "core")
        load_users()
        
        db_log_login(u, schema = "core")
        bslib::nav_select("navigation", "home")
      })
      
    } else {
      bslib::nav_select("navigation", "home")
    }
    
    # Data ----
    
    minJahr <- reactiveVal(min_jahr)
    maxJahr <- reactiveVal(max_jahr)
    maxDate <- reactiveVal(max_date)
    rStand <- reactiveVal(stand)
    
    unfDf <- reactiveVal(unf_df)
    objDf <- reactiveVal(obj_df)
    perDf <- reactiveVal(per_df)
    
    unfNewDf <- reactiveVal(unf_new_df)
    objNewDf <- reactiveVal(obj_new_df)
    perNewDf <- reactiveVal(per_new_df)
    
    observeEvent(input$v_jahr, {
      input_v_jahr <- as.integer(input$v_jahr)
      if(input_v_jahr != max_jahr+1) {
        minJahr(min_jahr)
        maxJahr(input_v_jahr-1)
        maxDate(as.Date(paste0(input_v_jahr, "-12-31")))
        rStand(maxDate())
        
        unfDf(unf_df |> dplyr::filter(Jahr < input_v_jahr))
        objDf(obj_df |> dplyr::filter(Jahr < input_v_jahr))
        perDf(per_df |> dplyr::filter(Jahr < input_v_jahr))
        unfNewDf(unf_df |> dplyr::filter(Jahr == input_v_jahr))
        objNewDf(obj_df |> dplyr::filter(Jahr == input_v_jahr))
        perNewDf(per_df |> dplyr::filter(Jahr == input_v_jahr))
      } else {
        minJahr(min_jahr)
        maxJahr(max_jahr)
        maxDate(max_date)
        rStand(stand)
        
        unfDf(unf_df)
        objDf(obj_df)
        perDf(per_df)
        unfNewDf(unf_new_df)
        objNewDf(obj_new_df)
        perNewDf(per_new_df)
      }
    }, ignoreInit = T)
    
    ampelData <- reactive({
      list(unfDf(), objDf(), perDf(), unfNewDf(), objNewDf(), perNewDf())
    })
    
    # reactive UI ----
    
    # used to update the ampel_ui and stand_pop when force_update is clicked
    updateCount <- reactiveVal(0) 
    
    observeEvent(input$force_update, {
      update_laufend(force = T)
      updateCount(updateCount() + 1)
      
      maxDate(max_date)
      rStand(stand)
      unfNewDf(unf_new_df)
      objNewDf(obj_new_df)
      perNewDf(per_new_df)
      
      if (input$v_jahr != max_jahr + 1) {
        shiny::showNotification("Das laufende Jahr wird zurückgesetzt.", type = "default")
        updateSelectInput(
          inputId = "v_jahr",
          choices = (min_jahr+10):(max_jahr+1),
          selected = max_jahr+1
        )
      }
    }, ignoreInit = T)
    
    output$laufjahr <- renderText({
      req(input$v_jahr)
      input$v_jahr
    })
    
    output$stand_pop <- renderUI({
      if(skip_login){
        cndt <- skip_login
      } else {
        req(current_user()$user_auth)
        cndt <- (current_user()$info$sc_user == "admin")
      }
      updateCount() # makes it update when force_update is clicked
      shinyjs::toggle(id = "force_update", condition = cndt)
      bsicons::bs_icon("info", size = "2em") |>
        bslib::popover(
          div(
            span(
              "Basis Daten Stand:", br(),
              "Relavante Daten Stand:", br(),
              "Unf laufendes Jahr:", br(),
              paste0("Unf Median ", maxJahr() - 9, "-", maxJahr(), ":")
            ),
            span(tags$b(
              strftime(rStand(), "%d.%m.%Y"), br(),
              strftime(maxDate(), format = "%d.%m.%Y"), br(),
              format(sum(unfNewDf()$datum <= maxDate()), big.mark = "'"), br(),
              format(
                ampel_summary(
                  unfDf(), maxj = maxJahr(), max_date_ = maxDate()
                )[[2]],
                big.mark = "'", digits = 1
              )
            ))
          ),
          br(),
          impressum(),
          options = list(customClass = "stand-pop")
        )
    })
    
    ampel_defs <- list(
      # --- UNFALLSCHWERE (level = Unfall) ---
      ampel_def("ss", "Sachschaden",        ss, level = "Unfall"),
      ampel_def("lv", "Leichtverletzte",    lv, level = "Unfall"),
      ampel_def("sv", "Schwerverletzte",    sv, level = "Unfall"),
      ampel_def("gt", "Getötete",           gt, level = "Unfall"),

      # --- VERKEHRSTEILNEHMER (level = Objekt) ---
      ampel_def("fuss", "Fussgänger",
                fahrzeugart_grp %in% c("Fussgänger"),
                level = "Objekt"),

      ampel_def("velo", "Velo",
                fahrzeugart_grp %in% c("Fahrrad", "E-Bike"),
                level = "Objekt"),

      ampel_def("moto", "Motorrad",
                fahrzeugart_grp %in% c("Motorrad"),
                level = "Objekt"),

      ampel_def("pw", "Personenwagen",
                fahrzeugart_grp %in% c("Personenwagen"),
                level = "Objekt"),

      # --- VERKEHRS- UND VERWALTUNGSGEBIETE (level = Unfall) ---
      ampel_def("gesamt", "Gesamte Kanton", level = "Unfall"),

      ampel_def("osdt", "Ohne Städte + HLS",
                (!is_stadt) | is_abas,
                level = "Unfall"),

      ampel_def("ksn", "Staatsstrassen",
                is_ksn,
                level = "Unfall"),

      ampel_def("sdtz", "Stadt Zürich",
                is_zh & !is_abas,
                level = "Unfall"),

      ampel_def("sdtw", "Stadt Winterthur",
                is_win & !is_abas,
                level = "Unfall"),

      ampel_def("abas", "Autobahn",
                is_abas,
                level = "Unfall"),

      ampel_def("io", "Innerorts",
                ioao == "innerorts",
                level = "Unfall"),

      ampel_def("ao", "Ausserorts",
                ioao == "ausserorts",
                level = "Unfall")
    )

    ampel_tbl <- reactive({
      out <- ampel_precompute(
        defs      = ampel_defs,
        ampel_data = ampelData(),
        maxj      = maxJahr(),
        max_date_ = maxDate()
      )

      out
    }) |>
      bindCache(maxJahr(), maxDate())
    
    output$ampel_ui <- renderUI({
      # t0 <- Sys.time()
      # on.exit({
      #   dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
      #   message(sprintf("[TIMING]: %.3fs", dt))
      # }, add = TRUE)
      
      updateCount()
      bslib::layout_columns(
        bslib::card(
          bslib::card_header(
            "Unfallschwere",
            infoPop(
              title = "Unfallschwere (Gesamte Kanton)",
              p(
                "Das Konzept der", strong("Unfallschwere"), " beschreibt die 
                Schwere der Folgen eines Unfalls und wird oft verwendet, um die 
                Auswirkungen auf Personen und Sachwerte zu klassifizieren. Es gibt 
                verschiedene Stufen der Unfallschwere, die je nach Kontext und 
                Land unterschiedlich definiert sein können. Hier sind die gängigen 
                Stufen und ihre Bedeutungen:"
              ),
              tags$ul(
                tags$li(strong("Leichtverletzte:"), "Personen, die 
                        durch den Unfall nur geringfügige Verletzungen erlitten 
                        haben, die eine ärztliche Behandlung oder einen 
                        Krankenhausaufenthalt von weniger als 24 Stunden erfordern."),
                tags$li(strong("Schwerverletzte:"), "Personen, die durch den 
                        Unfall schwerere Verletzungen erlitten haben, die einen 
                        Krankenhausaufenthalt von mehr als 24 Stunden notwendig machen."),
                tags$li(strong("Getötete:"), "Personen, die innerhalb von 30
                        Tagen nach dem Unfall an den Unfallfolgen verstorben sind."),
                tags$li(strong("Sachschaden:"), "Unfälle, bei denen nur 
                        Sachschäden entstanden sind")
              ),
              options = list(customClass = "big-info")
            ),
            class = "d-flex justify-content-between"
          ),
          bslib::layout_columns(
            actionButton("ss", "Sachschaden"),
            actionButton("lv", "Leichtverletzten"),
            actionButton("sv", "Schwerverletzten"),
            actionButton("gt", "Get\u00f6tete"),
            
            # ampel_html_filter(
            #   ss,
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            # ampel_html_filter(
            #   lv,
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            # ampel_html_filter(
            #   sv,
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            # ampel_html_filter(
            #   gt,
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            
            ampel_html_id("ss", ampel_tbl()),
            ampel_html_id("lv", ampel_tbl()),
            ampel_html_id("sv", ampel_tbl()),
            ampel_html_id("gt", ampel_tbl()),
            
            col_widths = 3,
            row_heights = "auto"
          )
        ),
        bslib::card(
          bslib::card_header(
            "Verkehrsteilnehmer",
            infoPop(
              title = "Verkehrsteilnehmer (Gesamte Kanton)",
              p("Hier wird statt der Anzahl der Unfälle die Anzahl der verunfallten Verkehrsteilnehmer ausgegeben. Die Ampeln entsprechen den folgenden Filtern:"),
              tags$ul(
                tags$li(strong("Fussgänger:"), "Nur Fussgänger, insbesondere keine FäG."),
                tags$li(strong("Velo:"), "Fahrrad, Motorfahrrad, Schnelles E-Bike und Langsames E-Bike"),
                tags$li(strong("Motorrad:"), "Motorrad, Kleinmotorrad, Kleinmotorrad-Dreirad, Motorrad-Dreirad, Motorrad-Seitenwagen, Kleinmotorfahrzeug, Leichtmotorfahrzeug und Dreirädriges Motorfahrzeug"),
                tags$li(strong("Personenwagen:"), "Personenwagen und Schwerer Personenwagen")
              ),
              options = list(customClass = "big-info")
            ),
            class = "d-flex justify-content-between"
          ),
          bslib::layout_columns(
            actionButton("fuss", "Fussg\u00e4nger"),
            actionButton("velo", "Velo"),
            actionButton("moto", "Motorrad"),
            actionButton("pw", "Personenwagen"),
            
            # ampel_html_filter(
            #   fahrzeugart_grp %in% c("Fussg\u00e4nger"), level = "Objekt",
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            # ampel_html_filter(
            #   fahrzeugart_grp %in% c("Fahrrad", "E-Bike"), level = "Objekt",
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            # ampel_html_filter(
            #   fahrzeugart_grp %in% c("Motorrad"), level = "Objekt",
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            # ampel_html_filter(
            #   fahrzeugart_grp %in% c("Personenwagen"), level = "Objekt",
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            
            ampel_html_id("fuss", ampel_tbl()),
            ampel_html_id("velo", ampel_tbl()),
            ampel_html_id("moto", ampel_tbl()),
            ampel_html_id("pw", ampel_tbl()),
            
            col_widths = 3,
            row_heights = "auto"
          )
        ),
        bslib::card(
          bslib::card_header(
            "Verkehrs- und Verwaltungsgebiete",
            infoPop(
              title = "Verkehrs- und Verwaltungsgebiete",
              p("Die Ampeln entsprechen den folgenden Filtern:"),
              tags$ul(
                tags$li(strong("Gesamte Kanton:"), "Alle Unfälle die im Kanton Zürich passiert sind."),
                tags$li(strong("Ohne St\u00e4dte + HLS:"), "Alle Unfälle ausserhalb der Stadt Zürich und Winterthur plus Unfälle auf Autobahnen und Autostrassen innerhalb der beiden Stadtgebiete."),
                tags$li(strong("Staatsstrassen:"), "Unfälle auf Staatsstrassen, also ausserhalb der beiden Stadtgebiete und auf Kantonsstrassen."),
                tags$li(strong("Stadt Z\u00fcrich:"), "Unfälle innerhalb der Stadt Zürich, ohne Unfälle auf Autobahnen und Autostrassen."),
                tags$li(strong("Stadt Winterthur:"), "Unfälle innerhalb der Stadt Winterthur, ohne Unfälle auf Autobahnen und Autostrassen."),
                tags$li(strong("Autobahn:"), "Unfälle auf Autobahnen und Autostrassen."),
                tags$li(strong("Innerorts:"), "Unfälle innerorts"),
                tags$li(strong("Ausserorts:"), "Unfälle Ausserorts")
              ),
              options = list(customClass = "big-info")
            ),
            class = "d-flex justify-content-between"
          ),
          bslib::layout_column_wrap(
            actionButton("gesamt", "Gesamte Kanton"),
            actionButton("osdt", "Ohne St\u00e4dte + HLS"),
            actionButton("ksn", "Staatsstrassen"),
            actionButton("sdtz", "Stadt Z\u00fcrich"),
            actionButton("sdtw", "Stadt Winterthur"),
            actionButton("abas", "Autobahn"),
            actionButton("io", "Innerorts"),
            actionButton("ao", "Ausserorts"),
            
            # ampel_html_filter(data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()),
            # ampel_html_filter(
            #   (!is_stadt) | is_abas,
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            # ampel_html_filter(
            #   is_ksn,
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            # ampel_html_filter(
            #   is_zh & !is_abas,
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            # ampel_html_filter(
            #   is_win & !is_abas,
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            # ampel_html_filter(
            #   is_abas,
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            # ampel_html_filter(
            #   ioao == "innerorts",
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            # ampel_html_filter(
            #   ioao == "ausserorts",
            #   data = ampelData(), maxj = maxJahr(), max_date_ = maxDate()
            # ),
            
            ampel_html_id("gesamt", ampel_tbl()),
            ampel_html_id("osdt", ampel_tbl()),
            ampel_html_id("ksn", ampel_tbl()),
            ampel_html_id("sdtz", ampel_tbl()),
            ampel_html_id("sdtw", ampel_tbl()),
            ampel_html_id("abas", ampel_tbl()),
            ampel_html_id("io", ampel_tbl()),
            ampel_html_id("ao", ampel_tbl()),
            
            width = 1/8, heights_equal = "row"
            # col_widths = 3,
            # row_heights = "auto"
          )
        ),
        col_widths = c(6, 6, 12),
        row_heights = 1,
        height = "100%"
      )
    })
    
    # module Servers ----
    
    started <- reactiveValues(
      ml = FALSE,
      map = FALSE,
      mapdensity = FALSE,
      history = FALSE,
      zetable = FALSE,
      vergleich = FALSE,
      lage = FALSE,
      kapo = FALSE,
      gauge = FALSE,
      bars = FALSE,
      vs_bar = FALSE,
      bsm = FALSE,
      anomal = FALSE,
      report = FALSE
    )

    observeEvent(input$home_nav, {
      if (input$home_nav == "Modell 120d" && !started$ml) {
        mlServer("ml")
        started$ml <- TRUE
      }
      if (input$home_nav == "Cluster" && !started$map) {
        mapServer("map")
        started$map <- TRUE
      }
      if (input$home_nav == "Heatmap" && !started$mapdensity) {
        mapDensityServer("mapdensity", unfDf, unfNewDf, maxDate, maxJahr)
        started$mapdensity <- TRUE
      }
      if (input$home_nav == "Historische Daten" && !started$history) {
        historyServer("history")
        started$history <- TRUE
      }
      if (input$home_nav == "Zeiteinheiten ZH" && !started$zetable) {
        zeTableServer("zetable")
        started$zetable <- TRUE
      }
      if (input$home_nav == "Jahresauswertung ZH" && !started$vergleich) {
        vergleichServer("vergleich")
        started$vergleich <- TRUE
      }
      if (input$home_nav == "Lagebericht VSI" && !started$lage) {
        lageberichtServer("lage", unfDf, unfNewDf, objDf, objNewDf, perDf, perNewDf, maxDate, maxJahr)
        started$lage <- TRUE
      }
      if (input$home_nav == "Lagebericht" && !started$kapo) {
        kapoberichtServer("kapo", unfDf, unfNewDf, objDf, objNewDf, perDf, perNewDf, maxDate, maxJahr)
        started$kapo <- TRUE
      }
      if (input$home_nav == "Messuhren" && !started$gauge) {
        gaugeServer("gauge", unfDf, unfNewDf, maxDate, maxJahr)
        started$gauge <- TRUE
      }
      if (input$home_nav == "Histogramme" && !started$bars) {
        barsServer("bars", unfDf, unfNewDf, maxDate, maxJahr)
        started$bars <- TRUE
      }
      if (input$home_nav == "Kollision" && !started$vs_bar) {
        vsBarServer("vs_bar", objDf, objNewDf, maxDate, maxJahr)
        started$vs_bar <- TRUE
      }
      if (input$home_nav == "Kennzahlen BSM" && !started$bsm) {
        bsmServer("bsm")
        started$bsm <- TRUE
      }
      if (input$home_nav == "Anomalien" && !started$anomal) {
        anomalServer("anomal", unfDf, unfNewDf, maxDate)
        started$anomal <- TRUE
      }

    }, ignoreInit = T)
    
    #active_report <- reactive(input$navigation == "report")
    filters <- reactiveVal(list())
    
    output$report_ui <- renderUI({
      reportUI("report", filters = filters(), reports = "all", maxj = maxJahr())
    }) |> 
      bindCache(
        list(
          filters(),
          maxJahr()
        )
      )
    
    observeEvent(input$navigation, {
      if(input$navigation != "report"){
        shinyjs::hide("report-cumul-lookback")
        shinyjs::hide("report-monat-lookback")
        shinyjs::hide("report-woche-lookback")
        shinyjs::hide("report-schwere-filter-sf-zeitraum")
        shinyjs::hide("report-faz-filter-sf-zeitraum")
        shinyjs::hide("report-haupt-filter-sf-zeitraum")
        shinyjs::hide("report-vs-sf-zeitraum")
        shinyjs::hide("report-schwere-filter-sf-zeitraum")
        shinyjs::hide("report-alter-filter-sf-zeitraum")
        shinyjs::hide("report-alter-alter_bin")
        shinyjs::hide("report-altervs-filter-sf-zeitraum")
        shinyjs::hide("report-altervs-alter_bin")
        shinyjs::hide("report-altervs-falter_bin")
        shinyjs::hide("report-sunset-filter-sf-zeitraum")
        
      }
    }, ignoreInit = T)
    
    observeEvent(input$navigation, {
      if (input$navigation == "report" && !started$report) {
        reportServer("report", reports = "all", unfDf, unfNewDf, objDf, objNewDf, perDf, perNewDf, maxDate, maxJahr)
        started$report <- TRUE
      }
    }, ignoreInit = T)
    
    #report_out <- reportServer("report", reports = "all", unfDf, unfNewDf, objDf, objNewDf, perDf, perNewDf, maxDate, maxJahr)
    
    
    # Ampel navigation ----
    
    observeEvent(input$gt, {
      filters(list(schwere = "gt"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$sv, {
      filters(list(schwere = "sv"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$lv, {
      filters(list(schwere = "lv"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$ss, {
      filters(list(schwere = "ss"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$fuss, {
      filters(list(faz = "Fussg\u00e4nger", level = "Objekt"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$velo, {
      filters(list(faz = c("Fahrrad", "E-Bike"), level = "Objekt"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$moto, {
      filters(list(faz = "Motorrad", level = "Objekt"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$pw, {
      filters(list(faz = "Personenwagen", level = "Objekt"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$gesamt, {
      filters(list())
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$osdt, {
      filters(list(zone = "Ohne St\u00e4dte + HLS"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$ksn, {
      filters(list(zone = "Staatsstrassen"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$sdtz, {
      filters(list(zone = "Stadt Z\u00fcrich"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$sdtw, {
      filters(list(zone = "Stadt Winterthur"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$abas, {
      filters(list(zone = "Autobahn"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$io, {
      filters(list(ioao = "innerorts"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input$ao, {
      filters(list(ioao = "ausserorts"))
      bslib::nav_select("navigation", "report")
    }, ignoreInit = T)
    
    observeEvent(input[["report-home"]], {
      bslib::nav_select("navigation", "home")
    }, ignoreInit = T)
  }
  
  shinyApp(ui, server, ...)
}
