# Checkers.jl

Automated testing
inspired by the [Julia implementation](https://github.com/pao/QuickCheck.jl)
of Koen Claessen and John Hughes' [QuickCheck](http://www.cse.chalmers.se/~rjmh/QuickCheck/)
property-based randomized tester.


## Test Generating Macros

This package provides three macros for test generation:

1. `@test_forall`
2. `@test_formany`
3. `@test_exists`

`@test_forall` takes an expression specifying one or more dummy variables,
discrete sets of values for those variables, and an expression, and tests the
expression substituting every combination of the variables 
(the Cartesian product of their possible value sets).

`@test_formany` functions like `@test_forall`, but allows quantifying over
infinite sets such as `[a,b] \subset \mathbb R`, etc. by sampling these
sets uniformly at random. It provides additional modifiers to control
how many tests it runs.

`@test_exists X` is essentially shorthand for `! (@test_formany !X)`.

Note that `@test_formany` and `@test_exists` are not strictly speaking exhaustive
or true universal/existential quantifiers. `@test_formany x Expr(x)` may pass
even when `\exists x` s.t. `Expr(x)` is false, and `@test_exists x Expr(x)` may
fail even under the same circumstances.

However, `@test_forall` is exhaustive.

### Output

The output of test macros has type `Base.Test.Pass`, `Base.Test.Fail`, 
or `Base.Test.Error`, and so as to function seamlessly with `Base.Test.@testset`.

### Logging

Test logging is also available.

## Detailed Documentation

See `?@test_forall`, etc. and `examples/examples.jl` for more detailed information. 

## License

Add note about MIT License.

## Credits

Documentation of QuickCheck can be found on [Read The Docs](https://quickcheckjl.readthedocs.org/en/latest/).

