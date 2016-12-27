# Checkers.jl

[![Build Status](https://travis-ci.org/pkalikman/Checkers.jl.svg?branch=master)](https://travis-ci.org/pkalikman/Checkers.jl)
[![Join the chat at https://gitter.im/Checkers-jl/Lobby](https://badges.gitter.im/Checkers-jl/Lobby.svg)](https://gitter.im/Checkers-jl/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Automated testing macros
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

The Checkers.jl package is licensed under the MIT "Expat" License:

Copyright (c) 2016: Efim Abrikosov & Philip Kalikman.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Credits

This package was co-designed and co-written by 
[Efim Abrikosov](https://github.com/flomastruk) and [Philip Kalikman](https://github.com/pkalikman/)
while each was a graduate student at Yale University.

- Efim wrote the majority of the code,
building on [the work of Patrick O'Leary](https://github.com/pao/QuickCheck.jl)

- Philip designed the majority of the functionality and syntax,
building on [the work (in Haskell) of Koen Classen and John Hughes](http://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)
