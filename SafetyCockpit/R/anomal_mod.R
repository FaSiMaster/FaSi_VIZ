anomalUI <- function(id) {
  ns <- NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 340,
      sliderInput(ns("years_interval"), "Zeitspanne (Jahre):", min = 5, 
                  max = 10, 
                  value = 10, 
                  step = 1,
                  ticks = F
      ),
      br(),
      selectInput(ns("schwere"), "Unfallschwere auswählen:", 
                  choices = c("Personenschaden" = "ps", 
                              "Sachschaden" = "ss", 
                              "Unfälle mit Leichtverletzte" = "lv", 
                              "Unfälle mit Schwerverletzte" = "sv", 
                              "Unfälle mit Getötete" = "gt", 
                              "Unfälle mit Schwerverunfallte" = "sv_gt"
                  )
      ),
      checkboxGroupInput(ns("ebenen"), 
                         div(
                           class = "d-flex align-items-center gap-4 stand-pop",
                           "Ebenen der Analyse wählen:",
                           bsicons::bs_icon("info",
                                            class = "stand-pop",
                                            size = "1.5em"
                           ) |> 
                           bslib::popover("Die ausgewählten Variablen werden vom Modell benutzt, um die Anomalien zu rechnen")
                         ), 
                         choices = c("Ioao", 
                                     "Gebiet", 
                                     "Fahrzeugart", 
                                     "Altersklasse", 
                                     "Hauptursache", 
                                     "Unfalltyp"
                         ),
                         selected = c("Ioao", 
                                      "Gebiet", 
                                      "Fahrzeugart", 
                                      "Altersklasse", 
                                      "Hauptursache", 
                                      "Unfalltyp"
                         )
      ),
      br(),
      downloadButton(ns("save_anomal"), 
                     label = "Anomalien als .xslx file speichern", 
                     icon = icon("file-excel"))
    ),
    bslib::card(
      bslib::card_header(
        class = "bg-danger d-flex align-items-center justify-content-between stand-pop",
        div(
          class = "d-flex align-items-center gap-1", 
          "Negative Entwicklung"
          #bsicons::bs_icon("emoji-frown")
        ),
        bsicons::bs_icon("info",
                         class = "stand-pop",
                         size = "1.5em"
        ) |> 
            bslib::popover(
              p("Mithilfe eines RandomForest-Modells berechnen wir die Differenz zwischen den Vorhersagen und den tatsächlich eingetretenen Unfällen."),
              p("Beachten Sie, dass 'Fahrzeugart' auf die Hauptverursacher bezieht.")
            )
      ), 
      DT::DTOutput(ns("anomalies_neg_rf")) |>
        add_spinner()
        #shinycssloaders::withSpinner(hide.ui = T)
    ),
    bslib::card(
      bslib::card_header(
        class = "bg-success d-flex align-items-center justify-content-between stand-pop",
        div(
          class = "d-flex align-items-center gap-1",
          "Positive Entwicklung"
          #bsicons::bs_icon("emoji-smile")
        )
      ),
      DT::DTOutput(ns("anomalies_pos_rf")) |>
        add_spinner()
        #shinycssloaders::withSpinner(hide.ui = T)
    )
  )
}

anomalServer <- function(id, unfDf, unfNewDf, maxDate) {
  moduleServer(id, function(input, output, session) {
    
    threshold_percentage <- 0.3
    
    anomalies_data <- reactive({
      anomal_data(unfDf(), unfNewDf(), maxd = maxDate()) #|>
      # dplyr::filter(md_date(datum) <= md_date(maxDate())) |>
      # dplyr::select(-datum)
    }) |> 
      bindCache(
        list(
          #unfDf(), 
          #unfNewDf(), 
          maxDate()
        )
      )
    
    data_filtered <- reactive({
      df <- req(anomalies_data())
      max_year <- max(anomalies_data()$Jahr)
      min_year <- max_year - input$years_interval + 1
      df |>
        dplyr::filter(Jahr >= min_year)
    }) |> bindCache(anomalies_data(), input$years_interval)
    
    # selected_column <- reactive({
    #   req(input$schwere)
    #   input$schwere
    # }) |> 
    #   bindCache(input$schwere)

    grouping_vars <- reactive({
      c("Jahr", input$ebenen)
    }) |> 
      bindCache(input$ebenen)

    data_summary <- reactive({
      req(input$schwere)
      vars <- grouping_vars()
      if(length(input$ebenen) == 0){
        data_filtered() |>
          dplyr::group_by(Jahr) |>
          dplyr::summarise(Unfälle = sum(.data[[input$schwere]], 
                                         na.rm = TRUE), 
                           .groups = 'drop')
      }
      else {
        data_filtered() |>
          dplyr::group_by(across(all_of(vars))) |>
          dplyr::summarise(Unfälle = sum(.data[[input$schwere]], 
                                         na.rm = TRUE), 
                           .groups = 'drop')
      }
    }) |>
      bindCache(input$schwere, grouping_vars(), data_filtered())

    data_rf <- reactive({
      dw <- req(data_summary())
      dw |>
        dplyr::filter(Jahr < max(Jahr))
    })

    data_now <- reactive({
      dw <- req(data_summary())
      dw |>
        dplyr::filter(Jahr == max(Jahr))
    })

    fit <- reactive({
      set.seed(123)
      dtrain <- req(data_rf())
      predictors <- c("Jahr", input$ebenen)
      formula <- as.formula(paste("Unfälle ~", paste(predictors, collapse = " + ")))
      ranger::ranger(formula, 
                     data = dtrain, 
                     num.trees = 500, 
                     mtry = floor(sqrt(length(predictors))), 
                     importance = "impurity")
      
      #vglm(formula, data = dtrain, family = negbinomial(), control = vglm.control(maxit = 200))
      
    }) |> bindCache(data_rf(), input$ebenen)

    anomalies_tbls <- reactive({
      m <- req(fit())
      d0 <- req(data_now())

      preds <- predict(m, data = d0)$predictions            #ranger prediction
      #preds <- predict(m, newdata = d0, type = "response") #VGLM prediction

      out <- d0
      out$Vorhersagen <- round(as.numeric(preds))
      out$Abweichung <- round(out$Unfälle - out$Vorhersagen)
      out$anomaly <- abs(out$Abweichung) > abs(threshold_percentage*out$Vorhersagen)

      anomalies <- out |> dplyr::filter(anomaly == TRUE)

      list(
        neg = anomalies |> dplyr::filter(Abweichung > 0) |> 
          dplyr::arrange(desc(Abweichung)) |> dplyr::select(-anomaly),
        pos = anomalies |> dplyr::filter(Abweichung < 0) |> 
          dplyr::arrange(Abweichung) |> dplyr::select(-anomaly)
      )
    }) |> bindCache(fit(), data_now())
    
    
    output$anomalies_neg_rf <- DT::renderDataTable({
      tabs <- req(anomalies_tbls())
      DT::datatable(tabs$neg)
    })
    
    output$anomalies_pos_rf <- DT::renderDataTable({
      tabs <- req(anomalies_tbls())
      DT::datatable(tabs$pos)
    })
    
    #output$hint <- renderText(
    #"Die Ebenen sind die Variablen, die vom Modell zur Berechnung der Anomalien verwendet werden"
    #)
    
    output$save_anomal <- downloadHandler(
      filename = function(){paste0("Anomalien_", input$schwere, ".xlsx")},
      content = function(file) {
        out <- req(anomalies_tbls())
        a_neg <- out$neg
        a_pos <- out$pos
        writexl::write_xlsx(list("Negative_Anomalien" = a_neg, 
                                 "Positive_Anomalien" = a_pos), 
                            path = file)
      }
    )
  })
}