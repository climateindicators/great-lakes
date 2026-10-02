# Provenance

Every file in this directory is reproduced unmodified from EPA's published
indicator page and its per-figure data downloads. To update the data, replace the
file and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/great-lakes/index.html>  \
  sha256 `ad68b64bdfa26c88ed3324feb1132369f71c6c7122fc0b45ecd6f457fb8b6fa4`

Technical documentation: <https://19january2025snapshot.epa.gov/system/files/documents/2024-06/great-lakes_documentation.pdf>

## Figure data

- `great-lakes_fig-1.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/great-lakes_fig-1.csv>  \
  sha256 `e4415f28b21056fdc0ef5da025c7abccfbbe546b9ed5c7bf20b31da6d5f37c86`  \
  encoding UTF-8, 164 data rows, columns: ``, `Lake Erie`, `Lake Michigan-Huron`, `Lake Ontario`, `Lake Superior`, `Lake Erie upper bound`, `Lake Michigan-Huron upper bound`, `Lake Ontario upper bound`, `Lake Superior upper bound`, `Lake Erie lower bound`, `Lake Michigan-Huron lower bound`, `Lake Ontario lower bound`, `Lake Superior lower bound`  \
  title: Figure 1. Water Levels of the Great Lakes, 1860-2023  \
  data source: NOAA, 2024; web update: June 2024; units: feet

- `great-lakes_fig-2.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/great-lakes_fig-2.csv>  \
  sha256 `6c17ef5803c3369f997d6a2ae6df7c790b5d3bbe5da0febaaefd329708d2a960`  \
  encoding windows-1252, 366 data rows, columns: `Year`, `Lake Erie annual average`, `Lake Huron annual average`, `Lake Michigan annual average`, `Lake Ontario annual average`, `Lake Superior annual average`, `Julian Day`, `Lake Erie, 2014-2023`, `Lake Huron, 2014-2023`, `Lake Michigan, 2014-2023`, `Lake Ontario, 2014-2023`, `Lake Superior, 2014-2023`, `Lake Erie, 1995-2004`, `Lake Huron, 1995-2004`, `Lake Michigan, 1995-2004`, `Lake Ontario, 1995-2004`, `Lake Superior, 1995-2004`  \
  title: Figure 2. Surface Water Temperatures of the Great Lakes, 1995-2023  \
  data source: NOAA, 2024; web update: June 2024; units: °F
