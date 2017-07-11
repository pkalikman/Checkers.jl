"""
    @test_formany [ntests = 100] [maxtests = 1000] [logto = ""] argument_data, prop 

Checks `prop` on randomly generated samples values specified in `argument_data`. 
Returns `Pass` if `prop` holds for all values in the sample, 
`Fail` if `prop` does not hold for some sampled value, 
and `Error` if a part of the code could not be evaluated
or if insufficient non-vacuous tests are generated.

## Arguments

* `argument_data`:
  a sequence of comma-separated expressions, 
  where each expression specifies
  a dummy variable, a universe from which to sample it,
  and a restricted comprehension of that universe.
  In particular, expressions must have one of the following forms:

  * `a<x::T<b` or `a>x::T>b`, where `x` is any symbol, treated as a dummy
    variable; `T` is a type; `a` & `b` are arbitrary expressions to constrain
    the range of values for `x` (provided that `a<x::T<b` is meaningful
    given `T` and the types of `a` and `b`);
  * `a<<x::T<b`, `a<x::T<<b`, `a>>x::T>b` or `a>x::T>>b`,
    as above, but where using `<<` will instruct `@test_formany`
    to generate test cases *away* from that boundary, i.e. closer 
    to the other boundary;
  * `a<x<b` etc., where the type `T` is omitted,
    and therefore defaults to `Float64`


* `prop`: the property to be tested. Two types of properties are allowed:

  * any boolean-valued expression, referencing the dummy variables defined
    in `argument_data`, or
  * a property of the form `antecedent --> consequent`, 
    where `antecedent` and `consequent` are themselves
    boolean-valued expressions that may reference dummy variables
    defined in `argument_data`. This form is useful for 
    expressing "if-then" relationships without thinking through 
    how to generate test cases that satisfy the antecedent,
    as `@test_formany` will do this for you; see below for more detail.

Optional keyword arguments include the following:

* `ntests = 100`: the number of tests that `test_formany` will perform
before returning `Pass`.

* `maxtests = 1000`: the maximal number of times to attempt to generate 
test cases that satisfy `antecedent`, when the `antecedent --> consequent`
form is used.

* `logto = "path_to_file"`: the path to a file to which
a log of the actual test cases used will be recorded.
Since `@test_formany` is pseudo-random and might pass a test that you
expect to fail (or vice versa), this can be useful
for debugging to see which actual test cases were tested.

## Details

`@test_formany` generates a sample of test cases based on `argument_data`, 
and tests `prop` on these values, returning `Pass` only if every test passes.

### Basic Use

When `prop` is just a boolean-valued expression,
`@test_formany` simply checks whether `prop` holds for the values
generated according to `argument_data`.

### Advanced Use: Conditional Properties and Vacuity Avoidance

When using `ntests = [some integer]`, with a `prop` of the form `antecedent --> consequent`,
`@test_formany` will attempt to test `ntests` cases where the
conditional is *not* vacuous, i.e. `ntests` cases where `antecedent`
evaluates to true. 
However, to prevent the test from looping infinitely,
`@test_formany` uses `maxtests = [some integer]` 
to limit the number of total attempts it will make.

Consider the following example: you might wish to test
this statement:

    ∀ 0 < x < 1, x^2 < 0.0001 --> x < 0.01

If you simply tested this statement with 100 randomly sampled
values between 0 and 1, you would be unlikely actually ever 
to evaluate the consequent of the conditional,
because most of the time x^2 < 0.0001 would not be true.
So, you could use 

    @test_formany ntests=100 0 < x::Float64 < 1, x^2 < 0.0001 --> x < 0.01

to guarantee 100 tests where `x^2 < 0.0001` was true.

However, by the same reasoning, you might actually be testing
an expression for which the antecedent is itself virtually always false.
Then you don't want the tests to continue forever---you want to specify
an upper bound on how many tests `@test_formany` should run before
it gives up.
For example, using `maxtests` in this case
prevents `@test_formany` from looping infinitely 
looking for a value that satisfies an impossible antecedent:

    @test_formany ntests=100 maxtests=10_000 0 < x::Float64 < 1, (x < 1 && x > 2) --> x < 0.01

In this case, if the number of attempts to satisfy the antecedent
exceeds `maxtests` before `ntests` tests *do* satisfy the antecedent,
then `@test_formany` will return `Base.Test.Error`.

### Keyword Argument Defaults

- If no keywords are specified, `@test_formany` assumes `ntests = 100, maxtests = 1000`.
- If only `ntests` is specified, `@test_formany` assumes `maxtests = 10*ntests`. 
- By default, `@test_formany` does *not* log output

Keyword arguments are order-invariant.

### Exhaustion

`@test_formany` tests a random sample of values specified
by `argument_data`, which in typical use will imply that it
tests a random sample of values drawn from a mathematically infinite
set. 
Consequently, `@test_formany` is not exhaustive,
and can therefore generate false positives,
i.e. cases that generate `Pass` even when a counter-example
exists.

A similar and more complicated concern applies when using
conditional properties.
Here, the vacuity-avoidance arguments `ntests` and `maxtests`
may result in false positives and false negatives:
a conditional that is true, but with an unlikely-to-satisfy antecedent, 
mail fail to generate enough test cases to test the entire
conditional, and therefore return `Error` even when the 
property is true for the entire universe.
On the other hand, a counter-example may still
exists even when `@test_formany` returns `Pass`
on a conditional property after testing many non-vacuous antecedents.

## Examples

```julia
julia> @test_formany 100 > x::Float64 > 10, x+10 < y::Float64 << 1000, y-5 < z::Float64 < Inf, z > x+5
Test Passed
  Expression: (:((100 > x::Float64 > 10,x + 10 < y::Float64 << 1000,y - 5 < z::Float64 < Inf,z > x + 5)),)

julia> @test_formany ntests = 1000 10 < x::Float64 < 100, x+10 < y::Float64 << 1000, y-5 < z::Float64 < Inf, z > x+6
String["x = 25.18875813550991","y = 35.192306691353075","z = 31.183953098939906"]
Test Failed
  Expression: (:(ntests = 1000),:((100 > x::Float64 > 10,x + 10 < y::Float64 << 1000,y - 5 < z::Float64 < Inf,z > x + 6)))

## Failing to find enough non-vacuous test cases:
julia> @test_formany -1000 < x::Float64 < 1000, x > 999 --> x+1 > 1000
Error During Test
  Test threw an exception of type ErrorException
  Expression: (:((-1000 < x::Float64 < 1000,$(Expr(:-->, :(x > 999), :(x + 1 > 1000))))),)
  Found only 1/100 values satisfying given antecedent.

## Test that `log` is an increasing function
julia>  @test_formany ntests=1000 Inf > x::Float64 > 0, Inf > y::Float64 > 0, x < y --> log(x) < log(y)
Test Passed
  Expression: (:((Inf > x::Float64 > 0,Inf > y::Float64 > 0,$(Expr(:-->, :(x < y), :(log(x) < log(y)))))),:(ntests = 1000))

## Test that f(x) = x^3 is convex on (-100,100) 
## Fails, because f(x) = x^3 is not convex on that interval!
julia> @test_formany 0 < a < 1,-100 < x < 100,-100 < y < 100,(a*x + (1-a)*y)^3 < a*x^3 + (1-a)*y^3
String["a = 0.39535367198058546","x = -13.538004569422625","y = 0.8504731053549079"]
Test Failed
  Expression: (:((0 < a < 1,-100 < x < 100,-100 < y < 100,(a * x + (1 - a) * y) ^ 3 < a * x ^ 3 + (1 - a) * y ^ 3)),)

## Test that f(x) = x^3 is convex on (0,100)
julia> @test_formany 0<a<1,0<x<100,0<y<100, (a*x+(1-a)*y)^3<=a*x^3+(1-a)*y^3
Test Passed
  Expression: (:((0 < a < 1,0 < x < 100,0 < y < 100,(a * x + (1 - a) * y) ^ 3 <= a * x ^ 3 + (1 - a) * y ^ 3)),)

## Test that Cobb-Douglas Utility is concave:
## First, define a helper function for concavity testing
julia> function respects_concavity(f,t,x1,x2)
                  f(t*x1+(1-t)*x2) > t * f(x1) + (1-t) * f(x2)
              end
## Same for weak concavity
julia> function respects_weak_concavity(f,t,x1,x2)
                  f(t*x1+(1-t)*x2) >= t * f(x1) + (1-t) * f(x2)
              end
## And one for Cobb-Douglas
julia> function cobb_douglas(a,x)
                  prod(x.^a)
              end

## The test below passes the @test_formany, 
## since the probability of discovering a counter-example is zero.
julia> @test_formany 0<t<1, 0<a<1, 1<x1<10, 1<x2<10, 1<y1<10, 1<y2<10, respects_concavity(x -> cobb_douglas( [a,1-a], x), t, [x1,y1], [x2,y2])
Test Passed
  Expression: (:((0 < t < 1,0 < a < 1,1 < x1 < 10,1 < x2 < 10,1 < y1 < 10,1 < y2 < 10,respects_concavity((x->begin  # REPL[5], line 1:
                    cobb_douglas([a,1 - a],x)
                end),t,[x1,y1],[x2,y2]))),)

julia> @test_formany 0 < t < 1, 0 < a < 1, 1 < x1 < 10, 1 < x2 < 10, 1 < y1 < 10, 1 < y2 < 10,respects_weak_concavity(x -> cobb_douglas( [a,1-a], x), t, [x1,y1], [x2,y2])
Test Passed
  Expression: (:((0 < t < 1,0 < a < 1,1 < x1 < 10,1 < x2 < 10,1 < y1 < 10,1 < y2 < 10,respects_weak_concavity((x->begin  # REPL[6], line 1:
                    cobb_douglas([a,1 - a],x)
                end),t,[x1,y1],[x2,y2]))),)

## Handling Errors
julia> @test_formany -1 < x < 1, abs( log(x) ) > 0
Error During Test
  Test threw an exception of type DomainError
  Expression: (:((-1 < x < 1,abs(log(x)) > 0)),)
  DomainError
```
"""
macro test_formany(exprs...)
    outex = Expr(:macrocall, Symbol("@test_cases"))
    for ex in exprs
        push!(outex.args, esc(ex))
    end
    ex1 = Expr(:(=), :mode, :test_formany)
    push!(outex.args, esc(ex1))
    return outex
end
