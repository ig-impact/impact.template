validate <- function(.tbl, use_agent = TRUE) {
  if (use_agent) {
    .tbl <- pointblank::create_agent(tbl = .tbl)
  }
  .tbl <- KQC::rows_dissimilar(
    .tbl,
    tool = cleaningtools::cleaningtools_survey,
    threshold = 12
  )

  if (use_agent) {
    .tbl |> pointblank::interrogate()
  }
}
