#' Sunrise and Sunset
#' 
#' Calculates the rise and set of the sun given coordinates and a date.
#' By default it calculates the regular rise and set times, but one can adjust 
#' h_o_deg to get civil, nautical and astronomical twilight as well.
#' Based on https://en.wikipedia.org/wiki/Sunrise_equation#Complete_calculation_on_Earth
#' 
#' @param lat,long Latitude and longitude in degrees (can be vectors).
#' @param date The date to be considered (can be vector).
#' @param extra_cols Should extra columns be returned?
#' @param tz_out By default the function tries to infer the output timezone from
#' the system, this is an override for it. Must be a string which as.POSIXct can handle or NULL.
#' @param h_o_deg Angle to the horizon in degrees. The default value is generally
#' correct, but can be adjusted for minor correction or changed completely to get
#' civil (-6°), nautical (-12°) and astronomical (-18°) twilight.
sunriset <- function(lat, lng, date, extra_cols = F, tz_out = NULL, h_o_deg = -0.8333, prefix = "") {
  
  if(is.null(tz_out)) tz_out <- Sys.timezone()
  
  # degrees to radians
  dtr <- pi/180
  
  # add 0.5 because we want difference from 2000-01-01 12:00
  # 69.184/86400.0 =~ 0.0008
  n <- ceiling(as.numeric(
    julian(date, origin = as.Date("2000-01-01")) + 0.5 + 69.184/86400.0
  ))
  
  J <- n - lng / 360
  
  M_deg <- (357.5291 + 0.98560028 * J) %% 360
  M <- M_deg*dtr
  
  C_deg <- 1.9148*sin(M) + 0.0200*sin(2*M) + 0.0003*sin(3*M)
  C <- C_deg*dtr
  
  lambda_deg <- (M_deg + C_deg + 180 + 102.9372) %% 360
  lambda <- lambda_deg*dtr
  
  J_transit <- J + 0.0053*sin(M) - 0.0069*sin(2*lambda)
  
  sin_delta <- sin(lambda) * sin(23.4397*dtr)
  delta <- asin(sin(lambda) * sin(23.4397*dtr))
  delta_deg <- delta/dtr
  
  h_o <- h_o_deg*dtr
  
  w_o <- acos((sin(h_o) - sin(lat*dtr) * sin(delta)) / (cos(lat*dtr)*cos(delta))) / dtr
  
  J_rise <- J_transit - w_o/360
  J_set <- J_transit + w_o/360 
  
  # subtract 0.5 to remove the 12:00 then convert using 2000-01-01
  rise <- as.POSIXct(as.Date(J_rise - 0.5, origin = "2000-01-01"), tz = tz_out)
  set <- as.POSIXct(as.Date(J_set - 0.5, origin = "2000-01-01"), tz = tz_out)
  
  if(extra_cols) {
    out <- data.frame(
      "date" = date, "lat" = lat, "lng" = lng, "rise" = rise, "set" = set,
      "j_rise" = J_rise, "j_transit" = J_transit, "j_set" = J_set
    )
  } else {
    out <- data.frame("rise" = rise, "set" = set)
  }
  names(out) <- paste0(prefix, names(out))
  out
}

#' Sunriset for dataframes
#' 
#' Method to apply the function sunriset to a dataframe (or tibble) with some
#' predefined columns.
#'
#' @param df A dataframe with columns lat, lng and datum.
#' @param join If True then the function returns a column bind of the original 
#' dataframe with the computed columns (will create duplicates if extra_cols = True).
#' @param ... Other Arguments passed on to sunriset
sunriset_df <- function(df, join = T, ...) {
  if(join) cbind(df, sunriset(df$lat, df$lng, df$datum, ...))
  else sunriset(df$lat, df$lng, df$datum, ...)
}

#' Lighting Condition
#' 
#' What part of the day is it? Given lat, lng and time you get what part of the
#' day it is (day, night, civil, nautical or astronomical twilight).
#' This function does not work if there is no astronomical twilight during that
#' day in that place, see
#' https://en.wikipedia.org/wiki/Twilight#Between_day_and_night
#' 
#' @param lat,long Latitude and longitude in degrees (can be vectors).
#' @param time A datetime or a vector of datetimes.
lighting_condition <- function(lat, lng, time) {
  
  date <- lubridate::floor_date(time, "day")
  
  riset <- sunriset(lat, lng, date)
  civil <- sunriset(lat, lng, date, h_o_deg = -6)
  nautical <- sunriset(lat, lng, date, h_o_deg = -12)
  astronomical <- sunriset(lat, lng, date, h_o_deg = -18)
  astronomical_set_yesterday <- sunriset(
    lat, lng, date - lubridate::days(1), h_o_deg = -18
  )$set
  astronomical_rise_tomorrow <- sunriset(
    lat, lng, date + lubridate::days(1), h_o_deg = -18
  )$rise

  lc <- dplyr::case_when(
    time <= astronomical_set_yesterday ~ "astronomische Dämmerung",
    astronomical_set_yesterday < time & time <= astronomical$rise ~ "Nacht",
    astronomical$rise < time & time <= nautical$rise ~ "astronomische Dämmerung",
    nautical$rise < time & time <= civil$rise ~ "nautische Dämmerung",
    civil$rise < time & time <= riset$rise ~ "bürgerliche Dämmerung",
    riset$rise < time & time <= riset$set ~ "Tag",
    riset$set < time & time <= civil$set ~ "bürgerliche Dämmerung",
    civil$set < time & time <= nautical$set ~ "nautische Dämmerung",
    nautical$set < time & time <= astronomical$set ~ "astronomische Dämmerung",
    astronomical$set < time & time <= astronomical_rise_tomorrow ~ "Nacht",
    astronomical_rise_tomorrow < time ~ "astronomische Dämmerung",
    is.na(time) ~ "unbekannt"
  )
  
  factor(
    lc, levels = c("Tag", "bürgerliche Dämmerung", "nautische Dämmerung",
                   "astronomische Dämmerung", "Nacht", "unbekannt")
  )
}
