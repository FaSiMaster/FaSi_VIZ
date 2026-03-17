
# normalize a vector by division through a value defined by a reference vector
# example: vector = sale_value, ref = year_of_sale, val = 1989, would normalize
# the Sales values by the Sales value in 1989.
norm_vector_by_ref_val <- function(vector, ref, val) {
  norm_factor = vector[ref == val][1]
  return(vector / norm_factor)
}

historyUI <- function(id) {
  ns <- NS(id)
  tagList(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        open = F,
        width = sidebar_width,
        selectInput(
          ns("where"), "Wo?",
          choices = sort(unique(old_df$where)), selected = "Z\u00fcrich",
          selectize = T
        ),
        selectizeInput(
          ns("name"), label = "Was?",
          choices = names(old_df)[-c(1,2)],
          selected = names(old_df)[c(4:6, 11)],
          multiple = T,
          options = list(plugins = list("remove_button"))
        ),
        checkBox(ns("norm"), "Indizieren", value = T),
        selectInput(
          ns("norm_year"), "Index-Jahr",
          choices = unique(old_df$year), selected = min(old_df$year)
        ),
        checkBox(ns("show_text"), "Text anzeigen", value = T),
        uiOutput(ns("clipboard"))
      ),
      bslib::card(
        bslib::card_header(
          textOutput(ns("plot_title")),
          infoPop(p(
            "Daten aus BFS:",
            tags$ul(
              tags$li(a(
                href = "https://www.bfs.admin.ch/asset/de/31726346",
                "Strassenverkehrsunfälle mit Personenschaden und Verunfallte nach Kanton"
              )),
              tags$li(a(
                href = "https://www.bfs.admin.ch/asset/de/33827606",
                "Strassenfahrzeugbestand nach Fahrzeuggruppe und Kanton"
              )),
              tags$li(a(
                href = "https://www.bfs.admin.ch/asset/de/33827620",
                "Motorisierungsgrad nach Kanton"
              ))
            )
          ), options = list(customClass = "big-info")),
          class = "d-flex justify-content-between"
        ),
        plotly::plotlyOutput(ns("historical")),
        full_screen = T
      )
    )
  )
}

historyServer <- function(id) {
  moduleServer(id,function(input, output, session) {
    
    observe({
      shinyjs::toggle(id = "norm_year", condition = (input$norm))
    })
    
    oldData <- reactive({
      temp <- old_df
      
      if(input$norm) {
        req(input$norm_year)
        temp <- temp |>
          dplyr::group_by(where) |> 
          dplyr::mutate(
            dplyr::across(
              !c(year), 
              \(col) norm_vector_by_ref_val(col, year, input$norm_year)
            )
          ) |> 
          dplyr::ungroup() |> 
          dplyr::filter(year >= input$norm_year)
      }
      temp |> 
        tidyr::pivot_longer(!c(year, where)) |> 
        dplyr::arrange(desc(year), desc(value))
    })
    
    oldDataFilter <- reactive({
      oldData() |> 
        dplyr::filter(
          where %in% input$where,
          name %in% input$name
        ) |> 
        dplyr::arrange(desc(year), desc(value)) |> 
        dplyr::mutate(name = forcats::fct_inorder(name))
    })
    
    yName <- reactive({
      ifelse(input$norm, "Relative \u00c4nderung", "Anzahl")
    })
    
    hoverFormatOld <- reactive({
      ifelse(input$norm, ".1%", ",.0f")
    })
    
    plotTitle <- reactive({
      y <- ifelse(input$norm, "Trendvergleich von", "Anzahl")
      what <- stringr::str_flatten_comma(input$name, last = " und ")
      where <- input$where
      index <- ifelse(input$norm, paste0(" (Indizierung:",input$norm_year," = 100%)"), "")
      paste0(y, " ", what, " in ", where, ", nach Jahr", index)
    })
    
    output$plot_title <- renderText(plotTitle())
    
    output$historical <- plotly::renderPlotly({
      ktz_colors <- c(
        "Getötete Personen" = "tomato2",
        "Schwerverletzte Personen" = "darkgoldenrod1",
        "Leichtverletze Personen" = "gold",
        "Verunfallte Personen" = "darkgoldenrod",
        "Unfälle mit Getötete" = "tomato2",
        "Unfälle mit Schwerverletze" = "darkgoldenrod1",
        "Unfälle mit Leichtverletze" = "gold",
        "Unfälle mit Personenschaden" = "darkgoldenrod",
        "Personenwagen" = ktz_palette[[1]],
        "Motorfahrzeuge" = ktz_palette[[10]],
        "Motorisierungsgrad" = ktz_palette[[19]],
        "Motorräder" = ktz_palette[[3]],
        "Personentransport" = ktz_palette[[5]],
        "Sachentransport" = ktz_palette[[7]]
      )
        
      #setNames(ktz_palette[1:length(lvls)], lvls)
      # browser()
      if(nrow(oldDataFilter()) == 0 | sum(!is.na(oldDataFilter()$value)) == 0) validate("Keine Daten")
      fig <- oldDataFilter() |> 
        plotly::plot_ly(
          x = ~year, y = ~value, color = ~name, colors = ktz_colors,
          type = "scatter", mode = "lines+markers",
          marker = marker_style, line = line_style,
          text = ~name,
          hovertemplate = "<b>%{text}</b>\n%{xaxis.title.text}: %{x}\n%{yaxis.title.text}: %{y}<extra></extra>"
        )
      if(input$show_text){
        fig <- fig |> 
          plotly::add_annotations(
            inherit = F,
            x = 1.01, y = .9, xanchor='left', xref="paper", yref="paper",
            showarrow = F, text = isolate(importantValues()), align = "left"
          )
      }
      fig |>  
        plotly::layout(
          separators = ".'",
          xaxis = list(tickvals = unique(oldDataFilter()$year), title = "Jahr"),
          yaxis = list(title = yName(), rangemode = "tozero", hoverformat = hoverFormatOld()),
          legend = list(x = 100, y = 0.5),
          modebar = list(remove = list("lasso", "select"))
        )|> 
        plotly::config(
          locale = 'de-ch',
          toImageButtonOptions = list(filename = plotTitle())
        )
    })
    
    importantValues <- reactive({
      maxj <- max(old_df$year)
      minj <- min(old_df$year)
      
      if(input$norm) {
        req(input$norm_year)
        minj <- input$norm_year
      }
      
      temp <- old_df |> 
        dplyr::filter(year %in% c(minj, maxj)) |> 
        dplyr::filter(where == input$where) |>
        tidyr::pivot_longer(!c(year, where)) |> 
        dplyr::filter(name %in% input$name)
      
      what <- temp |> dplyr::pull(name)
      howmuch <- temp |> dplyr::pull(value)
      
      l <- length(howmuch)
      
      if(l != length(what)) stop("What is not 1:1 to Howmuch")
      if(l %% 2) stop("Uneven. Probably something wrong with minj or maxj.")
      
      howmuch <- format(howmuch, big.mark = "'", digits = 3, trim = T)
      
      paste(
        tags$b(minj),
        paste(
          howmuch[(l/2+1):l], what[(l/2+1):l],
          sep = " ", collapse = "\n"
        ),"",
        tags$b(maxj),
        paste(
          howmuch[1:(l/2)], what[1:(l/2)], 
          sep = " ", collapse = "\n"
        ),
        sep = "\n"
      )
    })
    
    output$clipboard <- renderUI({
      rclipboard::rclipButton(
        inputId = NS(id,"clipbtn"),
        label = "Text kopieren",
        clipText = importantValues() |> stringr::str_remove_all("<[^<>]+>")
      )
    })
    
    observeEvent(input$clipbtn, {
      showNotification(
        "Der Text wurde in den Zwischenspeicher geschrieben",
        type = "message"
      )
    }, ignoreInit = T)
    
    output$important_values <- renderText({
            maxj <- max(old_df$year)
      minj <- min(old_df$year)
      
      if(input$norm) {
        req(input$norm_year)
        minj <- input$norm_year
      }
      
      temp <- old_df |> 
        dplyr::filter(year %in% c(minj, maxj)) |> 
        dplyr::filter(where == input$where) |>
        tidyr::pivot_longer(!c(year, where)) |> 
        dplyr::filter(name %in% input$name)
      
      what <- temp |> dplyr::pull(name)
      howmuch <- temp |> dplyr::pull(value)
      
      l <- length(howmuch)
      
      if(l != length(what)) stop("What is not 1:1 to Howmuch")
      if(l %% 2) stop("Uneven. Probably something wrong with minj or maxj.")
      
      howmuch <- format(howmuch, big.mark = "'", digits = 3)
      
      paste(tagList(div(
        style = "font-size: 12pt;",
        tags$b(minj),
        p(HTML(paste(
          howmuch[(l/2+1):l], what[(l/2+1):l],
          sep = " ", collapse = "<br>"
        ))),
        tags$b(maxj),
        p(HTML(paste(
          howmuch[1:(l/2)], what[1:(l/2)], 
          sep = " ", collapse = "<br>"
        )))
      )))
    })
    
  })
}
