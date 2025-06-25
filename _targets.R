library(targets)
library(tarchetypes)
library(cleaningtools)

tar_option_set(
  packages = c("tibble"),
  format = "qs",
  error = "continue"
)


tar_source()

save_clean_data <- function(clean_data) {
  output_file <- "outputs/clean_data.parquet"
  arrow::write_parquet(clean_data, output_file)
  output_file
}

save_agent <- function(agent) {
  output_file <- "outputs/agent.html"
  pointblank::export_report(agent, output_file, quiet = TRUE)
  return(output_file)
}

list(
  tar_target(raw_data, cleaningtools::cleaningtools_raw_data),
  tar_target(cleaning_log, cleaningtools::cleaningtools_cleaning_log),
  tar_target(
    review,
    cleaningtools::review_cleaning_log(
      raw_dataset = raw_data,
      raw_data_uuid_column = "X_uuid",
      cleaning_log = cleaning_log,
      cleaning_log_uuid_column = "X_uuid",
      cleaning_log_question_column = "questions",
      cleaning_log_new_value_column = "new_value",
      cleaning_log_change_type_column = "change_type"
    )
  ),
  tar_target(
    clean_data,
    cleaningtools::create_clean_data(
      raw_dataset = raw_data,
      raw_data_uuid_column = "X_uuid",
      cleaning_log = cleaning_log,
      cleaning_log_uuid_column = "X_uuid",
      cleaning_log_question_column = "questions",
      cleaning_log_new_value_column = "new_value",
      cleaning_log_change_type_column = "change_type"
    ) |>
      dplyr::rename("_uuid" = "X_uuid")
  ),
  tar_target(
    validation_agent,
    validate(
      dplyr::rename(raw_data, "_uuid" = "X_uuid"),
      use_agent = TRUE
    )
  ),
  tar_target(validation_output, save_agent(validation_agent), format = "file"),
  tar_target(
    validation_agent_clean,
    validate(clean_data, use_agent = FALSE)
  ),
  tar_target(
    output_clean_data,
    save_clean_data(clean_data),
    format = "file"
  )
)
