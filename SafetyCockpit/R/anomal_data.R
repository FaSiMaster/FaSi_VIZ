anomal_data <- function(old, new, maxd){
  
  tmp <- rbind(old |> dplyr::select(Jahr, 
                                    datum, 
                                    ps, 
                                    ss, 
                                    lv, 
                                    sv, 
                                    gt, 
                                    ioao, 
                                    is_stadt, 
                                    is_zh, 
                                    is_win, 
                                    is_abas, 
                                    is_ksn, 
                                    fahrzeugart_grp,
                                    unfalltyp,
                                    hauptursache_unter_grp, 
                                    kinderunfall, 
                                    jugendunfall, 
                                    junge_erw_unfall, 
                                    seniorenunfall
                     ), 
                     new |> dplyr::select(Jahr, 
                                          datum, 
                                          ps, 
                                          ss, 
                                          lv,
                                          sv, 
                                          gt,
                                          ioao,
                                          is_stadt,
                                          is_zh,
                                          is_win,
                                          is_abas, 
                                          is_ksn,
                                          fahrzeugart_grp,
                                          unfalltyp,
                                          hauptursache_unter_grp, 
                                          kinderunfall, 
                                          jugendunfall,
                                          junge_erw_unfall, 
                                          seniorenunfall
                      )
)
  
tmp <- tmp |> 
  dplyr::mutate(sv_gt = sv | gt, .before = ioao) |> 
  dplyr::mutate(altersklasse = dplyr::case_when(kinderunfall ~ "<= 14", 
                                         jugendunfall ~"15-17", 
                                         junge_erw_unfall ~"18-24", 
                                         TRUE ~ "25-64", 
                                         seniorenunfall ~ "65+"),
                altersklasse = as.factor(altersklasse), 
                .before = kinderunfall
  ) |> 
  dplyr::mutate(gebiet = dplyr::case_when(is_abas ~ "Autobahn", 
                                               is_ksn ~ "Staatsstrassen", 
                                               is_zh & !is_abas ~ "Stadt Zürich", 
                                               is_win & !is_abas ~ "Stadt Winterthur",
                                               TRUE ~ "Andere"),
                gebiet = as.factor(gebiet), 
                .before = is_stadt
  ) |> 
  dplyr::mutate(ioao = as.factor(ioao),
                unfalltyp = as.factor(unfalltyp),
                hauptursache_unter_grp = as.factor(hauptursache_unter_grp)
  ) |> 
  dplyr::rename(Ioao = ioao,
                Gebiet = gebiet,
                Fahrzeugart = fahrzeugart_grp,
                Altersklasse = altersklasse,
                Hauptursache = hauptursache_unter_grp,
                Unfalltyp = unfalltyp
  ) |> 
  tidyr::drop_na() |> 
  dplyr::filter(lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(maxd)*100 + lubridate::day(maxd)) |> 
  dplyr::select(
    -datum,
    -is_stadt, 
    -is_zh, 
    -is_win, 
    -is_abas, 
    -is_ksn, 
    -kinderunfall, 
    -jugendunfall, 
    -junge_erw_unfall, 
    -seniorenunfall           
  )

  tmp
}
