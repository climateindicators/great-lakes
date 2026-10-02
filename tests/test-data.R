# Regression checks on the generated data for the Great Lakes Water Levels and Temperatures indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are the
# TODO at the bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 3 dataset(s)", length(meta$datasets) == 3L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")
# Compared as strings, so source precision is pinned along with the value.
snapshot <- function(file, n, first, last, vmin, vmax) {
  d <- rd(file)
  check(sprintf("%s: %d rows", file, n), nrow(d) == n)
  check(sprintf("%s: first row is %s", file, paste(first, collapse = "/")),
        identical(unname(unlist(d[1L, ])), first))
  check(sprintf("%s: last row is %s", file, paste(last, collapse = "/")),
        identical(unname(unlist(d[nrow(d), ])), last))
  v <- as.numeric(d$value)
  check(sprintf("%s: minimum value is %s", file, vmin), identical(d$value[which.min(v)], vmin))
  check(sprintf("%s: maximum value is %s", file, vmax), identical(d$value[which.max(v)], vmax))
  d
}

lv <- snapshot("great_lakes_water_levels.csv", 1968L,
               c("1860", "Lake Erie", "level", "1.225938056"),
               c("2023", "Lake Superior", "lower_bound", "0.044838056"),
               "-3.728120278", "3.720465")
check("water_levels: 164 years by 4 lakes by 3 series",
      length(unique(lv$year)) == 164L && length(unique(lv$lake)) == 4L &&
        identical(sort(unique(lv$series)), c("level", "lower_bound", "upper_bound")))

ta <- snapshot("great_lakes_temp_annual.csv", 145L,
               c("1995", "Lake Erie", "51.7070411"),
               c("2023", "Lake Superior", "44.54856438"),
               "39.90421311", "54.90996721")
check("temp_annual: 29 years by 5 lakes", length(unique(ta$year)) == 29L && length(unique(ta$lake)) == 5L)

td <- snapshot("great_lakes_temp_daily.csv", 3660L,
               c("1", "Lake Erie", "2014-2023", "38.0588"),
               c("366", "Lake Superior", "1995-2004", "35.048"),
               "32.621", "75.4592")
check("temp_daily: 366 days by 5 lakes by 2 periods",
      length(unique(td$julian_day)) == 366L && length(unique(td$lake)) == 5L &&
        identical(sort(unique(td$period)), c("1995-2004", "2014-2023")))

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
