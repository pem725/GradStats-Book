# ---------------------------------------------------------------------------
# load_data.py - the book's datasets, in Python.
#
#     from setup.load_data import book_data
#     d = book_data("ch06-study")
#
# Every code tab in the book that needs data gets it from here. The files in
# data/sim/ were generated once in R and are shared across all four languages,
# which is the only way to guarantee you see the same numbers the book prints.
#
# Why not just simulate it here? Because random number generators are not
# portable. R, Julia, and Python all produce a different stream from the same
# seed, so re-simulating would give you statistically equivalent data with
# visibly different numbers - and you would spend an hour wondering what you
# broke. The recipe for each dataset is in the comment beside it, so you can
# still see exactly how it was built.
# ---------------------------------------------------------------------------

import pandas as pd

DATA_DIR = "data/sim"

# Categorical order matters and CSV does not preserve it. Without these, pandas
# would sort "cat, dog, fish, pig" alphabetically and silently reorder every
# coefficient that uses them; "none, low, high" would come back as a nonsense
# alphabetical ladder.
LEVELS = {
    "ch03-spread":     {"group": ["tight (sd=3)", "wide (sd=20)"]},
    "ch12-groups":     {"group": ["control", "treatment"]},
    "ch16-pets":       {"pet": ["cat", "fish", "pig", "dog"],
                        "mess": ["messy", "tidy"]},
    "ch17-dose":       {"dose": ["none", "low", "high"]},
    "ch18-pets":       {"pet": ["cat", "fish", "pig", "dog"]},
    "ch18-unbalanced": {"petw": ["cat", "fish", "pig", "dog"]},
    "ch21-invariance": {"grp": ["A", "B"]},
    "appendix-d":      {"group": ["A", "B"]},
}

# What each dataset is, and how it was made.
RECIPE = {
    "intro-people":          "10 people: height in feet, weight in pounds (typed by hand).",
    "ch01-heights":          "set.seed(20); rnorm(500, mean = 68, sd = 4)",
    "ch01-skewed":           "set.seed(21); rexp(1000, rate = 1)",
    "ch01-shapes":           "set.seed(22); rnorm / runif / rbinom(10, .5) / rpois(3), 1000 each",
    "ch02-x":                "c(3, 5, 5, 7, 20) - note the outlier",
    "ch02-income":           "c(30, 35, 40, 42, 45, 48, 5000) - thousands, one very rich person",
    "ch03-spread":           "set.seed(7); rnorm(500, 100, sd = 3) and rnorm(500, 100, sd = 20)",
    "ch03-x":                "c(3, 5, 5, 7, 8, 9, 12, 40)",
    "ch04-dirty":            "Seven rows with an impossible age, a negative income, a 999 code, and a stray 'b'.",
    "ch05-scores":           "One SAT and one ACT score with their scale means and SDs.",
    "ch05-pomp":             "A mood item (1-5) and a vitality item (1-7), for POMP scoring.",
    "ch06-study":            "set.seed(5); study ~ N(5,2); grade = 60 + 4*study + N(0,5)",
    "ch06-restriction":      "set.seed(2); x ~ N(0,1); y = 0.6*x + N(0,0.8)",
    "ch06-anscombe":         "R's built-in anscombe, stacked long into set / x / y.",
    "ch07-nulldist":         "set.seed(1908); 10,000 means of n = 4 drawn from N(20, 4)",
    "ch09-ctt":              "set.seed(8); truth ~ N(100,15), error ~ N(0,8), observed = truth + error",
    "ch09-items-tau":        "set.seed(9); six items = one common factor + independent noise",
    "ch09-items-congeneric": "set.seed(3); five items with UNEQUAL loadings .9 .8 .7 .5 .4",
    "ch09-attenuation":      "set.seed(10); true pair correlated .6, each seen through a noisy sensor",
    "ch10-validity":         "set.seed(4); a new scale, an established scale, and an unrelated measure",
    "ch12-groups":           "set.seed(12); 40 control and 40 treatment, true difference 0.6",
    "ch13-study":            "set.seed(14); studied 0/1; score = 70 + 8*studied + N(0,6)",
    "ch14-toy":              "Five points, small enough to check every number by hand.",
    "ch15-tangled":          "set.seed(1936); y, x1, x2 all built from a shared 'base' so they tangle",
    "ch15-typess":           "set.seed(42); x1 and x2 correlate ~.7; y = .5*x1 + .4*x2 + noise",
    "ch16-pets":             "set.seed(1925); a continuous 'dogness' score cut into four pet types",
    "ch17-dose":             "set.seed(17); three fertilizer doses, 30 plants each",
    "ch18-pets":             "set.seed(725); 200 pets, same cut-the-continuum trick as ch 16",
    "ch18-unbalanced":       "set.seed(9); deliberately unequal cells - 20/30/40/10",
    "ch19-items":            "set.seed(7); six noisy views of one construct",
    "ch20-cfa":              "set.seed(2026); eight items from TWO factors correlated ~.5",
    "ch21-invariance":       "set.seed(1); same true trait in both groups, group B answers 0.5 higher",
    "ch22-lca":              "set.seed(2026); two latent classes that differ in PATTERN (items 7-8 reversed)",
    "ch23-gtheory":          "set.seed(2026); 120 people crossed with 12 items",
    "ch24-fork":             "set.seed(4); Z causes both X and Y (the confounder)",
    "ch24-pipe":             "set.seed(5); X -> M -> Y (the mediator)",
    "ch24-collider":         "set.seed(6); X and Y both cause Z (the collider)",
    "ch25-skewed-sample":    "set.seed(42); rexp(30, rate = 1/50) - small and skewed",
    "ch25-twogroups":        "set.seed(7); 15 per group, true difference 0.8",
    "ch25-outlier":          "set.seed(1); 19 clean values around 100 plus one 250",
    "ch27-bdi":              "set.seed(2026); 1200 people, 21 graded 0-3 items from one latent severity",
    "ch28-curiosity":        "set.seed(2026); twelve items secretly built from THREE factors",
    "ch29-missing":          "set.seed(2026); y missing more often when z is high (MAR)",
    "appendix-d":            "set.seed(1); 80 people in two groups, predictor x and outcome y",
    "appendix-items":        "set.seed(2); four items sharing the appendix predictor",
}


def book_data(name):
    """Load one of the book's datasets by name, with categories in book order."""
    d = pd.read_csv(f"{DATA_DIR}/{name}.csv")
    for col, levels in LEVELS.get(name, {}).items():
        d[col] = pd.Categorical(d[col], categories=levels)
    return d


def recipe(name):
    """Print how a dataset was built."""
    print(f"{name}: {RECIPE.get(name, 'no recipe recorded')}")


def datasets():
    """List every dataset the book ships."""
    return sorted(RECIPE)
