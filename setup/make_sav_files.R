# ---------------------------------------------------------------------------
# make_sav_files.R - every dataset as a native SPSS .sav file.
#
# WHY. The CSV-plus-loader-plus-macro arrangement asks an SPSS user to reason
# about relative paths at two nested levels: !bookdata inserts a loader out of
# data/sim/, and that loader reads its .csv with a relative path of its own.
# Get either wrong and SPSS says only "cannot access a file with the given file
# specification". Co-author Jeff lost the better part of a session to it, and he
# was following the instructions.
#
# A .sav collapses both hops into one line with one absolute path:
#
#     GET FILE='C:/Users/jeff/Dropbox/Stats Book/data/ch09-ctt.sav'.
#
# No CD, no macro, no INSERT, nothing relative. It is also what Jeff asked for
# unprompted - "my favourite is SPSS, because that save file has so much
# information; CSV files have nothing" - and he is right: a .sav carries
# variable labels, value labels and declared types, so the category order the
# book keeps warning about travels INSIDE the file instead of needing a macro
# run afterwards.
#
# Built by PSPP, never committed. Run as a post-render hook so the .sav files
# cannot drift from the .csv files they come from.
#
# ONE THING WE CANNOT TEST HERE: whether real SPSS opens a PSPP-written system
# file. PSPP writes the documented format and SPSS is supposed to read it, but
# this machine has no SPSS. Until Jeff confirms, treat it as unverified.
# ---------------------------------------------------------------------------

out_root <- Sys.getenv("BOOK_SAV_DIR", file.path(tempdir(), "book-sav"))

if (!nzchar(Sys.which("pspp"))) {
  message("  BOOK-NOSAV: pspp not on PATH - skipping .sav generation.")
  quit(save = "no", status = 0)
}

loaders <- c(list.files("data/sim", pattern = "[.]sps$", full.names = TRUE),
             list.files("data",     pattern = "[.]sps$", full.names = TRUE))
loaders <- loaders[!duplicated(basename(loaders))]

# Category order, baked into the file rather than left to a macro the reader
# has to remember. These are the datasets whose groups do NOT sort the way the
# book needs: alphabetical order silently reattaches the right numbers to the
# wrong labels.
recodes <- list(
  "ch16-pets" = c("AUTORECODE VARIABLES = pet /INTO pet_ord.",
                  "RECODE pet_ord (1=1)(3=2)(4=3)(2=4) INTO pet_ord.",
                  "VALUE LABELS pet_ord 1 'cat' 2 'fish' 3 'pig' 4 'dog'.",
                  "VARIABLE LABELS pet_ord 'Pet, in the book''s order: cat < fish < pig < dog'."),
  "ch18-pets" = c("AUTORECODE VARIABLES = pet /INTO pet_ord.",
                  "RECODE pet_ord (1=1)(3=2)(4=3)(2=4) INTO pet_ord.",
                  "VALUE LABELS pet_ord 1 'cat' 2 'fish' 3 'pig' 4 'dog'.",
                  "VARIABLE LABELS pet_ord 'Pet, in the book''s order: cat < fish < pig < dog'."),
  "ch17-dose" = c("AUTORECODE VARIABLES = dose /INTO dose_ord.",
                  "RECODE dose_ord (3=1)(2=2)(1=3) INTO dose_ord.",
                  "VALUE LABELS dose_ord 1 'none' 2 'low' 3 'high'.",
                  "VARIABLE LABELS dose_ord 'Dose, in the book''s order: none < low < high'.")
)

dir.create(out_root, recursive = TRUE, showWarnings = FALSE)
ok <- fail <- character()

for (ldr in loaders) {
  stem <- sub("[.]sps$", "", basename(ldr))
  sav  <- file.path(normalizePath(out_root), paste0(stem, ".sav"))
  syn  <- tempfile(fileext = ".sps")

  writeLines(c(
    paste0("INSERT FILE='", ldr, "'."),
    recodes[[stem]],
    paste0("SAVE OUTFILE='", sav, "'.")
  ), syn)

  # PSPP must run with the repo as its working directory: the loaders read
  # their .csv by a relative path, which is the very problem this script exists
  # to remove for everyone downstream.
  r <- suppressWarnings(
    system2("pspp", shQuote(syn), stdout = TRUE, stderr = TRUE))
  bad <- any(grepl("error:", r, ignore.case = TRUE))

  if (!bad && file.exists(sav)) ok <- c(ok, stem)
  else fail <- c(fail, paste0(stem, ": ", paste(utils::head(r[grepl("error", r, TRUE)], 1), collapse = "")))
  unlink(syn)
}

message("  .sav written: ", length(ok), " ok, ", length(fail), " failed  -> ", out_root)
for (f in fail) message("     FAILED ", f)
