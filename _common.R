# Book-wide helpers, sourced at the top of every chapter.
#
# Nothing here is magic - it is three small functions that keep the numbers in
# this book readable and consistent. The whole file is reprinted in the
# "Setup and Required Packages" appendix so you can see exactly what it does.

# House rule: every number we print is rounded to two decimal places.
# round2() applies that to every numeric column of a data frame at once.
round2 <- function(x, digits = 2) {
  dplyr::mutate(x, dplyr::across(
    tidyselect::where(is.numeric),
    \(v) round(v, digits)
  ))
}

# p-values are the one exception. Rounded to two decimals, a p of .0000003
# would print as 0.00, which reads as "exactly zero" - and no p-value is ever
# exactly zero. So we give p three decimals and a floor: anything smaller than
# .001 prints as "< .001", the way APA style reports it.
fmt_p <- function(p) {
  dplyr::if_else(p < .001, "< .001", sprintf("%.3f", p))
}

# --- The book's figure theme ------------------------------------------------
# Every plot in the book ends with theme_book() rather than theme_minimal(),
# so type size and styling are set in ONE place instead of drifting chapter to
# chapter. Figure titles live in the chunk's fig-cap, not inside the plot, so
# they are real searchable text and Quarto can number and cross-reference them.
theme_book <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size)
}

# --- Staying inside the normal family ---------------------------------------
# This book keeps every distribution it draws in one family, so that a reader
# never has to learn a second set of parameters just to see what "skewed"
# means. A SKEW-NORMAL is a normal curve with one extra knob, alpha:
#
#     alpha = 0   ->  exactly the normal curve
#     alpha > 0   ->  the right tail stretches out
#     alpha < 0   ->  the left tail stretches out
#
# It is built from two ordinary normal draws, which is the whole point: skew
# is not a different kind of thing, it is a normal that leans.
rsnorm <- function(n, mean = 0, sd = 1, alpha = 0) {
  delta <- alpha / sqrt(1 + alpha^2)
  z0 <- abs(rnorm(n))            # a half-normal: the lean
  z1 <- rnorm(n)                 # an ordinary normal: the symmetric part
  mean + sd * (delta * z0 + sqrt(1 - delta^2) * z1)
}

# The matching density, so a histogram can always carry its theoretical curve.
dsnorm <- function(x, mean = 0, sd = 1, alpha = 0) {
  z <- (x - mean) / sd
  2 / sd * dnorm(z) * pnorm(alpha * z)
}

# tidy2() is the one we use most: it takes a fitted model, turns it into a
# tidy data frame with broom::tidy(), rounds the estimates to two decimals,
# and formats the p-values. One call, house style applied.
tidy2 <- function(model, ...) {
  broom::tidy(model, ...) |>
    dplyr::mutate(
      dplyr::across(
        tidyselect::where(is.numeric) & !dplyr::any_of("p.value"),
        \(v) round(v, 2)
      ),
      dplyr::across(dplyr::any_of("p.value"), fmt_p)
    )
}
