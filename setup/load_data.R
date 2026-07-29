# ---------------------------------------------------------------------------
# load_data.R - the book's datasets, in R.
#
#     source("setup/load_data.R")
#     d <- book_data("ch06-study")
#
# The chapters themselves generate their data inline, so you rarely need this
# file while reading. It exists so the R workflow matches the SPSS, Julia, and
# Python ones, and so you can grab any chapter's data without re-running its
# simulation. setup/make_data.R is what produced these files in the first
# place; open it to see every recipe in full.
# ---------------------------------------------------------------------------

library(tidyverse)

DATA_DIR <- "data/sim"

# Categorical order matters and CSV does not preserve it: without this, "cat,
# fish, pig, dog" comes back alphabetically and every coefficient shifts.
LEVELS <- list(
  `ch03-spread`     = list(group = c("tight (sd=3)", "wide (sd=20)")),
  `ch12-groups`     = list(group = c("control", "treatment")),
  `ch16-pets`       = list(pet = c("cat", "fish", "pig", "dog"),
                           mess = c("messy", "tidy")),
  `ch17-dose`       = list(dose = c("none", "low", "high")),
  `ch18-pets`       = list(pet = c("cat", "fish", "pig", "dog")),
  `ch18-unbalanced` = list(petw = c("cat", "fish", "pig", "dog")),
  `ch21-invariance` = list(grp = c("A", "B")),
  `appendix-d`      = list(group = c("A", "B"))
)

# Load one of the book's datasets by name, with factor levels in book order.
book_data <- function(name) {
  d <- readr::read_csv(file.path(DATA_DIR, paste0(name, ".csv")),
                       show_col_types = FALSE)
  for (col in names(LEVELS[[name]] %||% list())) {
    d[[col]] <- factor(d[[col]], levels = LEVELS[[name]][[col]])
  }
  d
}

# Every dataset the book ships.
datasets <- function() {
  tools::file_path_sans_ext(list.files(DATA_DIR, pattern = "[.]csv$"))
}
