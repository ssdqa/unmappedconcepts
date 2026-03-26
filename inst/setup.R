# Generate a test DB with synthetic omop data
testdb <- NULL
my_directory <- system.file(package = 'unmappedconcepts')
my_file_folder <- system.file('extdata', package = 'unmappedconcepts')
# Function to generate omop test db
mk_testdb_omop <- function(){
  if (! is.null(testdb)) return(testdb)

  # Create an ephemeral in-memory RSQLite database
  testdb <<- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  # Read all csv files in testdata folder
  col_type_mapping <- list(
    'condition_occurrence' = 'iiiDTDTiiciiicic',
    'person' = 'iiiiiTiiiiiccicici',
    'visit_occurrence' = 'iiiDTDTiiiciicici')
  for (file_name in list.files(path=system.file('extdata',
                                                package = 'unmappedconcepts'),
                               pattern = "\\.csv$")) {
    # Get table_name from csv file_name without extension
    table_name <- sub('\\.csv$', '', file_name)
    tbl <- readr::read_csv(
      file = file.path(system.file('extdata', package = 'unmappedconcepts'),
                       file_name),
      col_types = col_type_mapping[[table_name]],
      show_col_types = FALSE
    )
    if(table_name == 'condition_occurrence'){
      tbl <- tbl %>%
        dplyr::mutate(provider_id = ifelse(provider_id == 22, 9999, provider_id))
    }
    # Write to db
    DBI::dbWriteTable(testdb, table_name, tbl)
  }
  testdb
}
