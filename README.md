# Checkers.jl

An automated testing package
based on the [Julia implementation](https://github.com/pao/QuickCheck.jl)
of Koen Claessen and John Hughes'
[QuickCheck](http://www.cse.chalmers.se/~rjmh/QuickCheck/) property-based
randomized tester,
with additional syntactic sugar and convenient generators.

## Documentation
Documentation of QuickCheck can be found on [Read The Docs](https://quickcheckjl.readthedocs.org/en/latest/).

*This* README provides documentation of the additional features in **Checkers.jl**.

## New Macros

This version provides new macros `@test_exists`, `@test_formany`, `@test_forall`. 
They take expressions of specific forms, parse them, automatically define
corresponding generators for argument variables, and run tests.
Optional argument can be given to specify number of tests. 
Output has type `Base.Test.Pass`, `Base.Test.Fail` or `Base.Test.Error` and is adapted to work with `@testset` macro from `Base.Test`. Test logging is available.

See inlined documentation and `examples/examples.jl` for more detailed information. 
