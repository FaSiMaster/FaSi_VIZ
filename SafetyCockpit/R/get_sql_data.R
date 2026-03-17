
get_sql_data <- function(con, level, suffix = "", schema = "core") {
  if(!level %in% c("unf", "obj", "person")) stop("Wrong level")
  
  db <- con |> 
    dplyr::tbl(dbplyr::in_schema(schema, paste0(level, suffix)))
  
  
  if(suffix == "_all") {
    if(level == "unf"){
      db <- db |>
        dplyr::select(
          unf_uid, datum, unfallzeit, gemeinde, ioao, lv95_e, lv95_n, strassenart,
          strassenkategorie, dplyr::starts_with("unfaelle_mit"), dplyr::ends_with("_personen"),
          unfalltyp_grp, hauptursache, hauptursache_unter_grp, strassenzustand, strassenbeleuchtung,
          lichtverhaeltnis, verkehrsaufkommen, unfallstelle_zus, witterung, zonensignalisation, vortrittsregelung
        )
    } else if(level == "obj") {
      db <- db |> 
        dplyr::select(
          unf_uid, obj_uid, obj_nr_intern, kategorie, hauptverursacher, ursache_2, ursache_3,
          fahrzeugart, fahrzeugart_zus, faz, fahrzweck, anprall
        )
    } else if(level == "person") {
      db <- db |> 
        dplyr::select(
          unf_uid, obj_uid, obj_nr_intern, person_uid, person_nr, alter, wohnland,
          fuehrerausweisalter, unfallfolgen, personenart, schutzsystem
        )
    }
  }
  
  db |> tibble::as_tibble()
}

load_users <- function(schema = "core") {
  creds <- config::get(file = "conf/credentials.yml")
  
  baud_azure <- DBI::dbConnect(
    drv = odbc::odbc(), 
    driver = "SQL Server", 
    server = creds$server, 
    uid = creds$user, 
    pwd = creds$pwd, 
    database = "sqldb-baudi-data"
  )
  
  user_df <<- baud_azure |>
    dplyr::tbl(dbplyr::in_schema(schema, "safety_cockpit_user")) |> 
    tibble::as_tibble()
  
  on.exit(DBI::dbDisconnect(baud_azure))
}

get_prognose <- function(con) {
  con |>
    dplyr::tbl(dbplyr::in_schema("core", "unfall_prognose")) |>
    tibble::as_tibble()
}

get_wetter <- function(con){
  con |> 
    dplyr::tbl(dbplyr::in_schema("core", "wetter_api_last7days")) |> 
    tibble::as_tibble()
}

get_stand <- function(con) {
  con |> 
    dplyr::tbl(dbplyr::in_schema("core", "laufend_stand")) |> 
    dplyr::pull(stand) |> 
    as.Date()
}

update_laufend <- function(force = F) {
  creds <- config::get(file = "conf/credentials.yml")
  
  baud_azure <- DBI::dbConnect(
    drv = odbc::odbc(), 
    driver = "SQL Server", 
    server = creds$server, 
    uid = creds$user, 
    pwd = creds$pwd, 
    database = "sqldb-baudi-data"
  )
  
  sql_stand <- get_stand(baud_azure)
  
  if((sql_stand > stand) | force) {
    data_prep_new_auto(baud_azure)
    #wetter_df <<- get_wetter(baud_azure)
    prognose_df <<- get_prognose(baud_azure)
    stand <<- sql_stand
    max_date <<- min(
      # cut out data in the next year
      # (only relevant before the new historical data is ready, i.e. March)
      as.Date(paste0(max_jahr+1, "-12-31")),
      as.Date(stand - lubridate::days(30))
    )
  }
  
  unf_new_df <<- unf_new_df |> dplyr::filter(Jahr > max_jahr)
  obj_new_df <<- obj_new_df |> dplyr::filter(Jahr > max_jahr)
  per_new_df <<- per_new_df |> dplyr::filter(Jahr > max_jahr)
  
  on.exit(DBI::dbDisconnect(baud_azure))
}

db_set_new_pwd <- function(username, password, schema = "core") {
  credentials <- config::get(file = "conf/credentials.yml")
  
  baud_azure <- DBI::dbConnect(
    drv = odbc::odbc(),
    driver = "SQL Server",
    server = credentials$server,
    uid = credentials$user,
    pwd = credentials$pwd,
    database = "sqldb-baudi-data"
  )
  
  on.exit(DBI::dbDisconnect(baud_azure))
  
  sodium_password <- sodium::password_store(password)
  
  DBI::dbExecute(
    baud_azure, 
    paste0(
      "UPDATE ", schema, ".safety_cockpit_user
      SET [sc_password] = ?, make_new_password = 0
      WHERE [sc_user] = ?"
    ),
    params = list(sodium_password, username)
  )
}

db_log_login <- function(username, schema = "core") {
  credentials <- config::get(file = "conf/credentials.yml")
  
  baud_azure <- DBI::dbConnect(
    drv = odbc::odbc(),
    driver = "SQL Server",
    server = credentials$server,
    uid = credentials$user,
    pwd = credentials$pwd,
    database = "sqldb-baudi-data"
  )
  on.exit(DBI::dbDisconnect(baud_azure))
  
  DBI::dbExecute(
    baud_azure,
    paste0("INSERT INTO ", schema,".safety_cockpit_log (username) VALUES (?)"),
    params = list(username)
  )
}
