"""
    @test_exists [ntests = 100] [maxtests = 1000] [logto = ""] argument_data, prop 

Checks `prop` on randomly generated samples values specified in `argument_data`. 
Returns `Pass` if `prop` holds for at least one value in the sample, 
`Fail` if `prop` fails to hold for all sampled values, 
and `Error` if a part of the code could not be evaluated
or if insufficient non-vacuous tests are generated.


## Description

`@test_exists` is to `@test_formany` as the existential quantifier
is to the universal quantifier.
That is, 

    ( @test_exists x ∈ X, P(x)  ) == !( @test_formany x ∈ X, !P(x) )   

Consequently, the same concerns with vacuity avoidance apply.
Additionally, analogous concerns with false positivity 
apply: where `@test_formany` may falsely validate a property
by not exhausting its implicit test universe,
`@test_exists` may falsely *in*validate a property
by not exhausting its implicit search universe.

## Examples

```julia
julia> @test_exists ntests = 1000 -10 < x < 10, x^2 > 99
String["x = -9.966560160994264"]
Test Passed
  Expression: (:(ntests = 1000),:((-10 < x < 10,x ^ 2 > 99)))

## Here, the values of x, y, and z are generated independently, 
## so a conditional statement with an antecedent that checks for
## order is necessary: 
julia> @test_exists ntests = 1000 0 < x < 2*pi, 0 < y < 2*pi, 0 < z < 2*pi, x < y < z --> sin(x) < sin(y) < sin(z) 
String["x = 0.3082312611033726","y = 0.49557010329840206","z = 2.5966119472766076"]
Test Passed
  Expression: (:((0 < x < 2pi,0 < y < 2pi,0 < z < 2pi,$(Expr(:-->, :(x < y < z), :(sin(x) < sin(y) < sin(z)))))),:(ntests = 1000))

## By contrast, here, x, y, and z are generated with sequential 
## reference to the previously generated value(s), 
## so they satisfy x<y<z automatically.
## No conditional is needed.
julia> @test_exists 0<x<2*pi, x<y<2*pi, y<z<2*pi, sin(x)<sin(y)<sin(z)
String["x = 5.787034350107664","y = 6.23560263220101","z = 6.26802436856299"]
Test Passed
  Expression: (:((0 < x < 2pi,x < y < 2pi,y < z < 2pi,sin(x) < sin(y) < sin(z))),)

## This returns Error, because the antecedent is too restrictive
## to generate 100 non-vacuous tests:
@test_exists ntests = 100 0 < x < 1000, x > 990 --> x > 999.9 
Error During Test
  Test threw an exception of type ErrorException
  Expression: (:((0 < x < 1000,$(Expr(:-->, :(x > 990), :(x > 999.9))))),:(ntests = 100))
  Found only 14/100 values satisfying given condition.
```
"""
macro test_exists(exprs...)
    outex = Expr(:macrocall, Symbol("@test_cases"))
    for ex in exprs
        push!(outex.args, esc(ex))
    end
    ex1 = Expr(:(=), :mode, :test_exists)
    push!(outex.args, esc(ex1))
    return outex
end
