
altervsUI <- function(id, filters = NULL) {
  filters["level"] <- "Person"
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        width = sidebar_width,
        #sfiltersUI(id, filters = filters),
        sliderInput(
          NS(id, "alter_bin"), "Altersgruppe Gr\u00f6sse",
          min = 1, max = 20, value = 1, ticks = F
        ),
        sliderInput(
          NS(id, "falter_bin"), "F\u00fchrerausweis Altersgruppe Gr\u00f6sse",
          min = 1, max = 20, value = 1, ticks = F
        ),
        # fazFilterUI(
        #   ns("fazfilter1"), selected = filters[["faz"]],
        #   label = span("Fahrzeugart", bsicons::bs_icon("filter"))
        # ),
        # selectizeInput(
        #   NS(id, "schwere"), label = span("Unfallfolgen", bsicons::bs_icon("filter")),
        #   choices = levels(per_df$schwere),
        #   selected = translate_schwere(filters[["schwere"]], level = "Person"),
        #   multiple = T,
        #   options = list(plugins = list("remove_button"))
        # ),
        checkBox(NS(id, "kosten"), "Unfallkosten"),
        filterUI(ns("filter"), filters = filters, faz_label = "Fahrzeugart", schwere_label = "Unfallfolgen")
      ),
      bslib::card(
        bslib::card_header(textOutput(ns("plot_title"))),
        plotly::plotlyOutput(NS(id, "alter_plot")),
        full_screen = T
      )
    )
  )
}

altervsServer <- function(id, res = \(x) NULL) {
  moduleServer(id, function(input, output, session) {
    observeEvent(res(), {
      shinyjs::reset("sidebar")
    }, ignoreInit = T)
    
    #fazfiltervars <- fazFilterServer("fazfilter1")
    
    filterOut <- filterServer("filter", data = per_df, reactive_level = reactive("Person"))
    
    alterData <- reactive({
      # FILTERING
      
      alter_data <- filterOut$data() #sfiltersApply(per_df, input)
      
      # alter_data <- fazFilterApply(
      #   alter_data, fazfiltervars$faz(), isolate(fazfiltervars$grouped())
      # )
      # 
      # input_schwere <- input$schwere
      # 
      # if(length(input_schwere) == 0) input_schwere <- levels(alter_data$schwere)
      
      alter_data <- alter_data |>
        dplyr::filter(!is.na(alter), !is.na(fuehrerausweisalter)) |>
        dplyr::filter(per_n == 1, hauptverursacher) #|> 
        # dplyr::filter(
        #   schwere %in% input_schwere
        # )
      
      if(nrow(alter_data) == 0) validate("Keine Daten")
      
      # LABELS
      
      max_alter <- min(100, max(alter_data$alter))
      min_alter <- min(alter_data$alter)
      
      if(input$alter_bin == 1){
        alter_labels <- c(as.character(min_alter:(max_alter-1)), paste0(max_alter, "+"))
      } else {
        
        left <- as.character(seq(min_alter, max_alter - input$alter_bin, input$alter_bin))
        right <- as.character(seq(min_alter + input$alter_bin, max_alter, input$alter_bin) - 1)
        
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
      
      max_falter <- min(100, max(alter_data$fuehrerausweisalter))
      min_falter <- min(alter_data$fuehrerausweisalter)
      
      if(input$falter_bin == 1){
        falter_labels <- c(as.character(min_falter:(max_falter-1)), paste0(max_falter, "+"))
      } else {
        
        left <- as.character(seq(min_falter, max_falter - input$falter_bin, input$falter_bin))
        right <- as.character(seq(min_falter + input$falter_bin, max_falter, input$falter_bin) - 1)
        
        for (i in seq(length(left))) {
          if(stringr::str_length(left[i]) == 1 & stringr::str_length(right[i]) == 2) {
            left[i] = paste0(" ", left[i])
          }
        }
        
        falter_labels <- c(
          paste(left, "-", right),
          paste(max_falter - max_falter %% input$falter_bin, "+")
        )
      }
      
      
      # COUNTS
      
      alter_data <- alter_data |> 
        dplyr::mutate(
          alter = cut(
            alter, 
            breaks = c(seq(min_alter, max_alter, input$alter_bin), Inf),
            labels = alter_labels,
            right = F,
          ),
          fuehrerausweisalter = cut(
            fuehrerausweisalter, 
            breaks = c(seq(min_falter, max_falter, input$falter_bin), Inf),
            labels = falter_labels,
            right = F,
          )
        )
      if(input$kosten) {
        # browser()
        alter_data <- alter_data |> 
          dplyr::filter(per_n == 1, hauptverursacher) |>
          dplyr::select(unf_uid, alter, fuehrerausweisalter) |> 
          dplyr::left_join(unf_df |> dplyr::select(unf_uid, kosten12), dplyr::join_by(unf_uid)) |> 
          dplyr::count(alter, fuehrerausweisalter, wt = kosten12) |> 
          tidyr::complete(alter, fuehrerausweisalter, fill = list(n = 0))
      } else {
        alter_data <- alter_data |> 
          dplyr::count(alter, fuehrerausweisalter) |> 
          tidyr::complete(alter, fuehrerausweisalter, fill = list(n = 0))
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
        paste0(
          "Unfallkosten nach jahr und Alter und F\u00fchrerausweisalter der Hauptverursacher",
          plus
        )
      } else {
        paste0(
          "Anzahl Hauptverursacher nach Alter und F\u00fchrerausweisalter",
          plus
        )
      }
    })
    
    output$plot_title <- renderText(plotTitle())
    
    zName <- reactive({
      ifelse(input$kosten, "Kosten", "Anzahl")
    })
    
    zFormat <- reactive({
      ifelse(input$kosten, ".3s", ".0f")
    })
    
    zSuffix <- reactive({
      ifelse(input$kosten, " CHF", "")
    })
    
    output$alter_plot <- plotly::renderPlotly({
      if(nrow(alterData()) == 0) validate("Keine Daten")
      alterData() |> 
        plotly::plot_ly(
          x = ~alter, y = ~fuehrerausweisalter, z = ~n, colors = "RdYlBu", reversescale = T,
          type = "heatmap",
          hovertemplate = paste0(
            "%{xaxis.title.text}: %{x}\n",
            "%{yaxis.title.text}: %{y}\n", 
            zName(), ": %{z:,", zFormat(),"}", zSuffix(),"<extra></extra>"
          ),
          colorbar = list(title = list(text = paste0(zName(), zSuffix())))
        ) |> 
        plotly::layout(
          separators = ".'",
          xaxis = list(title = "Alter", ticks = ""),
          yaxis = list(title = "F\u00fchrerausweisalter", ticks = "", ticksuffix = " "),
          modebar = list(remove = list("lasso", "select"))
        ) |>
        plotly::config(locale = 'de-ch') |> 
        plotly::config(toImageButtonOptions = list(
          filename = plotTitle()
        ))
    })
  })
}
