# kak-aggregate-selections

This module provides simple arithmetic aggregation functions to apply
on selections in the Kakoune editor (ATM only decimal arithmetics is
supported).

A typical use case might be if you are editing a markdown table in
Kakoune which has columns containing numbers; at some point you might
wonder what the numbers in a certain column (or columns) add up to.
`aggregate-selections` provides the needed functionality for you:
Select the numbers/expressions[^1] you want to aggregate and apply the
needed function by invoking `agg` with the respective argument (to
compute e.g. the sum of all selected numbers, type `:agg sum<ret>`,
or just `:agg<ret>` since no argument defaults to `sum`).

The result is shown in the info widget (rounded) and it is also stored
into the `r` register (precise).

The module consists of the function `aggregate-selections`, which is
globally aliased to `agg`.

The computations are carried out by GNU `bc`, so make sure your shell
invoked by Kakoune provides this program.


## Setup

Add `src/aggregate_selections.kak` to your `autoload/` directory, or
copy the contents of the file to your `kakrc` directly.


[^1]: `aggregate-selections` is implemented to evaluate arithmetic
expressions inside selections: Thus, a `sum` aggregation on to
selections A `100` and B `50+50` yields `200`. For `bc` to be able
to evaluate selected numbers/expressions, `aggregate-selections`
removes all characters which are **not** a number, a `.`, or one
of the operators `+`, `-`, `*`, `/`, `^`. Therefore, you don't
need to pedantically crop your selections or remove 10k-separators
not processable by `bc` (`,`, `'`, ` ` and the like).

