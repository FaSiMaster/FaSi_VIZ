
reportUI <- function(id, filters = NULL, reports = "all", maxj) {
  ns <- NS(id)
  panels <- list()
  
  if("current" %in% reports || reports == "all") {
    panels[[length(panels)+1]] <- bslib::nav_menu(
      "Laufende Unf\u00e4lle",
      bslib::nav_panel("Kumuliert", cumulUI(ns("cumul"), filters, maxj)),
      bslib::nav_panel("Nach Monat", monatUI(ns("monat"), filters, maxj)),
      bslib::nav_panel("Nach Woche", wocheUI(ns("woche"), filters, maxj))
    )
  }
  
  if("entwicklung" %in% reports || reports == "all") {
    panels[[length(panels)+1]] <- bslib::nav_menu(
      "Entwicklung",
      bslib::nav_panel(
        "Nach Unfallschwere",
        schwereUI(ns("schwere"), filters)
      ),
      bslib::nav_panel(
        "Nach Verkehrsteilnehmer",
        fazUI(ns("faz"), filters)
      ),
      bslib::nav_panel(
        "Nach Hauptursache",
        hauptUI(ns("haupt"), filters)
      ),
      bslib::nav_panel(
        "Kollision",
        vsUI(ns("vs"), filters)
      )
    )
  }
  
  if("alter" %in% reports || reports == "all") {
    panels[[length(panels)+1]] <- bslib::nav_menu(
      "Alter",
      bslib::nav_panel(
        "Alter",
        alterUI(ns("alter"), filters)
      ),
      bslib::nav_panel(
        "Alter Vs F\u00fchrerausweisalter",
        altervsUI(ns("altervs"), filters)
      )
    )
  }
  
  if("sunset" %in% reports || reports == "all") {
    panels[[length(panels)+1]] <- bslib::nav_panel(
      "Lichtverhältnis",
      sunsetUI(ns("sunset"), filters)
    )
  }
  
  ui <- navset_bar_ktz(
    id = ns("navset"),
    title = actionButton(ns("home"), "SafetyCockpit"),
    !!!panels,
    bslib::nav_spacer(),
    bslib::nav_item(textOutput(ns("laufjahr_rep"))),
    bslib::nav_item(infoPop(impressum(), size = "2em"))
  )
}

reportServer <- function(id, reports = "all", unfDf, unfNewDf, objDf, objNewDf, perDf, perNewDf, maxDate, maxJahr) {
  moduleServer(id, function(input, output, session) {
    
    res <- \(x) NULL #reactive(input$home)
    
    output$laufjahr_rep <- renderText({
      maxJahr() + 1
    })
    
    if("current" %in% reports || reports == "all") {
      cumul_out <- cumulServer("cumul", res, unfDf, unfNewDf, objDf, objNewDf, perDf, perNewDf, maxDate, maxJahr)
      monatServer("monat", res, unfDf, unfNewDf, objDf, objNewDf, perDf, perNewDf, maxDate, maxJahr)
      wocheServer("woche", res, unfDf, unfNewDf, objDf, objNewDf, perDf, perNewDf, maxDate, maxJahr)
    }
    
    if("entwicklung" %in% reports || reports == "all") {
      schwereServer("schwere", res)
      fazServer("faz", res)
      hauptServer("haupt", res)
      vsServer("vs", res)
    }
    
    if("alter" %in% reports || reports == "all") {
      alterServer("alter", res)
      altervsServer("altervs", res)
    }
    
    if("sunset" %in% reports || reports == "all") {
        sunsetServer("sunset", res)
    }
    
    list(
      home = reactive(input$home),
      value = reactive(cumul_out$value()),
      color = reactive(cumul_out$color())
    )
  })
}