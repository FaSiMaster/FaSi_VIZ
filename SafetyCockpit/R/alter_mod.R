
alterUI <- function(id, filters = NULL) {
  filters["level"] <- "Person"
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        id = ns("sidebar"),
        width = sidebar_width,
        radioButtons(
          ns("yaxis"), "Typ",
          choices = c("Alter", "F\u00fchrerausweisalter"),
          selected = "Alter"
        ),
        checkBox(ns("standard"), "Standard Altersgruppen", value = F),
        sliderInput(
          ns("alter_bin"), "Altersgruppe Gr\u00f6sse",
          min = 1, max = 20, value = 6, ticks = F
        ),
        checkBox(ns("kosten"), "Unfallkosten"),
        checkBox(ns("year_norm"), "J\u00e4hrliche Normalizeireung") |> 
          bslib::tooltip("Die Daten werden durch die Jahressumme dividiert und in Prozent angegeben."),
        filterUI(
          ns("filter"), filters = filters,
          schwere_label = span("Unfallfolgen", bsicons::bs_icon("filter"))
        )
      ),
      bslib::card(
        bslib::card_header(textOutput(ns("plot_title"))),
        plotly::plotlyOutput(ns("alter_plot")),
        full_screen = T
      )
    )
  )
}

alterServer <- function(id, res = \(x) NULL) {
  moduleServer(id, function(input, output, session) {
    observeEvent(res(), {
      shinyjs::reset("sidebar")
    }, ignoreInit = T)
    
    observeEvent(input$standard, {
      cndt <- !(input$standard)
      shinyjs::toggle("alter_bin", condition = cndt)
    }, ignoreInit = T)
    
    observeEvent(input$yaxis, {
      if(input$yaxis == "Alter") {
        shinyjs::show("standard")
        updateCheckboxInput(inputId = "standard", value = F)
        updateSliderInput(inputId = "alter_bin", value = 6)
      } else {
        shinyjs::hide("standard")
        updateCheckboxInput(inputId = "standard", value = F)
        updateSliderInput(inputId = "alter_bin", value = 1)
      }
    }, ignoreInit = T)
    
    filterOut <- filterServer("filter", data = per_df, reactive_level = reactive("Person"))
    
    alterData <- reactive({
      
      alter_data <- filterOut$data()

      if(input$yaxis == "Alter") {
        alter_data <- alter_data |> 
          dplyr::mutate(yaxis = alter)
      } else {
        alter_data <- alter_data |> 
          dplyr::mutate(yaxis = fuehrerausweisalter) |> 
          dplyr::filter(hauptverursacher, per_n == 1)
      }
      
      alter_data <- alter_data |> dplyr::filter(!is.na(yaxis))
      
      if(nrow(alter_data) == 0) validate("Keine Daten")
      
      #LABELS
      
      if(input$standard) {
        alter_labels <- c("0-14", "15-17", "18-24", "25-64", "65+")
      } else {
        max_alter <- min(100, max(alter_data$yaxis))
        
        if(input$alter_bin == 1){
          alter_labels <- c(as.character(0:(max_alter-1)), paste0(max_alter, "+"))
        } else {
          
          left <- as.character(seq(0, max_alter - input$alter_bin, input$alter_bin))
          right <- as.character(seq(input$alter_bin, max_alter, input$alter_bin) - 1)
          
          for (i in seq(length(left))) {
            if(stringr::str_length(left[i]) == 1 & stringr::str_length(right[i]) == 2) {
              left[i] = paste0(" ", left[i])
            }
          }
          
          alter_labels <- c(
            paste(left, "-", right),
            paste(max_alter - max_alter %% input$alter_bin, "+")
          )
        }
      }
      
      # COUNTS
      
      if(input$standard) {
        alter_data <- alter_data |> 
          dplyr::mutate(
            yaxis = cut(
              yaxis, 
              breaks = c(0, 15,18,25,65, Inf),
              labels = alter_labels,
              right = F,
            )
          )
      } else {
        alter_data <- alter_data |> 
          dplyr::mutate(
            yaxis = cut(
              yaxis, 
              breaks = c(seq(0, max_alter, input$alter_bin), Inf),
              labels = alter_labels,
              right = F,
            )
          )
      }
      
      if(input$kosten) {
        alter_data <- alter_data |> 
          dplyr::filter(per_n == 1, hauptverursacher) |>
          dplyr::select(unf_uid, Jahr, yaxis) |> 
          dplyr::left_join(unf_df |> dplyr::select(unf_uid, kosten12), dplyr::join_by(unf_uid)) |> 
          dplyr::count(Jahr, yaxis, wt = kosten12) |> 
          tidyr::complete(Jahr = min(Jahr):max(Jahr), yaxis, fill = list(n = 0))
      } else {
        alter_data <- alter_data |> 
          dplyr::count(Jahr, yaxis) |> 
          tidyr::complete(Jahr = min(Jahr):max(Jahr), yaxis, fill = list(n = 0))
      }
      
      if(input$year_norm) {
        alter_data <- alter_data |> 
          dplyr::group_by(Jahr) |>
          dplyr::mutate(n = n / sum(n))
      }
      
      alter_data
    })
    
    plotTitle <- reactive({
      zone <- filterOut$zone()
      ioao <- filterOut$ioao()
      faz <- filterOut$faz()
      schwere <- filterOut$schwere()
      
      if(zone == "Gesamte Kanton") zone <-  NULL
      if(ioao == "Alle") ioao <-  NULL
      
      plus <- paste0(" (",stringr::str_flatten_comma(c(zone, ioao, faz, schwere)),")")
      
      plus <- ifelse(plus == " ()", "", plus)
      
      if(input$kosten) {
        what <- ifelse(input$year_norm, "Anteil Unfallkosten", "Unfallkosten")
        paste0(what, " nach jahr und ", input$yaxis, " der Hauptverursacher", plus)
      } else {
        what <- ifelse(input$year_norm, "Anteil", "Anzahl")
        if(input$yaxis == "Alter") {
          paste0(what, " Unfallbeteiligten nach Jahr und Alter", plus)
        } else {
          paste0(what, " Hauptverursacher nach Jahr und F\u00fchrerausweisalter", plus)
        }
      }
    })
    
    output$plot_title <- renderText(plotTitle())
    
    zName <- reactive({
      ifelse(
        input$kosten,
        ifelse(
          input$year_norm,
          "Kostenanteil",
          "Kosten"
        ),
        ifelse(
          input$year_norm,
          "Anteil",
          "Anzahl"
        )
      )
    })
    
    zFormat <- reactive({
      dplyr::case_when(
        input$year_norm ~ ".1%",
        input$kosten & !input$year_norm ~ ".3s",
        !input$kosten & !input$year_norm ~ ".0f"
      )
    })
    
    zSuffix <- reactive({
      ifelse(input$kosten & !input$year_norm, " CHF", "")
    })
    
    output$alter_plot <- plotly::renderPlotly({
      alterData() |> 
        plotly::plot_ly(
          x = ~Jahr, y = ~yaxis, z = ~n, colors = "RdYlBu", reversescale = T,
          type = "heatmap",
          hovertemplate =  paste0(
            "Jahr: %{x}\n",
            input$yaxis, ": %{y}\n",
            zName(), ": %{z:,", zFormat(),"}", zSuffix(), "<extra></extra>"
          ),
          colorbar = list(title = list(text = paste0(zName(), zSuffix())), tickformat = zFormat())
        ) |> 
        plotly::layout(
          separators = ".'",
          xaxis = list(tick0 = 0, dtick = 1, ticks = ""),
          yaxis = list(title = input$yaxis, ticks = "", ticksuffix = " "),
          modebar = list(remove = list("lasso", "select"))
        ) |>
        plotly::config(locale = 'de-ch') |>
        plotly::config(toImageButtonOptions = list(
          filename = plotTitle()
        ))
    })
  })
}
