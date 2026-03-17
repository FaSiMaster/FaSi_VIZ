#' Automatic data preparation 
#'
#' Prepares the accidents data for usage in the app.
#' 
#' @param unf_df,obj_df,per_df Dataframes from SQL (see data_prep_auto)
#' @noRd
data_prep <- function(unf_df, obj_df, per_df) {
  # UNFALL ------------------------------------------------------------------
  
  # rename ------------------------------------------------------------------
  
  colnames(unf_df) <- colnames(unf_df) |>
    stringr::str_remove_all("^unfaelle_mit_")
  
  # unf_df <- unf_df |>  
  #   dplyr::rename(
  #     ss = unfaelle_mit_ss,
  #     lv = unfaelle_mit_lv,
  #     sv = unfaelle_mit_sv,
  #     gt = unfaelle_mit_gt,
  #     ps = unfaelle_mit_ps
  # )
  
  
  # «» ----------------------------------------------------------------------
  
  unf_df <- unf_df |> 
    dplyr::mutate(dplyr::across(
      hauptursache, # c(unfalltyp, hauptursache, vortrittsregelung),
      ~stringr::str_remove_all(.x, "«|»")
    ))
  
  
  # Andere -> andere --------------------------------------------------------
  
  unf_df <- unf_df |> 
    dplyr::mutate(dplyr::across(
      strassenart, # c(strassenart, strassenkategorie),
      ~ dplyr::if_else(
        .x == "Andere",
        "andere",
        .x
      )
    ))
  
  
  # Datum Unfallzeit --------------------------------------------------------
  
  unf_df <- unf_df |>
    dplyr::mutate(stunde = stringr::str_sub(unfallzeit, end = 2)) |> 
    dplyr::mutate(
      unfallzeit = as.POSIXct(
        paste(datum, unfallzeit), format = "%F %T"
      ),
      datum = as.Date(datum)
    )
  
  # schwere -----------------------------------------------------------------
  
  unf_df <- unf_df |> 
    dplyr::mutate(
      schwere = dplyr::case_when(
        gt ~ "Unf\u00e4lle mit Get\u00f6teten",
        sv ~ "Unf\u00e4lle mit Schwerverletzten",
        lv ~ "Unf\u00e4lle mit Leichtverletzten",
        ss ~ "Unf\u00e4lle mit Sachschaden"
      ),
      schwere = factor(
        schwere , 
        levels = c("Unf\u00e4lle mit Sachschaden", "Unf\u00e4lle mit Leichtverletzten",
                   "Unf\u00e4lle mit Schwerverletzten", "Unf\u00e4lle mit Get\u00f6teten"))
    )
  
  
  # kosten ------------------------------------------------------------------
  
  # unf_kosten berechnen (gem\u00e4ss VSS 41713 ziffer 12)
  unf_df <- unf_df |>
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
  if(-1 %in% unique(unf_df$kosten12)) {
    stop("Unhandeled case in kosten12")
  }
  
  
  # koordinaten -------------------------------------------------------------
  
  # new columns with transformed coordinates and delete x,y
  # https://www.swisstopo.admin.ch/de/karten-daten-online/calculation-services.html
  # "N\u00e4herungsformeln f\u00fcr die Transformation zwischen Schweizer Projektionskoordinaten und WGS84"
  unf_df <- unf_df |>
    dplyr::mutate(
      temp_y = (lv95_e - 2600000) / 1000000,
      temp_x = (lv95_n - 1200000) / 1000000
    ) |>
    dplyr::mutate(
      lng = 2.6779094 + 4.728982 * temp_y + 0.791484 * temp_y * temp_x + 0.1306 * temp_y * temp_x^2 - 0.0436 * temp_y^3,
      lat = 16.9023892 + 3.238272 * temp_x - 0.270978 * temp_y^2 - 0.002528 * temp_x^2 - 0.0447 * temp_y^2 * temp_x - 0.0140 * temp_x^3,
      .after = lv95_n
    ) |>
    dplyr::mutate(
      lng = lng * 100 / 36,
      lat = lat * 100 / 36
    ) |>
    dplyr::select(!c(temp_x, temp_y)) # , lv95_e, lv95_n))
  
  # zones -------------------------------------------------------------------
  
  unf_df <- unf_df |> 
    dplyr::mutate(
      is_stadt = gemeinde %in% c("Z\u00fcrich", "Winterthur"),
      is_zh = gemeinde %in% c("Z\u00fcrich"),
      is_win = gemeinde %in% c("Winterthur"),
      is_abas = strassenart %in% c("Autobahn", "Autostrasse", "Autobahnnebenanlage"),
      is_ksn = !is_stadt & (strassenkategorie == "Kantonsstrasse") & !is_abas,
      Jahr = lubridate::year(datum)
    )
  

  # unfalltyp ---------------------------------------------------------------

  unf_df <- unf_df |> 
    dplyr::mutate(
      unfalltyp_grp = dplyr::if_else(
        unfalltyp_grp %in% c(
          "Überholunfall oder Fahrstreifenwechsel", 
          "Überholunfall, Fahrstreifenwechsel",
          "Überholunfall und Fahrstreifenwechsel"
        ),
        "Überholunfall oder Fahrstreifenwechsel",
        unfalltyp_grp
      )
    )
  

  # Haupturasche ------------------------------------------------------------
  
  unf_df <- unf_df |> 
    dplyr::mutate(
      hauptursache = forcats::fct_infreq(hauptursache)
    )
  
  # OBJEKT ------------------------------------------------------------------
  
  # rename ------------------------------------------------------------------
  
  obj_df <- obj_df |> 
    dplyr::rename(obj_n = obj_nr_intern)
  
  # faz ---------------------------------------------------------------------
  
  # clean fahrzeugart and faz
  obj_df <- obj_df |>
    dplyr::mutate(
      fahrzeugart = stringr::str_remove_all(fahrzeugart, "\\|")
    )
  
  # Replace the column fahrzuegart with a combination of fahrzuegart,
  # kategorie and faz, because not all objects have a faz (i.e. Fahrrad).
  # Then remove the descriptive part of the faz, leaving only the code
  obj_df <- obj_df |>
    dplyr::mutate(
      fahrzeugart = dplyr::case_when(
        is.na(faz) & !is.na(fahrzeugart) ~ fahrzeugart,
        is.na(faz) & is.na(fahrzeugart) ~ kategorie,
        .default = substr(faz, 5, nchar(faz)) # remove the code (i.e.: 001 Personenwagen -> Personenwagen)
      ),
      faz = substr(faz, 0, 3), # get only the code (i.e.: 001 Personenwagen -> 001)
      faz = dplyr::if_else(faz == "999", NA, faz) # remove the "unbekannt" faz (it's not an official code)
    ) |> 
    dplyr::mutate(
      fahrzeugart = forcats::fct_infreq(fahrzeugart)
    )
  
  
  # MAKE GROUPED VERSIONS
  # NOTE 1
  # Add column fahrzeugart_grp and fahrzeugart_grp_old, where fahrzeugart gets
  # reduced to more meaningful groups (mostly as in vusta2022). The old version is
  # valid for 2003+, the other one is better for 2013+, because there are some
  # more modern groups (i.e. E-Bike), which were not present before.
  
  # NOTE 2
  # I classified this stuff as follows:
  # Kleinmotorfahrzeug             -> Motorrad
  # Leichtmotorfahrzeug            -> Motorrad 
  # Dreir\u00e4driges Motorfahrzeug     -> Motorrad
  # Kleinmotorrad-Dreirad          -> Motorrad
  # Motorrad-Dreirad               -> Motorrad
  # Motorrad-Seitenwagen           -> Motorrad
  # Motorkarren                    -> Landw.
  # Arbeitsmaschine                -> Landw.
  # Arbeitskarren                  -> Landw.
  # Traktor                        -> Landw.
  # Sattel-Sachentransportanh\u00e4nger -> Andere (nicht motorisiert)
  # Sachentransportanh\u00e4nger        -> Andere (nicht motorisiert)
  # Anh\u00e4nger                       -> Andere (nicht motorisiert)
  # Sportger\u00e4teanh\u00e4nger            -> Andere (nicht motorisiert)
  
  uf <- unique(obj_df$fahrzeugart) |> as.character()
  group_levels <- c("Personenwagen", "Motorrad", "Fahrrad", "E-Bike",
                    "Fussg\u00e4nger", "Fahrzeug\u00e4hnliches Ger\u00e4t",
                    "Personentransport (ohne \u00d6V)", "\u00d6ffentlicher Verkehr",
                    "Sachentransport", "Landwirtschaft", "Andere (motorisiert)",
                    "Andere (nicht motorisiert)", "Unbekannt")
  obj_df <- obj_df |> 
    dplyr::mutate(
      fahrzeugart_grp = forcats::fct_collapse(
        fahrzeugart,
        "Fahrrad" = c("Fahrrad","Motorfahrrad (ohne E-Bike)"),
        "Fussg\u00e4nger" = "Fussg\u00e4nger",
        "Fahrzeug\u00e4hnliches Ger\u00e4t" = "F\u00e4G",
        "E-Bike" = c("Schnelles E-Bike", "Langsames E-Bike"),
        "Motorrad" = c(
          "Motorrad", "Kleinmotorrad", "Kleinmotorrad-Dreirad", "Motorrad-Dreirad",
          "Motorrad-Seitenwagen", "Kleinmotorfahrzeug", "Leichtmotorfahrzeug", 
          "Dreir\u00e4driges Motorfahrzeug"
        ),
        "Personenwagen" = c("Personenwagen", "Schwerer Personenwagen"),
        "Personentransport (ohne \u00d6V)" = c(
          "Leichter Motorwagen", "Schwerer Motorwagen", "Gesellschaftswagen",
          "Kleinbus"
        ),
        "\u00d6ffentlicher Verkehr" = c(
          "Gelenkbus", "Trolleybus", "Gelenktrolleybus", "Linienbus", "Tram",
          "Bahn" 
        ),
        "Landwirtschaft" = c(
          "Traktor", "Motorkarren", "Arbeitsmaschine", "Arbeitskarren",
          uf[grepl("landw",uf,ignore.case = T)]
        ),
        "Sachentransport" = c(
          "Lieferwagen", "Lastwagen", "Leichtes Sattelmotorfahrzeug", 
          "Schweres Sattelmotorfahrzeug", "Sattelschlepper"
        ),
        "Andere (motorisiert)" = "andere motorisierte Fahrzeuge",
        "Andere (nicht motorisiert)" = c(
          "andere nicht motorisierte Fahrzeuge",
          uf[grepl("anh\u00e4nger",uf,ignore.case = T)]
        ),
        "Unbekannt" = "unbekannt"
      ),
      fahrzeugart_grp = factor(fahrzeugart_grp, group_levels),
      .after = fahrzeugart
    ) |>
    dplyr::mutate(
      fahrzeugart_grp_old = forcats::fct_collapse(
        fahrzeugart_grp,
        "Fahrrad" = c("Fahrrad", "E-Bike"),
        "Fussg\u00e4nger" = c("Fussg\u00e4nger", "Fahrzeug\u00e4hnliches Ger\u00e4t")
      ),
      .after = fahrzeugart_grp
    )
  
  
  # PERSON ------------------------------------------------------------------
  
  # rename ------------------------------------------------------------------
  
  per_df <- per_df |> 
    dplyr::rename(
      obj_n = obj_nr_intern,
      per_uid = person_uid,
      per_n = person_nr
    )
  
  
  # unfallfolgen ------------------------------------------------------------
  
  per_df <- per_df |> 
    dplyr::mutate(
      unfallfolgen = dplyr::if_else(
        unfallfolgen %in% c("auf Platz gestorben", "innert 30 Tagen gestorben"),
        "gestorben", unfallfolgen
      ),
      unfallfolgen = factor(
        unfallfolgen, levels = c("nicht verletzt", "leicht verletzt", 
                                 "schwer verletzt", "gestorben", "unbekannt")
      )
    )
  
  
  # JOINS -------------------------------------------------------------------
  
  obj_df <- obj_df |> 
    dplyr::left_join(
      unf_df |> dplyr::select(unf_uid, Jahr, datum, unfallzeit, ioao, dplyr::starts_with("is_")),
      dplyr::join_by(unf_uid)
    ) |> 
    dplyr::mutate(kosten12 = 1)
  
  per_df <- per_df |> 
    dplyr::left_join(
      unf_df |> dplyr::select(unf_uid, Jahr, datum, unfallzeit, ioao, dplyr::starts_with("is_")),
      dplyr::join_by(unf_uid)
    ) |> 
    dplyr::left_join(
      obj_df |> dplyr::select(obj_uid, hauptverursacher, fahrzeugart_grp, fahrzeugart),
      dplyr::join_by(obj_uid)
    ) |> 
    dplyr::mutate(kosten12 = 1) |> 
    dplyr::rename(schwere = unfallfolgen)
  
  missing_hu_faz <- obj_df |>
    dplyr::group_by(unf_uid) |>
    dplyr::filter(all(!hauptverursacher) | all(is.na(hauptverursacher))) |>
    dplyr::filter(obj_n == 1) |> 
    dplyr::ungroup() |> 
    dplyr::select(unf_uid, fahrzeugart, fahrzeugart_grp)
  
  unf_df <- unf_df |>
    dplyr::left_join(
      obj_df |> 
        dplyr::filter(hauptverursacher) |>
        dplyr::select(unf_uid, fahrzeugart, fahrzeugart_grp) |> 
        rbind(missing_hu_faz),
      dplyr::join_by(unf_uid)
    )
  
  kinder_uid <- per_df |> 
    dplyr::filter(
      alter <= 14, 
      personenart %in% c("FäG", "Fussgänger/in", "Lenker/in")
    ) |> 
    dplyr::pull(unf_uid) |> 
    unique()
  
  jugend_uid <- per_df |> 
    dplyr::filter(
      14 < alter, alter <= 17
    ) |> 
    dplyr::pull(unf_uid) |> 
    unique()
  
  junge_erw_uid <- per_df |> 
    dplyr::filter(
      17 < alter, alter <= 24
    ) |> 
    dplyr::pull(unf_uid) |> 
    unique()
  
  senioren_uid <- per_df |> 
    dplyr::filter(alter > 64) |> 
    dplyr::pull(unf_uid) |> 
    unique()
  
  unf_df <- unf_df |> 
    dplyr::mutate(
      kinderunfall = unf_uid %in% kinder_uid,
      jugendunfall = unf_uid %in% jugend_uid,
      junge_erw_unfall = unf_uid %in% junge_erw_uid,
      seniorenunfall = unf_uid %in% senioren_uid
    )
  
  velo_uid <- obj_df |> 
    dplyr::filter(fahrzeugart_grp == "Fahrrad") |> 
    dplyr::pull(unf_uid) |> 
    unique()
  
  schulweg_uid <- obj_df |> 
    dplyr::filter(
      fahrzweck %in% c("Schulweg", "Schülertransport")
    ) |> 
    dplyr::pull(unf_uid) |> 
    unique()
  
  baum_uid <- obj_df |> 
    dplyr::filter(
      stringr::str_detect(anprall, "Baum")
    ) |> 
    dplyr::pull(unf_uid) |> 
    unique()
  
  unf_df <- unf_df |> 
    dplyr::mutate(
      schulweg = unf_uid %in% schulweg_uid,
      baum = unf_uid %in% baum_uid,
      velo = unf_uid %in% velo_uid
    )
  
  gt_ebikers_df <- per_df |> 
    dplyr::group_by(unf_uid) |> 
    dplyr::summarise(
      gt_ebikers = sum(fahrzeugart_grp == "E-Bike" & schwere == "gestorben")
    )
  
  unf_df <- unf_df |> 
    dplyr::left_join(gt_ebikers_df, dplyr::join_by(unf_uid))
  
  worst <- function(schwere) {
    if("gestorben" %in% schwere) return("gestorben")
    else if("schwer verletzt" %in% schwere) return("schwer verletzt")
    else if("leicht verletzt" %in% schwere) return("leicht verletzt")
    else if("nicht verletzt" %in% schwere) return("nicht verletzt")
    else if("unbekannt" %in% schwere) return("unbekannt")
    else stop("Unsupported schwere")
  }
  
  obj_df <- obj_df |> 
    dplyr::left_join(
      per_df |> 
        dplyr::group_by(obj_uid) |> 
        dplyr::summarise(schwere = worst(schwere)) |> 
        dplyr::mutate(schwere = factor(schwere, levels = levels(per_df$schwere))), 
      dplyr::join_by(obj_uid)
    )
  
  # MINIMIZE ----------------------------------------------------------------
  
  unf_df <- unf_df |> 
    dplyr::select(
      unf_uid, Jahr, datum, unfallzeit, schwere, ps, ss, lv, sv , gt, kosten12, 
      lv_personen, sv_personen, gt_personen, v_personen, uv_personen, ioao,
      strassenart, dplyr::starts_with("is_"),
      fahrzeugart, fahrzeugart_grp, lng, lat, lv95_e, lv95_n, unfalltyp = unfalltyp_grp,
      hauptursache, hauptursache_unter_grp, kinderunfall, jugendunfall,
      junge_erw_unfall, seniorenunfall, schulweg, baum, velo, gt_ebikers,
      strassenzustand, strassenbeleuchtung, lichtverhaeltnis, verkehrsaufkommen, unfallstelle_zus,
      stunde, witterung, zonensignalisation, vortrittsregelung
    )
  
  obj_df <- obj_df |> 
    dplyr::select(
      unf_uid, obj_uid, obj_n, Jahr, datum, unfallzeit, fahrzeugart, fahrzeugart_grp,
      fahrzeugart_zus, hauptverursacher, ursache_2, ursache_3, dplyr::starts_with("is_"), kosten12, schwere, ioao,
      fahrzweck, anprall
    )
  
  per_df <- per_df |> 
    dplyr::select(
      unf_uid, obj_uid, obj_n, per_uid, per_n, Jahr, datum, unfallzeit, hauptverursacher, 
      wohnland, alter, fuehrerausweisalter, schwere, personenart, dplyr::starts_with("is_"),
      fahrzeugart_grp, fahrzeugart, kosten12, ioao, schutzsystem
    )
  
  # list(unf_df, obj_df, per_df)
  unf_df <<- unf_df
  obj_df <<- obj_df
  per_df <<- per_df
}

#' Automatic data preparation 
#'
#' Gets the historical accident data from the SQL and prepares it for usage in the app.
#' 
#' @param con A connection to the SQL Server
#' @noRd
data_prep_auto <- function(con) {
  data_prep(
    get_sql_data(con, "unf",    suffix = "_all", schema = "core"),
    get_sql_data(con, "obj",    suffix = "_all", schema = "core"),
    get_sql_data(con, "person", suffix = "_all", schema = "core")
  )
}
