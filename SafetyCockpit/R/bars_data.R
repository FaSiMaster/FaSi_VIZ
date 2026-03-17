
bars_data <- function(df, new_df, factor, minmax, max_date_ = NULL) {
  if(is.null(max_date_)) max_date_ <- max_date
  
  laufend_name <- if(lubridate::year(max_date_) == max_jahr+1) {
    paste0("Laufendes Jahr")
  } else {
    paste0(lubridate::year(max_date_))
  }
  
  temp <- df |> 
    dplyr::filter(lubridate::month(datum)*100 + lubridate::day(datum) <= lubridate::month(max_date_)*100 + lubridate::day(max_date_)) |> 
    dplyr::count(Jahr, {{ factor }}, .drop = F) |> 
    dplyr::group_by({{ factor }}) |> 
    dplyr::summarise(n = median(n))
  
  names(temp)[2] <- minmax
  
  temp2 <- new_df |> 
    dplyr::filter(datum <= max_date_) |> 
    dplyr::count({{ factor }}, .drop = F) |> 
    dplyr::slice_max(n, n = 5) |> 
    dplyr::arrange(n)
  
  names(temp2)[2] <- laufend_name

  temp2 |> 
    dplyr::left_join(temp, dplyr::join_by({{ factor }})) |> 
    # dplyr::arrange(`Laufendes Jahr`) |> 
    dplyr::mutate({{ factor }} := forcats::fct_inorder({{ factor }})) |> 
    tidyr::pivot_longer(!{{ factor }}) |> 
    dplyr::mutate(name = base::factor(name, levels = c(laufend_name, minmax)))
}