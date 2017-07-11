# Checkers 🏁 🏁 Documentation

```@meta
CurrentModule = Checkers
```

## Introduction

Automated testing macros
inspired by a [Julia implementation](https://github.com/pao/QuickCheck.jl)
of Koen Claessen and John Hughes' [QuickCheck](http://www.cse.chalmers.se/~rjmh/QuickCheck/)
property-based randomized tester.

Checkers lets you write quick property-based tests:

    julia> using Checkers
    julia> f(x) = x^2
    julia> @test_formany -10<x<10, f(x) >= 0
    Test Passed
      Expression: (:((-10 < x < 10, f(x) >= 0)), :(mode = test_formany))

    julia> @test_forall x in -10:10, f(x) >= 0
    Test Passed
      Expression: (x in -10:10, f(x) >= 0)
        @test_forall x in 0:10, f(x) >= 0

    julia> @test_forall x in -10:10, f(x) > 0 #Should fail b/c f(0) = 0
    Test Failed
      Expression: (x in -10:10, f(x) > 0)
    ERROR: There was an error during testing


## Quickstart Guide

This package provides three macros for test generation:

1. `@test_forall`
2. `@test_formany`
3. `@test_exists`

In each case, the basic format is

    @[test] [set of values to test] [property to test]

The *property* is any expression that evaluates to a boolean,
making reference to some dummy variable specified in the set of values
to test.

The macros differ in how they specify and choose values to test:

- Use `@test_forall` when you can specify the exact *finite set* of values to 
  test. 
  For example, `-3:3` specifies the exact set of 7 Int64 values,
  {-3,-2,-1,0,1,2,3}, on which you wish to test the property.
  Because the user specifies the test universe completely,
  and that universe is finite,
  every value is tested and @test_forall returns only true positives
  and true negatives.

- Use `@test_formany` when you wish to specify a (possibly infinite) set of values 
  to test by restricted comprehension from some universe. 
  For example, `-3 < x::Float64 < 3` specifies that some number of `Float64`s `x`,
  satisfying the condition `-3 < x < 3`, will be tested for the property.
  Note that `@test_formany` is meant to capture the idea of the universal 
  quantifier, but is not universal on infinite sets, 
  since the package will only run a finite number of tests.
  That is, `@test_formany` may return a false positive, as it cannot
  be comprehensive. It will not, however, return a false negative.

- Use `@test_exists` like `@test_formany`, but when you wish the test to pass when 
  at least one value satisfies the property, rather than when all tested
  values satisfy the property.
  Like `@test_formany`, `@test_exists` *simulates* the existential quantifier,
  but is not strictly speaking complete. 
  That is, `@test_exists` may return a false negative, in the case that
  a value exists but was not lucky enough to be tested.
  It will not, however, return a false positive.

## The Macros in More Detail

`@test_forall` takes an expression specifying one or more dummy variables,
discrete sets of values for those variables, and an expression, and tests the
expression substituting every combination of the variables 
(the Cartesian product of their possible value sets). 
(Since Julia 0.5,
`@test_forall x in [Collection], P(x)` is quite similar to 
`@test for x in [Collection] P(x) end`,
and we may deprecate / remove it for that reason.)

The property may be a conditional expression such as `P(x) --> Q(x)`,
in which case truth may be vacuous when `P(x)` is false `\forall x` tested.

`@test_formany` functions like `@test_forall`, but allows quantifying over
infinite sets such as `[a,b] \subset \mathbb R`, etc. by sampling these
sets uniformly at random. It provides additional modifiers to control
how many tests it runs, which are especially helpful for ensuring
that conditional-expression tests are not only passed vacuously.

`@test_exists X` is essentially shorthand for `! (@test_formany !X)`.

### Exhaustion

Note that `@test_formany` and `@test_exists` are not strictly speaking exhaustive
or true universal/existential quantifiers. `@test_formany x Expr(x)` may pass
even when `\exists x` s.t. `Expr(x)` is false, and `@test_exists x Expr(x)` may
fail even under the same circumstances. However, `@test_forall` is exhaustive.

Tests that do not exhaust their universe take additional keyword arguments 
`ntests` and `maxtests` to control how many tests to run.

### Examples

Basic usage:

    @test_forall  x in 1:5,  x^2 < 30
    @test_formany 1 < x < 5, x^2 < 30
    @test_exists  1 < x < 5, x^2 < 30
    
Control how many tests in `@test_formany`:

    @test_formany ntests = 10_000  1 < x < 5, x^2 < 30
    
Test a conditional property, passing only if 100 of the tests are not vacuous:

    @test_formany ntests = 100  0 < x < Inf, 0 < y < Inf,  x < y --> log(x)<log(y)
  
Test a conditional property, passing only if 100 of the tests are not vacuous, but only allow 100 tests:

    @test_formany ntests = 100 maxtests = 100  0 < x < 10,  0 < y < 10,  x < y --> x^2 < y^2
    
Test a conditional property, passing only if 100 of the test are not vacuous, but allow 100,000 tests:

    @test_formany ntests = 100 maxtests = 100_000 0 < x < 10,  0 < y < 10,  x < y --> x^2 < y^2

Note that while the former (`maxtests=100`) usually fails, the latter (`maxtests=100_000`) passes. 
This is because `@test_formany` generates 100 random pairs of `(x,y)`, but not all of them
are likely to satisfy `x < y`. Therefore when `maxtests=100`, it will not generate
enough pairs to test the consequent of the conditional expression.

See `?@test_forall`, etc. and `examples/examples.jl` for more detailed information. 

### Logging

Test logging is available in `@test_formany` to see which values were actually tested
by using the keyword `logto` and supplying an output path:

    @test_formany logto = "tests.csv" 1<x<5, x^2 < 30

### Output

Test macros output results of type `Base.Test.Pass`, `Base.Test.Fail`, 
or `Base.Test.Error` in order to function seamlessly with `Base.Test.@testset`.

    @testset "Multiple tests" begin 
        @test_forall x in 1:5, x^2 < 30
        @test_forall x in 1:6, x^2 < 30
    end

## See Also

Also of note are these more comprehensive (and we feel complicated) packages. 
Our goal is to provide a lightweight, ready-to-use out-of-the-box alternative:

- [BaseTestAuto](https://github.com/robertfeldt/BaseTestAuto.jl)
- [DataGenerators](https://github.com/simonpoulding/DataGenerators.jl)

## License

The Checkers.jl package is licensed under the MIT "Expat" License:

Copyright (c) 2017: Efim Abrikosov & Philip Kalikman.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Credits

This package was co-designed and co-written by 
[Efim Abrikosov](https://github.com/flomastruk) and 
[Philip Kalikman](https://github.com/pkalikman/)
while each was a graduate student at Yale University.

- Efim wrote the majority of the code,
  which is based on but does not directly use [the work of Patrick
  O'Leary](https://github.com/pao/QuickCheck.jl)

- Philip designed the majority of the functionality and syntax,
  building on [the work (in Haskell) of Koen Classen and John
  Hughes](http://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)


## Index

```@index
```
