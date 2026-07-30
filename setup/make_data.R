# ---------------------------------------------------------------------------
# make_data.R - build every simulated dataset the book uses.
#
# Run this once, from the book's root folder:
#     source("setup/make_data.R")
#
# It writes CSV files into data/sim/. The SPSS, Julia, and Python setup files
# read those same CSVs, which is how all four languages end up printing the
# same numbers. Random number generators are NOT portable - R, Julia, and
# Python each produce a different stream from the same seed - so sharing the
# generated files is the only way to guarantee everyone sees what the book
# shows.
#
# The generating code below is the same code the chapters run, seeds and all.
# ---------------------------------------------------------------------------

library(tidyverse)
source("_common.R")   # rsnorm(): the book stays in the normal family

dir.create("data/sim", recursive = TRUE, showWarnings = FALSE)
put <- function(x, name) {
  readr::write_csv(x, file.path("data/sim", paste0(name, ".csv")))
  cat(sprintf("  %-28s %4d rows x %2d cols\n", paste0(name, ".csv"),
              nrow(x), ncol(x)))
}
cat("Writing the book's simulated datasets to data/sim/\n")

## Introduction -------------------------------------------------------------
put(tibble(
  height = c(5.5, 6.0, 5.8, 5.9, 6.1, 5.7, 5.6, 5.9, 6.2, 5.8),
  weight = c(125, 189, 220, 175, 145, 147, 256, 127, 155, 184)
), "intro-people")

## Ch 1 - Variables and Distributions ---------------------------------------
set.seed(20)
put(tibble(height = rnorm(500, mean = 68, sd = 4)), "ch01-heights")
set.seed(21)
put(tibble(value = rsnorm(1000, mean = 0, sd = 1, alpha = 6)), "ch01-skewed")
set.seed(22)
put(tibble(Normal   = rnorm(1000),
           Uniform  = runif(1000),
           Binomial = rbinom(1000, 10, .5),
           Poisson  = rpois(1000, 3)), "ch01-shapes")

## Ch 2 - The Best Guess -----------------------------------------------------
put(tibble(x = c(3, 5, 5, 7, 20)), "ch02-x")
put(tibble(income = c(30, 35, 40, 42, 45, 48, 5000)), "ch02-income")

## Ch 3 - Dispersion ---------------------------------------------------------
set.seed(7)
put(tibble(`tight (sd=3)` = rnorm(500, mean = 100, sd = 3),
           `wide (sd=20)` = rnorm(500, mean = 100, sd = 20)) |>
      pivot_longer(everything(), names_to = "group", values_to = "value"),
    "ch03-spread")
put(tibble(x = c(3, 5, 5, 7, 8, 9, 12, 40)), "ch03-x")

## Ch 4 - Cleaning House -----------------------------------------------------
put(tibble(age    = c(34, 29, 41, 220, 38, NA, 45),
           income = c(52, 61, 48, 55, -3, 60, 999),
           group  = c("A", "A", "b", "B", "A", "B", "A")), "ch04-dirty")

## Ch 5 - The Z-Distribution -------------------------------------------------
put(tibble(test  = c("SAT", "ACT"), score = c(1350, 30),
           mean  = c(1050, 21),     sd    = c(200, 5)), "ch05-scores")
put(tibble(measure = c("mood", "vitality"), score = c(4, 5),
           lo = c(1, 1), hi = c(5, 7)), "ch05-pomp")

## Ch 6 - Covariance ---------------------------------------------------------
set.seed(5)
study <- rnorm(100, 5, 2)
put(tibble(study = study, grade = 60 + 4 * study + rnorm(100, 0, 5)),
    "ch06-study")
set.seed(2)
x <- rnorm(1000)
put(tibble(x = x, y = 0.6 * x + rnorm(1000, sd = 0.8)), "ch06-restriction")
put(anscombe |> as_tibble() |>
      pivot_longer(everything(), names_to = c(".value", "set"),
                   names_pattern = "(.)(.)"), "ch06-anscombe")

## Ch 7 - Hypothesis Testing -------------------------------------------------
set.seed(1908)
put(tibble(sample_mean = map_dbl(1:10000, \(i) mean(rnorm(4, 20, 4)))),
    "ch07-nulldist")

## Ch 9 - Reliability --------------------------------------------------------
set.seed(8)
put(tibble(truth = rnorm(1000, 100, 15), error = rnorm(1000, 0, 8)) |>
      mutate(observed = truth + error), "ch09-ctt")
set.seed(9)
common <- rnorm(500)
put(map(1:6, \(i) common + rnorm(500)) |> set_names(paste0("item", 1:6)) |>
      as_tibble(), "ch09-items-tau")
set.seed(3)
Tval <- rnorm(500); lambda <- c(0.9, 0.8, 0.7, 0.5, 0.4)
put(map(lambda, \(l) l * Tval + rnorm(500, sd = sqrt(1 - l^2))) |>
      set_names(paste0("item", seq_along(lambda))) |> as_tibble(),
    "ch09-items-congeneric")
set.seed(10)
Tx <- rnorm(1000)
put(tibble(Tx = Tx) |>
      mutate(Ty = 0.6 * Tx + rnorm(1000, 0, 0.8),
             Ox = Tx + rnorm(1000, 0, 1),
             Oy = Ty + rnorm(1000, 0, 1)), "ch09-attenuation")

## Ch 10 - Validity ----------------------------------------------------------
set.seed(4)
anx <- rnorm(300)
put(tibble(anxiety_true = anx) |>
      mutate(new_scale = anx + rnorm(300, 0, 0.5),
             old_scale = anx + rnorm(300, 0, 0.5),
             verbal    = rnorm(300)), "ch10-validity")

## Ch 12 - GLM ---------------------------------------------------------------
set.seed(12)
grp <- factor(rep(c("control", "treatment"), each = 40))
put(tibble(group = grp, y = rnorm(80) + if_else(grp == "treatment", 0.6, 0)),
    "ch12-groups")

## Ch 13 - Point-Biserial ----------------------------------------------------
set.seed(14)
studied <- rbinom(50, 1, 0.5)
put(tibble(studied = studied,
           score = 70 + 8 * studied + rnorm(50, 0, 6)), "ch13-study")

## Ch 14 - Simple Regression -------------------------------------------------
put(tibble(x = c(1, 2, 3, 4, 5), y = c(4, 8, 10, 7, 8)), "ch14-toy")

## Ch 15 - Multiple Regression -----------------------------------------------
set.seed(1936)
base <- rnorm(100)
put(tibble(y = base + rnorm(100), x1 = base + rnorm(100),
           x2 = base + rnorm(100)), "ch15-tangled")
set.seed(42)
x1 <- rnorm(200); x2 <- 0.7 * x1 + rnorm(200, sd = sqrt(1 - 0.49))
put(tibble(x1 = x1, x2 = x2, y = 0.5 * x1 + 0.4 * x2 + rnorm(200)),
    "ch15-typess")

## Ch 16 - ANOVA and the GLM -------------------------------------------------
set.seed(1925)
xx <- sort(rnorm(100))
d16 <- tibble(x = xx, happy = xx + rnorm(100)) |>
  mutate(pet = cut(x, 4, labels = c("cat", "fish", "pig", "dog")))
d16 <- d16 |>
  mutate(mess = factor(if_else(rnorm(100) > 0, "messy", "tidy")),
         sad  = -x + as.numeric(mess) + rnorm(100),
         passed = rbinom(100, size = 1, prob = plogis(x)))
put(d16, "ch16-pets")

## Ch 17 - Basic ANOVA -------------------------------------------------------
set.seed(17)
put(tibble(dose = factor(rep(c("none", "low", "high"), each = 30),
                         levels = c("none", "low", "high")),
           growth = rnorm(90, mean = rep(c(10, 12, 15), each = 30), sd = 3)),
    "ch17-dose")

## Ch 18 - Coding ------------------------------------------------------------
set.seed(725)
x19 <- rnorm(200)
put(tibble(x = x19,
           pet = cut(x19, 4, labels = c("cat", "fish", "pig", "dog")),
           happy = x19 + rnorm(200)), "ch18-pets")
set.seed(9)
cnt <- c(cat = 20, fish = 30, pig = 40, dog = 10)
mu_w <- c(cat = 0, fish = 1, pig = 2, dog = 3)
petw <- factor(rep(names(cnt), cnt), levels = names(cnt))
put(tibble(petw = petw,
           happyw = rnorm(length(petw), mean = mu_w[as.character(petw)], sd = 1)),
    "ch18-unbalanced")

## Ch 19 - Data Reduction ----------------------------------------------------
set.seed(7)
Tval2 <- rnorm(200)
put(map(1:6, \(i) Tval2 + rnorm(200, sd = 0.8)) |>
      set_names(paste0("x", 1:6)) |> as_tibble(), "ch19-items")

## Ch 20 - CFA / SEM ---------------------------------------------------------
set.seed(2026)
N <- 400; L <- 0.75
F1 <- rnorm(N); F2 <- 0.5 * F1 + rnorm(N, sd = sqrt(1 - 0.25))
mk <- function(f) L * f + rnorm(N, sd = sqrt(1 - L^2))
put(tibble(a1 = mk(F1), a2 = mk(F1), a3 = mk(F1), a4 = mk(F1),
           b1 = mk(F2), b2 = mk(F2), b3 = mk(F2), b4 = mk(F2)), "ch20-cfa")

## Ch 21 - Measurement Invariance -------------------------------------------
set.seed(1)
Ninv <- 300
inv <- tibble(grp = rep(c("A", "B"), each = Ninv), trait = rnorm(2 * Ninv)) |>
  mutate(bias = if_else(grp == "B", 0.5, 0))
items_inv <- map(1:6, \(i) inv$trait + inv$bias + rnorm(2 * Ninv, sd = 0.8))
put(inv |> mutate(composite = reduce(items_inv, `+`) / 6), "ch21-invariance")

## Ch 22 - Latent Class ------------------------------------------------------
set.seed(2026)
Nl <- 800; J <- 8
rho <- rbind(rep(0.80, J), rep(0.20, J))
rho[1, c(7, 8)] <- 0.30; rho[2, c(7, 8)] <- 0.70
cls <- sample(1:2, Nl, replace = TRUE, prob = c(0.35, 0.65))
put(do.call(rbind, map(cls, \(k) rbinom(J, 1, rho[k, ]))) |>
      as_tibble(.name_repair = \(z) paste0("x", seq_along(z))), "ch22-lca")

## Ch 23 - IRT and Generalizability -----------------------------------------
set.seed(2026)
np <- 120; ni <- 12
person <- rnorm(np, sd = 1.0); item <- rnorm(ni, sd = 0.5)
put(expand_grid(p = 1:np, i = 1:ni) |>
      mutate(score = person[p] + item[i] + rnorm(np * ni, sd = 0.7)),
    "ch23-gtheory")

## Ch 24 - Causal Inference --------------------------------------------------
set.seed(4); n <- 2000
Z <- rnorm(n)
put(tibble(Z = Z, X = Z + rnorm(n), Y = Z + rnorm(n)), "ch24-fork")
set.seed(5)
Xp <- rnorm(n); Mp <- Xp + rnorm(n)
put(tibble(X = Xp, M = Mp, Y = Mp + rnorm(n)), "ch24-pipe")
set.seed(6)
Xc <- rnorm(n); Yc <- rnorm(n)
put(tibble(X = Xc, Y = Yc, Z = Xc + Yc + rnorm(n)), "ch24-collider")

## Ch 25 - Beyond the Normal Curve ------------------------------------------
set.seed(42)
put(tibble(samp = rsnorm(30, mean = 50, sd = 20, alpha = 8)), "ch25-skewed-sample")
set.seed(7)
put(tibble(value = c(rnorm(15, mean = 0.0), rnorm(15, mean = 0.8)),
           group = rep(1:2, each = 15)), "ch25-twogroups")
set.seed(1)
put(tibble(z = c(rnorm(19, mean = 100, sd = 10), 250)), "ch25-outlier")

## Ch 27 - Depression Profiles ----------------------------------------------
set.seed(2026)
Nd <- 1200; kd <- 21
symptoms <- c("sadness","pessimism","past_failure","loss_pleasure","guilt",
              "punishment","self_dislike","self_critical","suicidal","crying",
              "agitation","loss_interest","indecision","worthlessness",
              "loss_energy","sleep","irritability","appetite","concentration",
              "tiredness","loss_sex_interest")
theta <- rnorm(Nd, mean = -0.5)
diffs <- sort(rnorm(kd, mean = 2.6, sd = 1.3))
put(map(seq_len(kd), \(j) {
      p <- plogis(outer(theta, diffs[j] + c(-1.1, 0, 1.1), `-`))
      rowSums(runif(Nd) < p)
    }) |> set_names(symptoms) |> as_tibble(), "ch27-bdi")

## Ch 28 - Building a Measure -----------------------------------------------
set.seed(2026)
Nc <- 500; load <- 0.75
Fs <- list(F1 = rnorm(Nc), F2 = rnorm(Nc), F3 = rnorm(Nc))
mkc <- function(f) load * f + rnorm(Nc, sd = sqrt(1 - load^2))
put(Fs[rep(c("F1", "F2", "F3"), each = 4)] |> map(mkc) |>
      set_names(paste0("item", 1:12)) |> as_tibble(), "ch28-curiosity")

## Ch 29 - Missing Data ------------------------------------------------------
set.seed(2026)
Nm <- 2000
put(tibble(z = rnorm(Nm)) |>
      mutate(y = 0.6 * z + rnorm(Nm, sd = 0.8),
             p_miss = plogis(1.8 * z - 0.2),
             y_obs = if_else(runif(Nm) < p_miss, NA, y)), "ch29-missing")

## Appendix - the four-language worked example -------------------------------
set.seed(1)
appx <- tibble(group = factor(rep(c("A", "B"), each = 40)),
               x = rnorm(80, mean = 50, sd = 10)) |>
  mutate(y = 100 + 0.8 * x + rnorm(80, sd = 12))
put(appx, "appendix-d")
set.seed(2)
put(map(1:4, \(i) rnorm(80) + appx$x / 10) |>
      set_names(paste0("item", 1:4)) |> as_tibble(), "appendix-items")

cat("\nDone. The SPSS, Julia, and Python setup files read these same files.\n")
