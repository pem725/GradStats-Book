# ---------------------------------------------------------------------------
# make_data_zip.R - build the one-click data download.
#
# Readers working in SPSS, Julia or Python need the book's data before any of
# their code tabs will run. Sending them to GitHub is a bad answer: co-author
# Jeff teaches SPSS and does not use git, and neither do most of the students
# this book is for. So the book publishes its own data bundle, and the page
# hands out one ordinary URL:
#
#     https://pem725.github.io/GradStats-Book/gradstats-data.zip
#
# Run as a POST-render hook (see _quarto.yml), because Quarto empties the
# output directory when a render starts - anything written before that is
# thrown away.
#
# The zip is BUILT, never committed. That is deliberate: a checked-in zip
# drifts from data/ the first time a dataset is regenerated, and a stale
# dataset that still loads is exactly the kind of quiet wrongness this book
# keeps getting bitten by.
# ---------------------------------------------------------------------------

out_dir <- Sys.getenv("QUARTO_PROJECT_OUTPUT_DIR", "_book")
stage   <- file.path(tempdir(), "gradstats-zip")
bundle  <- "GradStats-data"           # the folder name the reader ends up with

# `zip` is a system utility, not part of R. If it is missing we say so and let
# the render finish: a book without the download link is still a book, but a
# build that dies here for want of a packaging tool helps nobody.
if (!nzchar(Sys.which("zip"))) {
  message("  BOOK-NOZIP: `zip` not on PATH - skipping gradstats-data.zip. ",
          "The setup page's download link will 404 until this is installed.")
  quit(save = "no", status = 0)
}

if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# Absolute, and resolved only AFTER the directory exists: normalizePath() does
# not expand a path that is not there yet, so doing this earlier left it
# relative - which then resolved against the staging directory once we setwd()
# into it, and zip failed with "Could not create output file".
zip_path <- file.path(normalizePath(out_dir), "gradstats-data.zip")

unlink(stage, recursive = TRUE)
dir.create(file.path(stage, bundle), recursive = TRUE)

# The data, and the four loaders that read it. Everything else in the repo -
# chapters, bibliographies, the rendered book - is noise to someone who just
# wants to run the code tabs.
invisible(file.copy("data", file.path(stage, bundle), recursive = TRUE))
invisible(file.copy(list.files("setup", pattern = "^load_data[.]",
                               full.names = TRUE),
                    file.path(stage, bundle)))

writeLines(c(
  "The Book's Data - Statistics by Us for You",
  "==========================================",
  "",
  "Everything the SPSS, Julia and Python code tabs need. You do not need",
  "git, GitHub, or an account anywhere to use this.",
  "",
  "STEP 1. Unzip this file somewhere you will find again - the Desktop is",
  "        fine. You get a folder called GradStats-data, holding a folder",
  "        called data and one loader per language.",
  "",
  "STEP 2 (SPSS). Open load_data.sps in SPSS, or in PSPP if you have no",
  "        SPSS licence. Near the top is a line reading:",
  "",
  "            * CD 'C:/path/to/GradStats-data'.",
  "",
  "        Delete the asterisk and the space after it, and put the real",
  "        location of the unzipped folder between the quotes:",
  "",
  "            CD 'C:/Users/jeff/Desktop/GradStats-data'.",
  "",
  "        Use forward slashes, even on Windows. Point at the folder that",
  "        CONTAINS data, not at data itself. Then Run All. The output",
  "        prints the folder back to you, so you can see it took.",
  "",
  "        After that, any chapter's data is one line:",
  "",
  "            !bookdata name = \"ch09-ctt\".",
  "",
  "        The chapter tells you which name to use, in a note near its top.",
  "",
  "STEP 2 (Julia).  include(\"load_data.jl\"); d = book_data(\"ch09-ctt\")",
  "STEP 2 (Python). from load_data import book_data; d = book_data(\"ch09-ctt\")",
  "",
  "A NOTE ON CATEGORY ORDER. A .csv cannot record the order of a categorical",
  "variable, so every language sorts them alphabetically - which would put",
  "the fertilizer doses in the ANOVA chapter as high, low, none instead of",
  "none, low, high, and attach the right numbers to the wrong labels. The",
  "loaders fix this. In SPSS run the matching macro after loading, for",
  "example !doseorder. after ch17-dose, or !petorder. after ch16-pets.",
  "",
  "WHY THE DATA IS SHIPPED RATHER THAN SIMULATED. Random number generators",
  "are not portable: the same seed gives different draws in R, Julia and",
  "Python. If you regenerated these datasets in your own language, every",
  "number you computed would sit a little off the ones printed in the book,",
  "and you would reasonably assume you had made a mistake. So the data was",
  "generated once, in R, and all four languages read the same files.",
  "",
  paste("Built from the book source on", format(Sys.Date(), "%Y-%m-%d"), "-",
        "https://pem725.github.io/GradStats-Book/")
), file.path(stage, bundle, "README.txt"))

owd <- setwd(stage)
on.exit(setwd(owd), add = TRUE)
if (file.exists(zip_path)) unlink(zip_path)
# Name the zip binary explicitly. utils::zip() defaults to R_ZIPCMD, and on
# this machine that variable exists but is EMPTY, which fails the argument
# check rather than falling back to "zip" on the PATH.
status <- utils::zip(zip_path, bundle, flags = "-qr9X",
                     zip = unname(Sys.which("zip")))
setwd(owd)

if (status != 0 || !file.exists(zip_path)) {
  message("  BOOK-NOZIP: packaging failed (status ", status, ").")
} else {
  message("  Built ", zip_path, " (",
          round(file.size(zip_path) / 1024), " KB, ",
          length(list.files(file.path(stage, bundle), recursive = TRUE)),
          " files)")
}
