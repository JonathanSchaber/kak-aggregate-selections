# kak-aggregate-selections

This module provides simple arithmetic aggregation functions to apply on selections in the Kakoune editor.

It consists of the function `aggregate-selections`, which is globally aliased to `agg`.

The computations are carried out by GNU `bc`, so make sure your shell provides this program.


## Setup

Add `src/aggregate_selections.kak` to your `autoload/` directory, or copy the contents of the file to your `kakrc` directly.


## Usage

Select the numbers you want to aggregate and apply the needed function by invoking `agg` with the respective argument (to compute e.g. the sum of all selected numbers, type `:agg sum`).

The result will be shown in the info widget and is also sotred in the `r` register.
