
#' Automatic new data preparation 
#'
#' Gets the accident data of the current year from the SQL and prepares it for usage in the app.
#' 
#' @param con A connection to the SQL Server
#' @noRd
data_prep_new_auto <- function(con) {
  
  unf_new_df <- con |> get_sql_data("unf", suffix = "_laufendes_jahr", schema = "staging")
  obj_new_df <- con |> get_sql_data("obj", suffix = "_laufendes_jahr", schema = "staging")
  per_new_df <- con |> get_sql_data("person", suffix = "_laufendes_jahr", schema = "staging")

  # unf clean ---------------------------------------------------------------
  
  unf_new_df <- unf_new_df |> 
    dplyr::mutate(
      unfalltyp_grp = dplyr::if_else(
        unfalltyp_grp %in% c(
          "Überholunfall oder Fahrstreifenwechsel", 
          "Überholunfall, Fahrstreifenwechsel",
          "Überholunfall und Fahrstreifenwechsel"
        ),
        "Überholunfall oder Fahrstreifenwechsel",
        unfalltyp_grp
      ),
      hauptursache = stringr::str_remove_all(hauptursache, "[«»]")
    )
  
  # unf new columns ---------------------------------------------------------
  
  unf_new_df <- unf_new_df |>
    dplyr::mutate(
      jahr = as.integer(jahr),
      gt = gt_personen>0,
      sv = sv_personen>0 & !gt,
      lv = lv_personen>0 & !sv & !gt,
      ss = uv_personen == total_personen,
      ps = !ss,
      v_personen = total_personen - uv_personen, 
      is_stadt = gemeinde %in% c("Z\u00fcrich", "Winterthur"),
      is_zh = gemeinde %in% c("Z\u00fcrich"),
      is_win = gemeinde %in% c("Winterthur"),
      is_abas = strassenart %in% c("Autobahn", "Autostrasse", "Autobahnnebenanlage"),
      is_ksn = !is_stadt & (strassenkategorie == "Kantonsstrasse") & !is_abas
    ) |> 
    dplyr::mutate(
      schwere = dplyr::case_when(
        ss ~ "Sachschaden",
        lv ~ "Leichtverletzten",
        sv ~ "Schwerverletzten",
        gt ~ "Get\u00f6tete"
      ),
      schwere = factor(
        schwere,
        levels = c("Sachschaden", "Leichtverletzten","Schwerverletzten", "Get\u00f6tete")
      )
    ) |> 
    dplyr::mutate(
      schwere = paste0("Unf\u00e4lle mit ", schwere, dplyr::if_else(stringr::str_ends(schwere, "e"), "n", "")),
      schwere = forcats::fct_infreq(schwere)
    )
  
  
  # kosten ------------------------------------------------------------------
  
  # unf_kosten berechnen (gem\u00e4ss VSS 41713 ziffer 12)
  unf_new_df <- unf_new_df |>
    dplyr::mutate(
      kosten12 = dplyr::case_when(
        ss ~ t12[[1, 3]],
        lv ~ dplyr::if_else(
          ioao == "ausserorts",
          dplyr::if_else(
            strassenart %in% c("Autostrasse", "Autobahn"),
            t12[[1, 2]],
            t12[[2, 2]]
          ),
          t12[[3, 2]]
        ),
        sv | gt ~ dplyr::if_else(
          ioao == "ausserorts",
          dplyr::if_else(
            strassenart %in% c("Autostrasse", "Autobahn"),
            t12[[1, 1]],
            t12[[2, 1]]
          ),
          t12[[3, 1]]
        ),
        .default = -1
      )
    )
  
  # check for errors
  if(-1 %in% unique(unf_new_df$kosten12)) {
    stop("Unhandeled case in kosten12")
  }
  
  # koordinaten -------------------------------------------------------------
  
  # new columns with transformed coordinates and delete x,y
  # https://www.swisstopo.admin.ch/de/karten-daten-online/calculation-services.html
  # "N\u00e4herungsformeln f\u00fcr die Transformation zwischen Schweizer Projektionskoordinaten und WGS84"
  unf_new_df <- unf_new_df |>
    dplyr::mutate(
      temp_y = (koord_e - 2600000) / 1000000,
      temp_x = (koord_n - 1200000) / 1000000
    ) |>
    dplyr::mutate(
      lng = 2.6779094 + 4.728982 * temp_y + 0.791484 * temp_y * temp_x + 0.1306 * temp_y * temp_x^2 - 0.0436 * temp_y^3,
      lat = 16.9023892 + 3.238272 * temp_x - 0.270978 * temp_y^2 - 0.002528 * temp_x^2 - 0.0447 * temp_y^2 * temp_x - 0.0140 * temp_x^3,
      .after = koord_n
    ) |>
    dplyr::mutate(
      lng = lng * 100 / 36,
      lat = lat * 100 / 36
    ) |>
    dplyr::select(!c(temp_x, temp_y)) |> # , koord_e, koord_n))
    dplyr::rename(lv95_e = koord_e, lv95_n = koord_n)
  
  
  # obj new columns ---------------------------------------------------------
  
  obj_new_df <- obj_new_df |> 
    dplyr::mutate(
      jahr = as.integer(jahr),
      kosten12 = 1 # dummy column, don't remove
    )
  # fahrzeugart ---------------------------------------------------------
  
  group_levels <- c("Personenwagen", "Motorrad", "Fahrrad", "E-Bike", 
                    "Fussg\u00e4nger", "Fahrzeug\u00e4hnliches Ger\u00e4t",
                    "Personentransport (ohne \u00d6V)", "\u00d6ffentlicher Verkehr",
                    "Sachentransport", "Landwirtschaft", "Andere (motorisiert)",
                    "Andere (nicht motorisiert)", "Unbekannt")
  
  obj_new_df <- obj_new_df |> 
    dplyr::mutate(
      fahrzeugart = stringr::str_extract(fahrzeugart, "([|0-9 ]+)?([^|]+)(\\|)?", group = 2),
      fahrzeugart_grp = to_grp(fahrzeugart),
      fahrzeugart = forcats::fct_infreq(fahrzeugart),
      fahrzeugart_grp = factor(fahrzeugart_grp, group_levels),
    )
  
  
  faz_df <- obj_new_df |> 
    dplyr::filter(hauptverursacher) |> 
    dplyr::select(unf_uid, fahrzeugart, fahrzeugart_grp)
  
  
  # per new columns ----------------------------------------------------------
  
  per_new_df <- per_new_df |> 
    dplyr::mutate(
      jahr = as.integer(jahr),
      unfallfolgen = dplyr::case_when(
        unfallfolgen %in% c("erheblich verletzt", "lebensbedrohlich verletzt") ~ "schwer verletzt",
        unfallfolgen %in% c("auf Platz gestorben", "innert 30 Tagen gestorben") ~ "gestorben",
        .default = unfallfolgen
      ),
      unfallfolgen = forcats::fct_infreq(unfallfolgen)
    ) |>
    dplyr::mutate(kosten12 = 1) # dummy column, don't remove
  
  
  # joins -------------------------------------------------------------------
  
  unf_new_df <- unf_new_df |>
    dplyr::left_join(faz_df, dplyr::join_by(unf_uid))
  
  obj_new_df <- obj_new_df |> 
    dplyr::left_join(
      unf_new_df |> dplyr::select(unf_uid, ioao, starts_with("is_")),
      dplyr::join_by(unf_uid)
    ) |> 
    dplyr::left_join(
      per_new_df |> 
        dplyr::filter(per_nr == 1) |> 
        dplyr::select(obj_uid, schwere = unfallfolgen),
      dplyr::join_by(obj_uid)
    )
  
  per_new_df <- per_new_df |> 
    dplyr::left_join(
      obj_new_df |> dplyr::select(
        obj_uid, fahrzeugart, fahrzeugart_grp, hauptverursacher, ioao, 
        dplyr::starts_with("is_")
      ),
      dplyr::join_by(obj_uid)
    )
  
  
  
  # dates -------------------------------------------------------------------
  
  unf_new_df <- unf_new_df |> 
    dplyr::mutate(stunde = stringr::str_sub(unfallzeit, end = 2)) |> 
    dplyr::mutate(
      datum = as.Date(datum),
      unfallzeit = as.POSIXct(
        paste(datum, unfallzeit), format = "%F %T"
      )
    )
  
  obj_new_df <- obj_new_df |> 
    dplyr::mutate(datum = as.Date(datum))
  
  per_new_df <- per_new_df |> 
    dplyr::mutate(datum = as.Date(datum))
  
  #gauge stuff
  kinder_uid <- per_new_df |> 
    dplyr::filter(
      alter <= 14, 
      personenart %in% c("FäG", "Fussgänger/in", "Lenker/in")
    ) |> 
    dplyr::pull(unf_uid) |> 
    unique()
  
  jugend_uid <- per_new_df |> 
    dplyr::filter(
      14 < alter, alter <= 17
    ) |> 
    dplyr::pull(unf_uid) |> 
    unique()
  
  junge_erw_uid <- per_new_df |> 
    dplyr::filter(
      17 < alter, alter <= 24
    ) |> 
    dplyr::pull(unf_uid) |> 
    unique()
  
  senioren_uid <- per_new_df |> 
    dplyr::filter(alter > 64) |> 
    dplyr::pull(unf_uid) |> 
    unique()
  
  unf_new_df <- unf_new_df |> 
    dplyr::mutate(
      kinderunfall = unf_uid %in% kinder_uid,
      jugendunfall = unf_uid %in% jugend_uid,
      junge_erw_unfall = unf_uid %in% junge_erw_uid,
      seniorenunfall = unf_uid %in% senioren_uid
    )
  
  schulweg_uid <- obj_new_df |> 
    dplyr::filter(
      fahrzweck %in% c("Schulweg", "Schülertransport")
    ) |> 
    dplyr::pull(unf_uid) |> 
    unique()
  
  baum_uid <- obj_new_df |> 
    dplyr::filter(
      stringr::str_detect(anprall, "Baum")
    ) |> 
    dplyr::pull(unf_uid) |> 
    unique()
  
  unf_new_df <- unf_new_df |> 
    dplyr::mutate(
      schulweg = unf_uid %in% schulweg_uid,
      baum = unf_uid %in% baum_uid
    )
  
  # minimize ----------------------------------------------------------------
  unf_new_df <- unf_new_df |>
    dplyr::select(
      unf_uid, Jahr = jahr, datum, unfallzeit, schwere, ps, ss, lv, sv , gt, 
      kosten12, lv_personen, sv_personen, gt_personen, v_personen, uv_personen,
      ioao, strassenart, dplyr::starts_with("is_"), fahrzeugart, fahrzeugart_grp,
      lng, lat, lv95_e, lv95_n, kinderunfall, jugendunfall, junge_erw_unfall, seniorenunfall,
      hauptursache, hauptursache_unter_grp, schulweg, baum, unfalltyp = unfalltyp_grp,
      unfallstelle_zus, stunde, zonensignalisation
    )
  
  obj_new_df <- obj_new_df |> 
    dplyr::select(
      unf_uid, obj_uid, obj_n, Jahr = jahr, datum, fahrzeugart, fahrzeugart_grp, fahrzeugart_zus,
      hauptverursacher, dplyr::starts_with("is_"), kosten12, schwere, ioao
    )
  
  per_new_df <- per_new_df |> 
    dplyr::select(
      unf_uid, obj_uid, obj_n, per_uid, per_n = per_nr, Jahr = jahr, datum, 
      hauptverursacher, alter, fuehrerausweisalter, schwere = unfallfolgen, personenart,
      starts_with("is_"), fahrzeugart_grp, fahrzeugart, kosten12, ioao
    )
  
  # add the date of last update as metadata
  # attr(unf_new_df, "stand") <- as.Date("2025-03-06")
  
  unf_new_df <<- unf_new_df
  obj_new_df <<- obj_new_df
  per_new_df <<- per_new_df
}
