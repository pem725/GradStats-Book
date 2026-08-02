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

# One place that answers "how big is a figure in this book?".
#
# The R chunks get their size from fig-width / fig-height / fig-dpi in
# _quarto.yml, and knitr hands those same values to a custom engine in
# options$fig.width, options$fig.height and options$dpi. Reading them here
# means SPSS, Julia and Python inherit the book's geometry automatically - and
# a chunk that overrides it with #| fig-width: 10 changes all four languages at
# once instead of only the R tab.
#
# The Julia point sizes are derived, not invented. ggplot2's
# theme_minimal(base_size) sets axis TITLES at base_size and axis TEXT at
# 0.8 * base_size, and we want Julia's type to come out the same size on the
# page so the tabs do not change character when a reader clicks between them.
#
# The conversion is NOT the obvious points-to-pixels one. ggplot2 and matplotlib
# both measure type in real points on a figure measured in inches, so dpi
# converts between them. Plots.jl measures its canvas in pixels and scales type
# WITH the canvas, so applying dpi as well counts it twice - the first attempt
# here used base_size * dpi / 72 and produced axis labels roughly two and a half
# times too big, with the y-axis title running off the edge of the plot.
#
# Deriving it from Plots' 600-pixel reference canvas overshot in the other
# direction, so the number below is measured rather than reasoned. Rendering
# the same histogram at a range of font sizes and measuring the height of the
# tick-label text in the finished png - digits in both languages, so a fair
# comparison - ggplot2's 12-point base lands on 16 in Plots at this figure
# width. Everything else follows from that one anchor: axis titles keep
# ggplot's 1.25 ratio over tick labels, and a chunk that asks for a different
# fig-width scales in proportion.
.book_fig_geometry <- function(options, base_size = 12) {
  w   <- if (is.null(options$fig.width))  7   else options$fig.width
  h   <- if (is.null(options$fig.height)) 4.5 else options$fig.height
  dpi <- if (is.null(options$dpi))        192 else options$dpi

  jl <- base_size * (20 / 12) * (7 / w)   # measured anchor, scaled by width
  list(
    in_w     = w,
    in_h     = h,
    dpi      = dpi,
    px_w     = round(w * dpi),
    px_h     = round(h * dpi),
    pt_guide = round(jl),              # axis titles
    pt_tick  = round(jl * 0.8)         # axis text and legends
  )
}

# A name for whatever figure this chunk draws, unique across the WHOLE book.
#
# The chapter name has to be part of it. knitr labels unlabelled chunks
# "unnamed-chunk-1", "unnamed-chunk-2", ... and starts counting again at 1 in
# every file, so those labels are unique only within one chapter. R's own plots
# are safe because knitr files them under a per-chapter directory; these
# engines share a single _figs/, so without the chapter prefix chapter 33 would
# quietly overwrite chapter 9's figure and both pages would show chapter 33's.
.book_fig_path <- function(options, ext = "png") {
  chap <- tryCatch(knitr::current_input(), error = function(e) NULL)
  chap <- if (is.null(chap)) "book" else sub("\\.[^.]*$", "", basename(chap))

  stem <- options$label
  if (is.null(stem) || !nzchar(stem)) stem <- "chunk"

  file.path(.book_fig_dir(),
            paste0(chap, "-", stem, "-", options$engine, ".", ext))
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

# Where on this PSPP page is the chart, if there is one at all?
#
# PSPP renders a whole PAGE at a time, so asking it for pictures gets one back
# even when the syntax drew nothing - a picture of a table, or (when a chapter
# uses a command PSPP has not implemented, such as GGRAPH) a picture of an
# error message. Neither belongs in the book as a figure: the txt pass already
# shows that same text as real, selectable, searchable text. And when a page
# does hold a chart it usually holds tables underneath it too, which would be
# the same numbers a second time, as a picture, in a very tall image.
#
# Colour answers both questions. PSPP sets every table and every error message
# in plain black and reaches for its palette only when it draws, so coloured
# pixels mean "chart here" and their bounding box says where. Returns NULL when
# the page is black and white - that is, when there is no chart on it.
#
# The scan runs on a thumbnail. A full page at 192 dpi is around eight million
# pixels, and testing each one in R is slow enough to notice across a whole
# book; a 300-pixel-wide copy answers the same question in a fraction of the
# time, and the box is scaled back up afterwards.
.book_chart_bbox <- function(f) {
  if (!file.exists(f) || !requireNamespace("magick", quietly = TRUE)) return(NULL)
  tryCatch({
    im    <- magick::image_read(f)
    full  <- as.numeric(magick::image_info(im)[1, c("width", "height")])
    small <- magick::image_resize(im, "300x")

    # as.integer() on magick's pixel data gives [row, column, channel] - that
    # is, [y, x, rgb]. Getting this axis order wrong silently compares pixels
    # DOWN the page instead of across the three colour channels, which finds
    # "colour" everywhere and crops to nonsense.
    d <- as.integer(magick::image_data(small, "rgb"))
    r <- d[, , 1]; g <- d[, , 2]; b <- d[, , 3]
    sat <- pmax(r, g, b) - pmin(r, g, b)

    hit <- which(sat > 25, arr.ind = TRUE)   # col 1 = y, col 2 = x
    if (nrow(hit) < 20) return(NULL)         # no chart on this page

    sc <- full[1] / ncol(sat)
    list(
      x0 = (min(hit[, 2]) - 1) * sc, x1 = max(hit[, 2]) * sc,
      y0 = (min(hit[, 1]) - 1) * sc, y1 = max(hit[, 1]) * sc,
      w = full[1], h = full[2]
    )
  }, error = function(e) NULL)
}

.book_has_chart <- function(f) !is.null(.book_chart_bbox(f))

# Trim the blank margins off a page.
#
# This deliberately stops short of cropping to the chart alone. It is tempting:
# the coloured box says exactly where the plot is, so padding around it should
# leave the chart and drop the tables PSPP prints underneath. It does not work.
# The axis numbers and axis titles sit OUTSIDE the coloured box in plain black,
# and on a real page the blank gap above the x-axis title is wider than the gap
# below it - so no padding, and no whitespace-gap rule, separates "still part of
# the chart" from "start of the next table". Every setting either clipped the
# axis labels off the plot or swallowed the tables anyway.
#
# Losing an axis label is a worse figure than a tall one, so we trim the white
# border and leave whatever else PSPP put on that page in place.
.book_trim_page <- function(f) {
  if (!requireNamespace("magick", quietly = TRUE)) return(invisible(FALSE))
  tryCatch({
    magick::image_write(magick::image_trim(magick::image_read(f)), f)
    invisible(TRUE)
  }, error = function(e) invisible(FALSE))
}

# Turn one PSPP run into a list of chart images.
#
# Getting a usable picture out of PSPP takes a detour. Its png driver
# rasterises at a fixed 72 pixels to the inch, which is far too soft next to a
# 1344-pixel ggplot, and its svg driver - the obvious way to get something
# sharp - lays chart and tables on top of each other, so the output is
# unreadable. Its PDF driver gets the layout right, so we go out through PDF
# and rasterise that ourselves at the book's own dpi.
#
# What comes back is one image per PAGE. We keep only the pages that hold a
# chart - which throws away the pages that are just a picture of a table, or of
# an error message - and trim the blank margins off the ones we keep.
.book_pspp_charts <- function(sps, root, dpi) {
  if (!.book_have("pdftoppm")) return(NULL)
  pdf <- paste0(root, ".pdf")
  unlink(list.files(dirname(root),
                    pattern = paste0("^", basename(root), "([-.].*)?$"),
                    full.names = TRUE))
  suppressWarnings(system2("pspp",
    c("--no-output", "-o", pdf, "-O", "format=pdf", sps),
    stdout = FALSE, stderr = FALSE))
  if (!file.exists(pdf)) return(NULL)

  suppressWarnings(system2("pdftoppm",
    c("-r", dpi, "-png", pdf, root), stdout = FALSE, stderr = FALSE))
  unlink(pdf)

  pages <- list.files(dirname(root), full.names = TRUE,
                      pattern = paste0("^", basename(root), "-\\d+\\.png$"))
  pages <- pages[order(as.integer(sub(".*-(\\d+)\\.png$", "\\1", pages)))]

  keep <- Filter(.book_has_chart, pages)
  unlink(setdiff(pages, keep))
  for (f in keep) .book_trim_page(f)
  if (length(keep)) keep else NULL
}

# --- SPSS, by way of PSPP ---------------------------------------------------
# Every chunk runs twice, for two different jobs. The txt driver gives clean,
# selectable tables, which is what most SPSS output is and how it should be
# read. The second pass exists only to catch charts, and only runs when the
# syntax actually asks for one - so ordinary table output stays real text
# rather than becoming a picture of text.
knitr::knit_engines$set(pspp = function(options) {
  # knitr does not enforce eval = FALSE for custom engines; we must.
  if (isFALSE(options$eval)) {
    return(knitr::engine_output(options, options$code, NULL))
  }
  if (!.book_have("pspp")) return(.book_static(options, "PSPP not installed"))

  code <- paste(options$code, collapse = "\n")
  f <- tempfile(fileext = ".sps")
  writeLines(code, f)
  geo <- .book_fig_geometry(options)

  out <- suppressWarnings(
    system2("pspp", c("-O", "format=txt", f), stdout = TRUE, stderr = TRUE))

  # Only bother looking for pictures when the syntax actually asks to draw one.
  # `-O` options attach to the PREVIOUS `-o`, and --no-output switches off the
  # default driver, which otherwise drops a stray pspp.png in the working
  # directory; both are handled inside .book_pspp_charts().
  figs <- NULL
  if (grepl("\\b(GRAPH|GGRAPH|PLOT)\\b", code, ignore.case = TRUE)) {
    root <- sub("\\.png$", "", .book_fig_path(options))
    figs <- .book_pspp_charts(f, root, geo$dpi)
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
  geo <- .book_fig_geometry(options)

  # The book's Julia tabs are written the way you would type them at the REPL:
  # a bare `mean(df.x)` on its own line is meant to show its answer. A script
  # does not do that, so we evaluate the chunk one top-level expression at a
  # time and display whatever each one returns.
  user <- tempfile(fileext = ".jl")
  writeLines(paste(options$code, collapse = "\n"), user)

  runner <- tempfile(fileext = ".jl")
  writeLines(c(
    'ENV["GKSwstype"] = "100"',
    sprintf('src = read("%s", String)', user),
    'parsed = Meta.parseall(src)',
    'silent = (:(=), :using, :import, :function, :macro, :const, :struct, :module)',
    'for ex in parsed.args',
    '    isa(ex, LineNumberNode) && continue',
    '    val = Core.eval(Main, ex)',
    '    # assignments and imports stay quiet, the way they do in R and Python;',
    '    # a bare expression shows its value, the way it would at the REPL',
    '    (isa(ex, Expr) && ex.head in silent) && continue',
    '    val === nothing || display(val)',
    'end',
    'try',
    '    if isdefined(Main, :Plots) && Plots.current() !== nothing',
    # Plots.jl defaults to a 600x400 canvas with 11-point type, which next to a
    # 1344x864 ggplot looks small and blurry. Restyle the finished plot to the
    # book's geometry just before saving, so the Julia tab and the R tab show
    # the same picture at the same size and the same type size.
    sprintf('        Plots.plot!(Plots.current(); size = (%d, %d),',
            geo$px_w, geo$px_h),
    sprintf('            guidefontsize = %d, tickfontsize = %d,',
            geo$pt_guide, geo$pt_tick),
    sprintf('            legendfontsize = %d, titlefontsize = %d,',
            geo$pt_tick, geo$pt_guide),
    # Plots sizes its margins for its own smaller default type. At the book's
    # larger sizes the y-axis title runs off the left edge of the canvas and is
    # cut in half, so widen the margins to match.
    '            left_margin = 6Plots.mm, bottom_margin = 6Plots.mm)',
    sprintf('        Plots.savefig(Plots.current(), "%s")', fig),
    '    end',
    'catch',
    'end'), runner)

  out <- suppressWarnings(
    system2("julia", c("--project=.", "--startup-file=no", runner),
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
  geo <- .book_fig_geometry(options)

  # Same problem as Julia: the book's Python tabs are written REPL-style, where
  # a bare `df.x.mean()` shows its value. Scripts stay silent. Compiling each
  # top-level statement in "single" mode restores the REPL's echo, so the tabs
  # need no print() calls bolted on.
  user <- tempfile(fileext = ".py")
  writeLines(paste(options$code, collapse = "\n"), user)

  runner <- tempfile(fileext = ".py")
  writeLines(c(
    "import ast, matplotlib",
    "matplotlib.use('Agg')",
    "import matplotlib.pyplot as _plt",
    # Match the R figures exactly: 7 x 4.5 in at 192 dpi and 12-point type, the
    # same numbers set in _quarto.yml. autolayout keeps labels from being
    # clipped WITHOUT changing the figure's size - which is what the old
    # bbox_inches='tight' did, and why every Python figure used to come out a
    # different shape. A chunk that sets its own figsize still wins.
    "_plt.rcParams.update({",
    sprintf("    'figure.figsize': (%s, %s),", geo$in_w, geo$in_h),
    sprintf("    'figure.dpi': %d,", geo$dpi),
    sprintf("    'savefig.dpi': %d,", geo$dpi),
    "    'figure.autolayout': True,",
    "    'font.size': 12,",
    "})",
    sprintf("_src = open(%s).read()", shQuote(user)),
    "_g = {'__name__': '__main__'}",
    "for _node in ast.parse(_src).body:",
    "    _mod = ast.Interactive(body=[_node])",
    "    ast.fix_missing_locations(_mod)",
    sprintf("    exec(compile(_mod, %s, 'single'), _g)", shQuote(user)),
    "if _plt.get_fignums():",
    sprintf("    _plt.savefig(%s)", shQuote(fig))
  ), runner)

  out <- suppressWarnings(
    system2(py, runner, stdout = TRUE, stderr = TRUE))
  .book_output(options, out, if (file.exists(fig)) fig else NULL)
})
