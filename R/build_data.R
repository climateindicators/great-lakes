# Build tidy long-format data for the Great Lakes Water Levels and Temperatures indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# Generated as a stub by the build-indicator skill. Each figure below has a
# `todo_reshape()` call standing where its reshape belongs. Replace that line,
# then delete the todo_reshape() helper once no call to it remains.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Pivot the columns named in `lookup` to long format. `lookup` has one row per
# source header, in output order, plus the dimension columns that header encodes.
# Rows come out in source order (by key), then lookup order; blank cells are dropped.
pivot_by_lookup <- function(df, key_col, key_name, lookup) {
  df |>
    dplyr::mutate(.row = dplyr::row_number()) |>
    dplyr::select(.row, dplyr::all_of(c(key_col, lookup$header))) |>
    tidyr::pivot_longer(dplyr::all_of(lookup$header), names_to = "header", values_to = "value") |>
    dplyr::filter(value != "") |>
    dplyr::arrange(.row, match(header, lookup$header)) |>
    dplyr::left_join(lookup, by = "header") |>
    dplyr::rename(!!key_name := dplyr::all_of(key_col)) |>
    dplyr::select(-.row, -header) |>
    dplyr::relocate(value, .after = dplyr::last_col())
}

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Great Lakes Water Levels and Temperatures",
  slug                    = "great-lakes",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/great-lakes/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-06/great-lakes_documentation.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 1: Water Levels of the Great Lakes, 1860-2023 ----

f1_path <- file.path(raw_dir, "great-lakes_fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)

# The year column has a blank header in EPA's file; it is the only id column.
f1_lookup <- tidyr::expand_grid(
  lake   = c("Lake Erie", "Lake Michigan-Huron", "Lake Ontario", "Lake Superior"),
  series = c("level", "upper_bound", "lower_bound")
) |>
  dplyr::mutate(header = paste0(lake, c(level = "", upper_bound = " upper bound", lower_bound = " lower bound")[series])) |>
  dplyr::select(header, lake, series)

assert_headers(
  f1_raw,
  id_cols          = "",
  expected_headers = f1_lookup$header,
  what             = "great-lakes_fig-1.csv"
)

names(f1_raw)[names(f1_raw) == ""] <- "year"
f1 <- pivot_by_lookup(f1_raw, "year", "year", f1_lookup) |>
  dplyr::select(year, lake, series, value)
assert_conservation(f1_raw, f1_lookup$header, nrow(f1), "great-lakes_fig-1.csv")

write_csv_stable(f1, file.path(out_dir, "great_lakes_water_levels.csv"))

# ---- Figure 2: Surface Water Temperatures of the Great Lakes, 1995-2023 ----

f2_path <- file.path(raw_dir, "great-lakes_fig-2.csv")
f2_meta <- read_epa_preamble(f2_path)
f2_raw  <- read_epa_csv(f2_path)

# This one source file holds two unrelated datasets side by side, each with its
# own key column: annual averages (Year, 29 populated rows) and a daily
# climatology (Julian Day, 366 rows). They become two output files.
F2_LAKES <- c("Lake Erie", "Lake Huron", "Lake Michigan", "Lake Ontario", "Lake Superior")

f2_annual_lookup <- tibble::tibble(
  header = paste(F2_LAKES, "annual average"),
  lake   = F2_LAKES
)
f2_daily_lookup <- tidyr::expand_grid(
  lake   = F2_LAKES,
  period = c("2014-2023", "1995-2004")
) |>
  dplyr::mutate(header = paste0(lake, ", ", period)) |>
  dplyr::select(header, lake, period)

assert_headers(
  f2_raw,
  id_cols          = c("Year", "Julian Day"),
  expected_headers = c(f2_annual_lookup$header, f2_daily_lookup$header),
  what             = "great-lakes_fig-2.csv"
)

f2_annual <- pivot_by_lookup(f2_raw, "Year", "year", f2_annual_lookup)
assert_conservation(f2_raw, f2_annual_lookup$header, nrow(f2_annual), "great-lakes_fig-2.csv (annual)")

f2_daily <- pivot_by_lookup(f2_raw, "Julian Day", "julian_day", f2_daily_lookup)
assert_conservation(f2_raw, f2_daily_lookup$header, nrow(f2_daily), "great-lakes_fig-2.csv (daily)")

write_csv_stable(f2_annual, file.path(out_dir, "great_lakes_temp_annual.csv"))
write_csv_stable(f2_daily,  file.path(out_dir, "great_lakes_temp_daily.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

# Columns are documented by hand; the column list is checked against the data
# frame so the dictionary cannot drift from the file.
describe <- function(df, cols) {
  stopifnot(identical(vapply(cols, function(x) x$name, character(1)), names(df)))
  cols
}

LAKE_DESC <- "Lake name as EPA labels it in this figure."

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "great_lakes_water_levels.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "great-lakes_fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "UTF-8",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = f1_meta$units,
      rows            = nrow(f1),
      columns         = describe(f1, list(
        col("year", "integer", "Calendar year."),
        col("lake", "string", LAKE_DESC),
        col("series", "string", "level (annual mean water level), upper_bound or lower_bound (the bounds EPA plots around it)."),
        col("value", "number", "Water level in feet relative to the lake's long-term average, as published.")
      ))
    ),
    list(
      file            = "great_lakes_temp_annual.csv",
      figure          = "Figure 2",
      figure_title    = f2_meta$title,
      source_file     = "great-lakes_fig-2.csv",
      source_sha256   = file_sha256(f2_path),
      source_encoding = "windows-1252",
      data_source     = f2_meta$data_source,
      web_update      = f2_meta$web_update,
      unit            = f2_meta$units,
      rows            = nrow(f2_annual),
      columns         = describe(f2_annual, list(
        col("year", "integer", "Calendar year."),
        col("lake", "string", LAKE_DESC),
        col("value", "number", "Annual average surface water temperature in degrees Fahrenheit.")
      ))
    ),
    list(
      file            = "great_lakes_temp_daily.csv",
      figure          = "Figure 2",
      figure_title    = f2_meta$title,
      source_file     = "great-lakes_fig-2.csv",
      source_sha256   = file_sha256(f2_path),
      source_encoding = "windows-1252",
      data_source     = f2_meta$data_source,
      web_update      = f2_meta$web_update,
      unit            = f2_meta$units,
      rows            = nrow(f2_daily),
      columns         = describe(f2_daily, list(
        col("julian_day", "integer", "Day of the year, 1 to 366."),
        col("lake", "string", LAKE_DESC),
        col("period", "string", "Averaging period: 2014-2023 or 1995-2004."),
        col("value", "number", "Average surface water temperature on that day over the period, in degrees Fahrenheit.")
      ))
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
