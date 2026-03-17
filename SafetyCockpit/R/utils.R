
translate_schwere <- function(schwere, level = "Unfall", na.rm = F) {
  if(is.null(schwere)) return(NULL)
  if(is.null(level)) level <- "Unfall"
  
  if(level == "Unfall") {
    temp <- setNames(levels(unf_df$schwere), c("ss", "lv", "sv", "gt"))
  } else {
    temp <- setNames(levels(per_df$schwere), c("ss", "lv", "sv", "gt", "un"))
  }
  
  temp <- unname(temp[schwere])
  
  if(na.rm) return(temp[!is.na(temp)])
  
  temp
}

encode_schwere <- function(schwere, level = "Unfall") {
  if(is.null(schwere)) return(NULL)
  
  if(level == "Unfall") {
    temp <- setNames(c("ss", "lv", "sv", "gt"), levels(unf_df$schwere))
  } else {
    temp <- setNames(c("ss", "lv", "sv", "gt", "un"), levels(per_df$schwere))
  }
  
  unname(temp[schwere])
}

#' Level data
#' 
#' Selects the correct dataset based on level
#' @param level A string giving the wanted level (Unfall, Objekt or Person)
#' @param new Whether to get the new data or the historic data
#' @noRd
level_data <- function(level, new = F, data = NULL) {
  if (is.null(data)) {
    switch (
      level,
      "Unfall" = {
        if(new) {
          unf_new_df
        } else {
          unf_df
        }
      },
      "Objekt" = {
        if(new) {
          obj_new_df
        } else {
          obj_df
        }
      },
      "Person" = {
        if(new) {
          per_new_df
        } else {
          per_df
        }
      },
      stop("Unsopported level")
    )
  } else {
    switch (
      level,
      "Unfall" = {
        if(new) {
          data[[4]]
        } else {
          data[[1]]
        }
      },
      "Objekt" = {
        if(new) {
          data[[5]]
        } else {
          data[[2]]
        }
      },
      "Person" = {
        if(new) {
          data[[6]]
        } else {
          data[[3]]
        }
      },
      stop("Unsopported level")
    )
  }
  
  
}

md_date <- function(date, year = 1970) {
  lubridate::make_date(year = year, month = lubridate::month(date), day = lubridate::day(date))
}

# readable number formatting to nearest power of 1000
nearest_pow3 <- function(x, order = NULL) {
  if (is.null(order)) {
    order <- dplyr::if_else(
      sum(x == 0) == length(x),
      0,
      (log10(max(abs(x))) - log10(max(abs(x))) %% 3),
    )
  }
  order_text <- dplyr::case_match(
    order,
    0 ~ "",
    3 ~ " T",
    6 ~ " M",
    .default = paste0(" 1e", order)
  )
  result <- paste0(round(x / (10^order), digits = 1), order_text)
  # result <- dplyr::if_else(x == 0, "0", result)
  return(result)
}

# summary for zeiteinheiten
# used also for vergleich
ze_summary <- function(df) {
  df |> 
    dplyr::mutate(gt2 = gt, ps2 = ps) |> # copy to use for calcs after summing
    # group_by(Jahr) |>
    dplyr::summarise(
      total = dplyr::n(),
      dplyr::across(c(ps:gt,lv_personen:v_personen), sum),
      io = sum(ioao == "innerorts"),
      io_ps = sum(ioao == "innerorts" & ps2),
      ao = sum(ioao == "ausserorts"),
      ao_ps = sum(ioao == "ausserorts" & ps2),
      abas = sum(strassenart %in% c("Autobahn", "Autostrasse")),
      abas_ps = sum(strassenart %in% c("Autobahn", "Autostrasse") & ps2),
      schulweg = sum(kinderunfall & schulweg),
      velo = sum(velo),
      hu_alk = sum(hauptursache == "Einwirkung von Alkohol"),
      hu_geschw = sum(hauptursache_unter_grp == "Geschwindigkeit"),
      hu_alkgeschw = hu_alk + hu_geschw,
      gt_ebikers = sum(gt_ebikers)
    )
}

# days in a year or multiple years (01.01.year to 01.01.to_year+1)
n_days <- function(year, to_year = NULL) {
  if(is.null(to_year)) to_year = year + 1
  else to_year = to_year + 1
  as.numeric(lubridate::make_date(to_year) - lubridate::make_date(year))
}

try_nb <- function(data, base_coef) {
  fit_nb <- tryCatch(
    MASS::glm.nb(n ~ Jahr, data = data, start = base_coef),
    warning = function(w) w,
    error = function(e) e
  )
  if (is(fit_nb, "warning") || is(fit_nb, "error") || !is.finite(fit_nb$theta) || fit_nb$theta <= 0) {
    fit_nb <- glm(
      n ~ Jahr,  data = data,
      family = MASS::negative.binomial(theta = 1e6), 
      start = base_coef,
      control = glm.control(epsilon = 1e-8, maxit = 200, trace = FALSE)
    )
  }
  fit_nb
}


#' Add glm Fit
#' 
#' Tries to fit a MASS::glm.nb to a dataset with formula n ~ Jahr for each grouping variable.
#' Falls back to glm with fixed theta if it fails.
#' @param df a data frame eith columns Jahr and n
#' @param ... grouping column(s)
#' @param a sensitivity level for confidence interval
#' @noRd
add_glm_fit <- function(df, ..., a = 0.05) {
  df |>
    dplyr::nest_by(...) |> 
    dplyr::mutate(
      base_fit = list(
        glm(n ~ Jahr, family = "quasipoisson", data = data,
            control = list(epsilon = 1e-8, maxit = 200, trace = FALSE))
      ),
      model = list(try_nb(data, coef(base_fit))),
      glm_fit = list(predict(model, se.fit = T, type = "link"))
    ) |> 
    dplyr::reframe(
      Jahr = data$Jahr,
      n = data$n,
      pred = exp(glm_fit$fit),
      high = exp(glm_fit$fit + glm_fit$se.fit*qnorm(1 - a/2)),
      low  = exp(glm_fit$fit + glm_fit$se.fit*qnorm(a/2))
    )
}


faz_to_color <- function(faz, grouped = T) {
  if (grouped) {
    levels <- levels(unf_df$fahrzeugart_grp)
    colors <- ktz_palette[1:length(levels)]
    colors <- setNames(colors, levels)
  } else {
    levels <- levels(unf_df$fahrzeugart)
    colors <- ktz_palette[1:length(levels)]
    colors <- setNames(colors, levels)
  }
  unname(colors[as.character(faz)])
}

factor_to_ktz_palette <- function(fct) {
  levels <- levels(fct)
  colors <- ktz_palette[1:length(levels)]
  setNames(colors, levels)
}

add_spinner <- function(x, ...) {
  bslib::as_fill_carrier(
    shinycssloaders::withSpinner(x, hide.ui = T, ...)
  )
}


