#' Ampel Summary
#' 
#' Calculates quartiles of counts by year.\cr
#' Depends on global variables max_jahr and max_date.
#' @param df A dataframe with a Jahr column and a datum column
#' @noRd
ampel_summary <- function(df, min_max = F, minj = NULL, maxj = NULL, max_date_ = NULL) {
  if(is.null(maxj)) maxj <- max_jahr
  if(is.null(minj)) minj <- maxj - 9
  if(is.null(max_date_)) max_date_ <- max_date
  summary <- df |> 
    dplyr::filter(
      Jahr >= minj, Jahr <= maxj,
      lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(max_date_)*100 + lubridate::day(max_date_)
    ) |>
    dplyr::count(Jahr) |> 
    dplyr::summarise(
      min = min(n),
      q25 = quantile(n, 0.25),
      q50 = median(n),
      q75 = quantile(n, .75),
      max = max(n)
    ) |> 
    as.numeric() |> 
    dplyr::coalesce(0) # fixes NAs in cases where there where no accidents
  
  summary <- setNames(summary, c("min", "q25", "q50", "q75", "max"))
  
  if(min_max) summary
  else summary[2:4]
}

#' Get Ampel color
#' 
#' Get the color which should be on, based on the quartiles and current value.
#' @param value Current number of accidents
#' @param quartiles Calculated quartiles based on previous years (i.e. the output of ampel_summary())
#' @noRd
get_ampel_color <- function(value, quartiles) {
  dplyr::case_when(
    value > quartiles[[3]] ~ "rot",
    quartiles[[3]] >=  value & value >= quartiles[[1]] ~ "gelb",
    quartiles[[1]] > value ~ "gruen"
  )
}

#' Ampel HTML
#' 
#' Gives the HTML for the Ampel.
#' @param color Which color should be on? (in German)
#' @param value Number to be displayed at the bottom
#' @param icon An icon to be displayed at the bottom (overwrites value)
#' @noRd
ampel_html <- function(color, value = NULL, icon = NULL) {
  if(is.null(value) & is.null(icon)) {
    HTML(paste(
      img(
        src = paste0("www/ampel_", color, ".png"),
        style = "height: 80%; object-fit: contain;",
        alt = paste(color, "Ampel")
      )
    ))
  } else if(!is.null(value)){
    HTML(paste(
      div(
        style = "position: relative; width: 100%; height: 100%;",
        img(
          src = paste0("www/ampel_", color, ".png"),
          style = "height:100%; display: block; margin: auto;",
          alt = paste(color, "Ampel")
        ) |> bslib::tooltip(
          p("Die Ampel wird entsprechend der Position im Quartil der letzten 10 Jahre eingef\u00e4rbt."),
          p("Rot bedeutet \u00fcber 75%, Gelb zwischen 25% und 75%, Gr\u00fcn unter 25%.")
        ),
        h5(format(value, big.mark = "'"), style = "position: absolute; bottom: 2%; left: 50%; transform: translate(-50%);")
      )
    ))
  } else {
    HTML(paste(
      div(
        style = "position: relative; width: 100%; height: 100%;",
        img(
          src = paste0("www/ampel_", color, ".png"),
          style = "height:100%; display: block; margin: auto;",
          alt = paste(color, "Ampel")
        ),
        bsicons::bs_icon(icon, size = "12%", position = "absolute", bottom = "3%", left = "50%", transform = "translate(-50%) scale(1.4, 1.4)"),
        bsicons::bs_icon(
          "info", size = "25px", position = "absolute",# height = "auto",
          top =  "0%", right = "0%"
        ) |>
          bslib::popover(
            title = "Ampel Farb und Pfeil",
            p("Die Ampel wird entsprechend der Position im Quartil eingef\u00e4rbt.
              Rot bedeutet \u00fcber 75%, Gelb zwischen 25% und 75%, Gr\u00fcn unter 25%."),
            p("Der Pfeil entspricht der Abweichung des linearen Trends des laufenden Jahres vom linearen Trend des Medians der letzten 30 Tage.
              Bei einer Abweichung von mehr als 10% zeigt der Pfeil nach oben oder unten.")
          )
      )
    ))
  }
}


#' Ampel HTML filter
#'
#' Gives the HTML for the Ampel by calculating the summary given a filter.
#' @param ... Arguments passed on to dplyr::filter()
#' @param level Unfall, Objekt, Person
#' @noRd
ampel_html_filter <- function(..., level = "Unfall", data = NULL, minj = NULL, maxj = NULL, max_date_ = NULL) {
  if(is.null(max_date_)) max_date_ <- max_date

  current <- level_data(level, new = T, data = data)
  base <- level_data(level, data = data)

  value <- current |> dplyr::filter(..., datum <= max_date_) |> nrow()
  quartiles <- base |> dplyr::filter(...) |> ampel_summary(minj = minj, maxj = maxj, max_date_ = max_date_)

  color <- get_ampel_color(value, quartiles)

  ampel_html(color, value)
}

ampel_def <- function(id, label, ..., level = "Unfall") {
  list(
    id    = id,
    label = label,
    level = level,
    quos  = rlang::enquos(...)
  )
}

ampel_html_id <- function(id, tbl) {
  i <- match(id, tbl$id)
  if (is.na(i)) return(ampel_html("grey", 0))
  ampel_html2(tbl$color[i], tbl$value[i])
  # r <- tbl[tbl$id == id, , drop = FALSE]
  # if (nrow(r) == 0) return(ampel_html("grey", 0))
  # ampel_html(r$color[[1]], r$value[[1]])
}

ampel_precompute <- function(defs, ampel_data, minj = NULL, maxj = NULL, max_date_ = NULL) {
  if (is.null(maxj))      maxj      <- max_jahr
  if (is.null(minj))      minj      <- maxj - 9
  if (is.null(max_date_)) max_date_ <- max_date

  lvl <- list(
    Unfall = list(current = ampel_data[[4]], base = ampel_data[[1]]),
    Objekt = list(current = ampel_data[[5]], base = ampel_data[[2]]),
    Person = list(current = ampel_data[[6]], base = ampel_data[[3]])
  )
  lvl_names <- names(lvl)
  
  if (!is.list(defs) || length(defs) == 0L) {
    stop("defs deve essere una lista non vuota di definizioni semaforo.")
  }

  for (k in seq_along(defs)) {
    d <- defs[[k]]
    if (!is.list(d) || is.null(d$id) || is.null(d$level)) {
      stop("Elemento defs[[", k, "]] non valido: manca id/level.")
    }
    if (!d$level %in% lvl_names) {
      stop("Level non valido per id=", d$id, ": '", d$level,
           "'. Attesi: ", paste(lvl_names, collapse = ", "))
    }
    if (is.null(d$quos) || !is.list(d$quos)) {
      stop("d$quos non è una lista per id=", d$id)
    }
  }

  need_cols <- c("datum", "Jahr")
  for (lv in lvl_names) {
    cur  <- lvl[[lv]]$current
    base <- lvl[[lv]]$base
    missing_cur  <- setdiff(need_cols, names(cur))
    missing_base <- setdiff(need_cols, names(base))
    if (length(missing_cur))  stop("cur (", lv, ") manca colonne: ", paste(missing_cur, collapse=", "))
    if (length(missing_base)) stop("base (", lv, ") manca colonne: ", paste(missing_base, collapse=", "))
  }
  
  cur_by_level <- lapply(lvl_names, function(lv) {
    dplyr::filter(lvl[[lv]]$current, datum <= max_date_)
  })
  names(cur_by_level) <- lvl_names
  
  base_by_level <- lapply(lvl_names, function(lv) {
    dplyr::filter(lvl[[lv]]$base, Jahr >= minj, Jahr <= maxj, lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(max_date_)*100 + lubridate::day(max_date_))
  })
  names(base_by_level) <- lvl_names
  
  # ---- FUNZIONE PER COSTRUIRE UNA MASCHERA LOGICA DA QUOS ----
  mask_from_quos <- function(df, quos) {
    # m <- rep_len(TRUE, nrow(df))
    # if (length(quos) == 0L) return(m)
    # for (q in quos) {
    #   m <- m & rlang::eval_tidy(q, data = df)
    # }
    # m
    if (length(quos) == 0L) return(rep_len(TRUE, nrow(df)))
    
    # Prima condizione: eviti l'allocazione iniziale di TRUE
    m <- rlang::eval_tidy(quos[[1]], data = df)
    m <- (m %in% TRUE)   # forza logical e tratta NA come FALSE
    
    if (length(quos) > 1L) {
      for (k in 2:length(quos)) {
        if (!any(m)) break
        mk <- rlang::eval_tidy(quos[[k]], data = df)
        m <- m & (mk %in% TRUE)
      }
    }
    m
  }
  
  # ---- OUTPUT PREALLOCATO ----
  n <- length(defs)
  id    <- character(n)
  level <- character(n)
  value <- integer(n)
  color <- character(n)
  
  # ---- LOOP SEMAFORI (leggero) ----
  for (i in seq_len(n)) {
    d <- defs[[i]]
    id[i]    <- d$id
    level[i] <- d$level
    
    cur_df  <- cur_by_level[[d$level]]   # già filtrato per data
    base_df <- base_by_level[[d$level]]
    
    m_cur <- mask_from_quos(cur_df, d$quos)
    value[i] <- sum(m_cur)
    
    # m_base <- mask_from_quos(base_df, d$quos)
    # base_f <- base_df[m_base, , drop = FALSE]
    base_df <- base_df |> dplyr::filter(!!!d$quos)
    
    quartiles <- ampel_summary(base_df, minj = minj, maxj = maxj, max_date_ = max_date_)
    color[i] <- get_ampel_color(value[i], quartiles)
    
    # Debug opzionale (come avevi tu)
    if (value[i] == 0L) {
      message("[DEBUG] id=", d$id, " level=", d$level,
              " | n(cur)=", nrow(cur_df),
              " n(cur_hit)=", value[i],
              " n(base)=", nrow(base_df)
      )
      message("[DEBUG] quos for ", d$id, ": ",
              paste(vapply(d$quos, rlang::quo_text, character(1)), collapse=" & "))
    }
  }
  
  tibble::tibble(id = id, level = level, value = value, color = color)
}

ampel_html2 <- function(color, value = NULL, icon = NULL) {
  stopifnot(is.character(color), length(color) == 1)
  
  # In Shiny, files in /www are served from the app root (no "www/" prefix needed)
  src <- paste0("www/ampel_", color, ".png")
  
  base_img <- tags$img(
    src   = src,
    alt   = paste(color, "Ampel"),
    style = "height:100%; display:block; margin:auto;"
  )
  
  # Case 1: plain ampel only
  if (is.null(value) && is.null(icon)) {
    return(base_img)
  }
  
  # common container
  container <- tags$div(
    style = "position:relative; width:100%; height:100%;",
    base_img
  )
  
  # Case 2: numeric value overlay + tooltip on the image
  if (!is.null(value)) {
    img_tt <- bslib::tooltip(
      base_img,
      tags$p("Die Ampel wird entsprechend der Position im Quartil der letzten 10 Jahre eingefärbt."),
      tags$p("Rot bedeutet über 75%, Gelb zwischen 25% und 75%, Grün unter 25%.")
    )
    
    val_txt <- if (is.na(value)) "–" else format(value, big.mark = "'")
    
    return(tags$div(
      style = "position:relative; width:100%; height:100%;",
      img_tt,
      tags$h5(
        val_txt,
        style = "position:absolute; bottom:2%; left:50%; transform:translate(-50%);"
      )
    ))
  }
  
  # Case 3: icon overlay + popover (info icon)
  container <- tagAppendChildren(
    container,
    bsicons::bs_icon(
      icon, size = "12%",
      position = "absolute", bottom = "3%", left = "50%",
      transform = "translate(-50%) scale(1.4, 1.4)"
    ),
    bslib::popover(
      bsicons::bs_icon("info", size = "25px", position = "absolute", top = "0%", right = "0%"),
      title = "Ampel Farb und Pfeil",
      tags$p("Die Ampel wird entsprechend der Position im Quartil eingefärbt. Rot bedeutet über 75%, Gelb zwischen 25% und 75%, Grün unter 25%."),
      tags$p("Der Pfeil entspricht der Abweichung des linearen Trends des laufenden Jahres vom linearen Trend des Medians der letzten 30 Tage. Bei einer Abweichung von mehr als 10% zeigt der Pfeil nach oben oder unten.")
    )
  )
  
  container
}
