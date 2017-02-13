
<a id='@test_exists-1'></a>

# @test_exists

<a id='Checkers.@test_exists' href='#Checkers.@test_exists'>#</a>
**`Checkers.@test_exists`** &mdash; *Macro*.



```
@test_exists [ntests = 100][maxtests = 1000][logto = ""][argument_data, prop]
```

Generates sample of values for arguments in proposition. Returns `Pass` if proposition holds for at least one value in the sample, `Fail` if proposition does not hold for any values, and `Error` if a part of code could not be evaluated. `Error` is given if after `maxtests` attempts to generate argument values, number of arguments satisfying `condition` part of `prop` is less than `ntests`.

**Description**

Similar to `@test_formany`, see it's documentation for details.

**Examples**

```julia
julia> @test_exists ntests = 1000 -10<x<10, x^2>99
String["x = -9.966560160994264"]
Test Passed
  Expression: (:(ntests = 1000),:((-10 < x < 10,x ^ 2 > 99)))

## values are generated successively in the oder x->y->z, they satisfy x<y<z automatically
julia> @test_exists 0<x<2*pi, x<y<2*pi, y<z<2*pi, sin(x)<sin(y)<sin(z)
String["x = 5.787034350107664","y = 6.23560263220101","z = 6.26802436856299"]
Test Passed
  Expression: (:((0 < x < 2pi,x < y < 2pi,y < z < 2pi,sin(x) < sin(y) < sin(z))),)

## values are generated independently, the statement is checked only for those that satisfy x<y<z
julia> @test_exists 0<x<2*pi, 0<y<2*pi, 0<z<2*pi, x<y<z --> sin(x)<sin(y)<sin(z) ntests = 1000
String["x = 0.3082312611033726","y = 0.49557010329840206","z = 2.5966119472766076"]
Test Passed
  Expression: (:((0 < x < 2pi,0 < y < 2pi,0 < z < 2pi,$(Expr(:-->, :(x < y < z), :(sin(x) < sin(y) < sin(z)))))),:(ntests = 1000))

## Gives Error, because condition is too restrictive
@test_exists 0<x<1000, x>990 --> x>999.9 ntests = 100
Error During Test
  Test threw an exception of type ErrorException
  Expression: (:((0 < x < 1000,$(Expr(:-->, :(x > 990), :(x > 999.9))))),:(ntests = 100))
  Found only 14/100 values satisfying given condition.
```


<a target='_blank' href='https://github.com/pkalikman/Checkers.jl/tree/f5b596a843039997e2852cb6148188cab23992ac/src/./test-exists.jl#L1-L40' class='documenter-source'>source</a><br>

