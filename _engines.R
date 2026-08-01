# ---------------------------------------------------------------------------
# _engines.R - make SPSS, Julia and Python chunks EXECUTE.
#
# The book shows every procedure in four languages. Without this file the R
# tab runs and the other three are static text a reader has to trust. These
# knitr engines run them for real and paste back whatever they produced -
# tables, printed values, and figures.
#
# Each engine follows the same shape: write the chunk to a scratch file, run
# the language's own interpreter on it, capture stdout, and look for a figure
# the chunk may have drawn. Nothing is shared between chunks except through
# files, which is why every non-R tab loads its own data.
#
# Sourced by _common.R, so any chapter that sources that gets these too.
# ---------------------------------------------------------------------------

# Is this interpreter actually on the machine doing the build?
#
# The book should render for anyone who clones it, whether or not they have
# PSPP, Julia and Python installed. When an interpreter is missing we fall
# back to showing the code as static text - exactly what the book did before
# these engines existed - rather than failing the build. That also means CI
# can gain the toolchains one at a time without ever going red.
.book_have <- function(cmd) nzchar(Sys.which(cmd)[[1]])

.book_static <- function(options, why) {
  message("  [", options$engine, "] ", why, " - showing code without running it")
  knitr::engine_output(options, options$code, NULL)
}

.book_fig_dir <- function() {
  d <- file.path("_figs")
  dir.create(d, showWarnings = FALSE, recursive = TRUE)
  d
}

# A stable, collision-proof name for whatever figure this chunk draws. Labelled
# chunks use their label; unlabelled ones fall back to a hash of their own code,
# which stays the same across renders but cannot clash with another chunk.
.book_fig_path <- function(options, ext = "png") {
  stem <- options$label
  if (is.null(stem) || !nzchar(stem)) {
    code <- paste(options$code, collapse = "\n")
    stem <- paste0("anon-", substr(
      paste(sprintf("%02x", utf8ToInt(substr(code, 1, 1))), nchar(code),
            abs(sum(utf8ToInt(code))) %% 99991, sep = ""), 1, 16))
  }
  file.path(.book_fig_dir(), paste0(stem, "-", options$engine, ".", ext))
}

# Emit text output plus any figures the chunk drew. `figs` may be several: a
# single PSPP chunk with four GRAPH commands produces four charts.
.book_output <- function(options, out, figs = NULL) {
  txt <- knitr::engine_output(options, options$code, out)
  if (length(figs)) {
    figs <- figs[!is.na(figs)]
    figs <- figs[file.exists(figs)]
    for (f in figs) txt <- paste0(txt, "\n\n![](", f, ")\n")
  }
  txt
}

# PSPP writes extra charts as "name.png-2", "name.png-3", ... which no browser
# will display. Rename them to real .png files and return the lot in order.
.book_collect_pspp_figs <- function(fig) {
  extras <- list.files(dirname(fig),
                       pattern = paste0("^", basename(fig), "-\\d+$"),
                       full.names = TRUE)
  extras <- extras[order(as.integer(sub(".*-", "", extras)))]
  renamed <- vapply(extras, function(f) {
    new <- sub("\\.png-(\\d+)$", "-\\1.png", f)
    file.rename(f, new)
    new
  }, character(1), USE.NAMES = FALSE)
  c(if (file.exists(fig)) fig, renamed)
}

# --- SPSS, by way of PSPP ---------------------------------------------------
# PSPP's txt driver gives clean, selectable tables; its png driver renders the
# page as an image, which is how we get charts. We ask for the image only when
# the syntax actually contains a charting command, so ordinary table output
# stays real text rather than a picture of text.
knitr::knit_engines$set(pspp = function(options) {
  # knitr does not enforce eval = FALSE for custom engines; we must.
  if (isFALSE(options$eval)) {
    return(knitr::engine_output(options, options$code, NULL))
  }
  if (!.book_have("pspp")) return(.book_static(options, "PSPP not installed"))

  code <- paste(options$code, collapse = "\n")
  f <- tempfile(fileext = ".sps")
  writeLines(code, f)

  out <- suppressWarnings(
    system2("pspp", c("-O", "format=txt", f), stdout = TRUE, stderr = TRUE))

  figs <- NULL
  if (grepl("\\b(GRAPH|GGRAPH|PLOT)\\b", code, ignore.case = TRUE)) {
    fig <- .book_fig_path(options)
    unlink(list.files(dirname(fig),
                      pattern = paste0("^", basename(fig), "(-\\d+)?$"),
                      full.names = TRUE))
    suppressWarnings(
      system2("pspp", c("-O", "format=png", "-o", fig, f),
              stdout = FALSE, stderr = FALSE))
    figs <- .book_collect_pspp_figs(fig)
  }
  .book_output(options, out, figs)
})

# --- Julia ------------------------------------------------------------------
# Run against the book's own Julia project so the package versions are pinned.
# GKSwstype=100 puts the GR backend in headless mode; without it Plots tries to
# open a window and dies on a build server. After the chunk runs we ask Plots
# for the current figure and save it, which quietly does nothing if the chunk
# drew no plot.
knitr::knit_engines$set(julia = function(options) {
  # knitr does not enforce eval = FALSE for custom engines; we must.
  if (isFALSE(options$eval)) {
    return(knitr::engine_output(options, options$code, NULL))
  }
  if (!.book_have("julia")) return(.book_static(options, "Julia not installed"))

  fig <- .book_fig_path(options)
  code <- paste(options$code, collapse = "\n")
  wrapped <- paste0(
    'ENV["GKSwstype"] = "100"\n',
    code, "\n",
    'try\n',
    '  if isdefined(Main, :Plots) && Plots.current() !== nothing\n',
    '    Plots.savefig(Plots.current(), "', fig, '")\n',
    '  end\n',
    'catch\n',
    'end\n')
  f <- tempfile(fileext = ".jl")
  writeLines(wrapped, f)

  out <- suppressWarnings(
    system2("julia", c("--project=.", "--startup-file=no", f),
            stdout = TRUE, stderr = TRUE))
  .book_output(options, out, if (file.exists(fig)) fig else NULL)
})

# --- Python -----------------------------------------------------------------
# The Agg backend draws to a file rather than a screen. If the chunk opened any
# matplotlib figure we save it; plt.show() becomes a no-op under Agg, so the
# book's code needs no special-casing.
knitr::knit_engines$set(python = function(options) {
  # knitr does not enforce eval = FALSE for custom engines; we must.
  if (isFALSE(options$eval)) {
    return(knitr::engine_output(options, options$code, NULL))
  }
  # Insist on the book's own virtualenv rather than whatever python3 happens to
  # be on PATH: a bare system Python has none of the packages these tabs import,
  # and would fill the page with import tracebacks instead of output.
  py <- file.path(getwd(), ".venv", "bin", "python")
  if (!file.exists(py)) {
    return(.book_static(options, "the book's .venv is not set up"))
  }

  fig <- .book_fig_path(options)
  code <- paste(options$code, collapse = "\n")
  wrapped <- paste0(
    "import matplotlib\n",
    "matplotlib.use('Agg')\n",
    "import matplotlib.pyplot as _plt\n",
    code, "\n",
    "if _plt.get_fignums():\n",
    "    _plt.savefig('", fig, "', dpi = 150, bbox_inches = 'tight')\n")
  f <- tempfile(fileext = ".py")
  writeLines(wrapped, f)

  out <- suppressWarnings(
    system2(py, f, stdout = TRUE, stderr = TRUE))
  .book_output(options, out, if (file.exists(fig)) fig else NULL)
})
