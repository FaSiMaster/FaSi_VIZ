
make_template_lv95 <- function(area_sf_2056, step_m) {
  bb   <- sf::st_bbox(area_sf_2056)
  ncol <- ceiling((bb["xmax"] - bb["xmin"]) / step_m)
  nrow <- ceiling((bb["ymax"] - bb["ymin"]) / step_m)
  terra::rast(xmin = bb["xmin"], xmax = bb["xmax"],
              ymin = bb["ymin"], ymax = bb["ymax"],
              ncols = ncol, nrows = nrow,
              crs   = "EPSG:2056")
}

rasterize_counts <- function(df_points, r_template) {
  # df_points: deve avere lv95_e, lv95_n (metri)
  pts <- sf::st_as_sf(df_points, coords = c("lv95_e","lv95_n"), crs = 2056)
  terra::rasterize(terra::vect(pts), r_template,
                   field = 1, fun = "sum", background = 0)
}


mapdensity_data <- function(base_data, current_data, r_template, area_zh_2056, smooth_sigma = 100) {
  years_hist   <- min(base_data$Jahr):max(base_data$Jahr)
  year_now     <- as.numeric(min(current_data$Jahr))
  
  setProgress(0.15, detail = "Historische Daten werden vorbereitet...")
  r_stack_hist <- lapply(years_hist, function(y) {
    d_y <- base_data |> dplyr::filter(Jahr == y)
    rasterize_counts(d_y, r_template)
  })
  r_hist <- terra::app(terra::rast(r_stack_hist), fun = median, na.rm = TRUE)
  
  setProgress(0.30, detail = "Laufende Daten werden vorbereitet...")
  r_now <- rasterize_counts(current_data, r_template)
  
  setProgress(0.45, detail = "Differenz laufende - historische...")
  r_delta <- r_now - r_hist
  r_delta <- terra::ifel(is.na(r_delta), 0, r_delta)
  r_delta <- terra::mask(r_delta, terra::vect(area_zh_2056))
  names(r_delta) <- paste0(year_now, "_minus_hist")
  
  setProgress(0.60, detail = "Glättung wird vorbereitet...")
  if (smooth_sigma > 0) {
    W <- terra::focalMat(r_delta, d = smooth_sigma, type = "Gauss")
    r_delta <- terra::focal(r_delta, w = W, na.policy = "omit", na.rm = TRUE)
  }
  
  setProgress(0.80, detail = "Projektion...")
  r_leaf <- terra::project(r_delta, "EPSG:3857", method = "bilinear")
  
  r_leaf
}
