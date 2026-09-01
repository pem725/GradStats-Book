# ---------------------------------------------------------------------------
# make_spss_kit.R - every SPSS block in the book, as runnable .sps files.
#
# The book's SPSS lives inside .qmd chapters as {pspp} chunks, which is right
# for building the book and useless for someone who wants to sit in front of
# SPSS and work. This pulls each chapter's blocks out into one .sps per
# chapter, bundles them with the data, and zips the lot.
#
# Everything in the book has been verified against PSPP, which is a SUBSET of
# SPSS. So this kit exists to answer a question we cannot answer ourselves:
# what does real SPSS do with it? That includes the blocks marked
# `eval: false`, which PSPP cannot run at all and which therefore no one has
# ever executed.
#
# Run as a POST-render hook alongside make_data_zip.R. Built, never committed.
# ---------------------------------------------------------------------------

out_dir <- Sys.getenv("QUARTO_PROJECT_OUTPUT_DIR", "_book")
stage   <- file.path(tempdir(), "gradstats-spss-kit")
bundle  <- "GradStats-SPSS"

if (!nzchar(Sys.which("zip"))) {
  message("  BOOK-NOZIP: `zip` not on PATH - skipping gradstats-spss.zip.")
  quit(save = "no", status = 0)
}

# Chapters in BOOK order, not filename order - _quarto.yml is the authority.
yml   <- readLines("_quarto.yml", warn = FALSE)
files <- sub("^\\s*-\\s*", "", grep("^\\s+-\\s+[0-9A-Za-z_-]+\\.qmd\\s*$", yml, value = TRUE))
files <- trimws(files)
files <- files[file.exists(files)]

if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
zip_path <- file.path(normalizePath(out_dir), "gradstats-spss.zip")
unlink(stage, recursive = TRUE)
dir.create(file.path(stage, bundle, "spss"), recursive = TRUE)
dir.create(file.path(stage, bundle, "output"), recursive = TRUE)

# --- pull the {pspp} blocks out of one chapter ------------------------------
extract <- function(path) {
  txt <- readLines(path, warn = FALSE)
  open <- grep("^```\\{pspp", txt)
  if (!length(open)) return(NULL)
  fence <- grep("^```\\s*$", txt)

  # Depth of ::: divs at each line, so headings inside a callout can be told
  # apart from real section headings. Panel-tabsets nest, hence a running sum.
  delta <- ifelse(grepl("^:::+\\s*\\{", txt), 1L,
                  ifelse(grepl("^:::+\\s*$", txt), -1L, 0L))
  in_div <- cumsum(delta) > 0L

  lapply(open, function(o) {
    close <- fence[fence > o][1]
    body  <- txt[(o + 1):(close - 1)]
    # Chunk options (#| eval: false and friends) are knitr's, not SPSS's.
    opts  <- grepl("^#\\|", body)
    shown_only <- any(grepl("eval:\\s*false", body[opts]))
    body  <- body[!opts]
    # Nearest heading above, for a human-readable label. Skip the tab headers
    # themselves (### R / ### SPSS / ### Julia / ### Python) - the nearest
    # heading to any SPSS chunk is always "SPSS", which labels nothing.
    heads <- grep("^#{2,4} ", txt[seq_len(o)])
    heads <- heads[!grepl("^#+\\s*(R|SPSS|Julia|Python)\\s*$", txt[heads])]
    # Callouts carry their own ## title ("Working in SPSS, Julia, or Python?"),
    # which is the nearest heading to a great many chunks and describes none of
    # them. Anything inside a ::: div is a callout title, not a section.
    heads <- heads[!in_div[heads]]
    head  <- if (length(heads)) sub("^#+ \\s*", "", txt[tail(heads, 1)]) else ""
    head  <- trimws(gsub("\\{.*\\}|\\*\\*|\\$", "", head))
    # A block of nothing but comments has no code to run - the book uses these
    # to say plainly that base SPSS cannot do the thing.
    code  <- body[nzchar(trimws(body)) & !grepl("^\\s*\\*", body)]
    list(line = o, head = head, body = body,
         shown_only = shown_only, prose_only = length(code) == 0)
  })
}

title_of <- function(path) {
  h <- grep("^# ", readLines(path, warn = FALSE), value = TRUE)
  if (length(h)) trimws(gsub("\\{.*\\}", "", sub("^# ", "", h[1]))) else path
}

made <- character()
n_blocks <- n_shown <- n_prose <- 0L

for (f in files) {
  blocks <- extract(f)
  if (is.null(blocks)) next
  title <- title_of(f)
  stem  <- sub("\\.qmd$", "", f)
  outf  <- file.path(stage, bundle, "spss", paste0(stem, ".sps"))

  L <- c(
    "* ==========================================================================.",
    paste0("* ", title),
    paste0("* Extracted from ", f, " by setup/make_spss_kit.R. Do not hand-edit -"),
    "* fix the chapter and rebuild, or the book and this kit drift apart.",
    "*",
    paste0("* ", length(blocks), " block(s). Run the file top to bottom, or one block at a time."),
    "*",
    "* RUN 00-START-HERE.sps FIRST, once per SPSS session. It defines !bookroot,",
    "* which the next line uses to point SPSS at the folder holding data/.",
    "* ==========================================================================.",
    "",
    "* Re-anchors the working directory. Harmless to run twice, and it means this",
    "* file works no matter what folder SPSS thinks it is in when you open it.",
    "CD !bookroot.",
    ""
  )

  for (i in seq_along(blocks)) {
    b <- blocks[[i]]
    n_blocks <- n_blocks + 1L
    tag <- if (b$prose_only) "  [NO CODE - base SPSS cannot do this; the block says what can]"
           else if (b$shown_only) "  [NEVER EXECUTED - PSPP cannot run it; real SPSS may]"
           else ""
    if (b$prose_only) n_prose <- n_prose + 1L
    if (b$shown_only) n_shown <- n_shown + 1L
    L <- c(L,
      "* --------------------------------------------------------------------------.",
      paste0("* BLOCK ", i, " of ", length(blocks),
             if (nzchar(b$head)) paste0("  |  ", b$head) else ""),
      paste0("* source: ", f, " line ", b$line, tag),
      "* --------------------------------------------------------------------------.",
      b$body, "")
  }
  writeLines(L, outf)
  made <- c(made, basename(outf))
}

# --- the one file the reader edits ------------------------------------------
writeLines(c(
  "* ==========================================================================.",
  "* START HERE. Run this once, at the beginning of every SPSS session.",
  "*",
  "* ONE LINE TO EDIT. Put the location of THIS FOLDER between the quotes.",
  "* Forward slashes, even on Windows:",
  "*",
  "*     Mac      '/Users/yourname/Desktop/GradStats-SPSS'",
  "*     Windows  'C:/Users/yourname/Dropbox/GradStats-SPSS'",
  "*",
  "* Point at the folder that CONTAINS data and spss. Do NOT put /data or",
  "* /spss on the end. That is the commonest way to get this wrong, and the",
  "* error it causes does not say so.",
  "*",
  "* Your own syntax files can live anywhere. Every chapter file re-anchors",
  "* itself with CD !bookroot, so it does not matter what folder SPSS thinks",
  "* it is in.",
  "* ==========================================================================.",
  "",
  "DEFINE !bookroot () 'C:/path/to/GradStats-SPSS' !ENDDEFINE.",
  "",
  "CD !bookroot.",
  "SHOW DIRECTORY.",
  "",
  "* CHECK IT. Run this line:   !bookcheck.",
  "* A mean height of about 67.99 means everything is wired up. Anything else",
  "* means !bookroot above is wrong.",
  "DEFINE !bookcheck ()",
  "CD !bookroot.",
  "SHOW DIRECTORY.",
  "INSERT FILE = 'data/sim/ch01-heights.sps'.",
  "DESCRIPTIVES VARIABLES=height /STATISTICS=MEAN.",
  "!ENDDEFINE.",
  "",
  "* OPTIONAL, and UNTESTED BY US - PSPP has no OMS, so we could not try it.",
  "* Uncomment to have SPSS write everything to a plain text file you can send",
  "* on, instead of reading it off the screen. Put OMSEND. at the end of the run.",
  "*",
  "* OMS /SELECT ALL /DESTINATION FORMAT=TEXT OUTFILE='output/session.txt'.",
  "*",
  "* Failing that, File > Export in the output window does the same job by hand."
), file.path(stage, bundle, "spss", "00-START-HERE.sps"))

invisible(file.copy("data", file.path(stage, bundle), recursive = TRUE))
invisible(file.copy(list.files("setup", pattern = "^load_data[.]", full.names = TRUE),
                    file.path(stage, bundle)))

writeLines(c(
  "The Book's SPSS, Ready to Run - Statistics by Us for You",
  "========================================================",
  "",
  "Every SPSS block in the book, pulled out of the chapters into one syntax",
  "file per chapter, with the data they need. Nothing here requires git or a",
  "GitHub account.",
  "",
  "WHAT IS IN HERE",
  "  spss/00-START-HERE.sps   run this first, once per session",
  "  spss/<chapter>.sps       one file per chapter, in book order",
  "  data/                    every dataset the blocks read",
  "  output/                  empty, for you to export output into",
  "  load_data.*              the R, SPSS, Julia and Python loaders",
  "",
  "GETTING GOING",
  "  1. Unzip somewhere you can find again. The Desktop is fine.",
  "  2. Open spss/00-START-HERE.sps in SPSS. Put your own path in the CD line,",
  "     uncomment it, and run the file. It prints the folder back to you.",
  "  3. Open any chapter file and run it, whole or a block at a time.",
  "",
  "WHY WE ARE ASKING",
  "  Every SPSS block in the book has been checked against PSPP, which is free",
  "  and which runs a SUBSET of SPSS. Real SPSS is the thing we cannot test.",
  "  Where the two differ, the book was written to the smaller one - it uses",
  "  PAF where SPSS would offer ML, and spells contrast codes out with COMPUTE",
  "  because PSPP has no UNIANOVA /CONTRAST. Those choices are noted in the",
  "  blocks. If real SPSS does something better, we want to know.",
  "",
  "HOW BLOCKS ARE LABELLED",
  "  Each block carries the chapter file and line it came from, so a problem",
  "  can be traced straight back to the source:",
  "",
  "      * BLOCK 3 of 6  |  Cronbach's Alpha, By Hand",
  "      * source: 10-reliability.qmd line 120",
  "",
  "  Two labels are worth knowing:",
  "",
  "  [NEVER EXECUTED]  PSPP cannot run it, so the book prints it without ever",
  "                    running it. No one has seen this work. If it runs for",
  "                    you, that is new information.",
  "",
  "  [NO CODE]         All comment, nothing to execute. The book uses these to",
  "                    say plainly that base SPSS cannot do something and to",
  "                    name the tool that can. Empty output is correct here.",
  "",
  "RUN THESE FIRST - THE BLOCKS NOBODY HAS EVER SEEN WORK",
  "  PSPP answers 'not yet implemented' to these, so every one is a command",
  "  the book prints and cannot demonstrate. Real SPSS should run all of them.",
  "  Measured against PSPP 2.0:",
  "",
  "      15-MRC.sps            UNIANOVA    Type I and Type III sums of squares",
  "      30-irt.sps            VARCOMP     variance components for G-theory",
  "      20-beyond.sps         CREATE      lagged/generated series",
  "      21-graphics.sps       GGRAPH      the modern SPSS chart engine",
  "      21-graphics.sps       VARSTOCASES reshaping wide to long",
  "      02-distributions.sps  GRAPH /LINE overlaying a curve on a histogram",
  "      20-beyond.sps         GRAPH /LINE the same",
  "      21-graphics.sps       GRAPH /LINE the same",
  "      intro.sps             GRAPH /XYZ  the 3-D scatterplot",
  "",
  "  UNIANOVA and VARCOMP are the two that matter most. They are ordinary SPSS",
  "  and they carry real teaching weight - Type I versus Type III sums of",
  "  squares is the whole point of that section of the regression chapter.",
  "  If they run for you, please send the output.",
  "",
  "A TRAP WORTH KNOWING",
  "  A continuation line that BEGINS with an asterisk is read as a comment and",
  "  silently dropped, because an asterisk in the command position starts one.",
  "  Break long expressions so each operator ENDS its line instead. This cost",
  "  the book a wrong number once already.",
  "",
  paste("Built from the book source on", format(Sys.Date(), "%Y-%m-%d"), "-",
        "https://pem725.github.io/GradStats-Book/")
), file.path(stage, bundle, "README.txt"))

owd <- setwd(stage); on.exit(setwd(owd), add = TRUE)
if (file.exists(zip_path)) unlink(zip_path)
status <- utils::zip(zip_path, bundle, flags = "-qr9X", zip = unname(Sys.which("zip")))
setwd(owd)

if (status != 0 || !file.exists(zip_path)) {
  message("  BOOK-NOZIP: SPSS kit packaging failed (status ", status, ").")
} else {
  message("  Built ", zip_path, " (", round(file.size(zip_path) / 1024), " KB): ",
          length(made), " chapter files, ", n_blocks, " blocks (",
          n_shown, " never executed, ", n_prose, " comment-only)")
}
