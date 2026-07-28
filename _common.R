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
