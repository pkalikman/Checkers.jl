
#Checkers.jl Documentation 

    - [Testing Macros](index.md#Testing-Macros-1)
    - [Index](index.md#Index-1)


<a id='Testing-Macros-1'></a>

## Testing Macros

<a id='Checkers.@test_forall' href='#Checkers.@test_forall'>#</a>
**`Checkers.@test_forall`** &mdash; *Macro*.



```
@test_forall argument_data, prop
```

Check statement of proposition over all tuples of values of variables, specified in `argument_data`. Generate Pass/Fail/Error output for Base.Test. 

**Arguments**

  * `argument_data`: comma separated expression with arbitrarily many statements, containing information about ranges of variables. Statements must have form `x in iter`, where `x` is symbol and `iter` is any expression valid in `"for x in iter"` syntax used in construction of for-loops. In particular, `iter` can be `a:b`, where `a` & `b` are integer-valued expressions; or array/tuple-valued expression.
  * `prop` is boolean-valued expression for proposition to be checked for arguments in specified ranges (see Examples below).

**Details**

Code constructs a sequence of for-loops and checks that proposition evaluates to `true` for all values of variables specified. Equivalently, test is performed over cartesian product of ranges of variables.

Loops are generated from `argument_data` inductively: from outer-loop to inner-loop. If range of a variable depends on other variables, then their ranges must be defined in `argument_data` earlier.

#Examples

```julia
julia> @test_forall x in -1:1, x*(x-1)*(x+1) == 0
Test Passed
  Expression: (x in -1:1,x * (x - 1) * (x + 1) == 0)

julia> @test_forall x in -1:1, x*(x-2)*(x+1) == 0
Test Failed
  Expression: (x in -1:1,x * (x - 2) * (x + 1) == 0)

julia> @test_forall x in [0,1,2], y in x:4, (y+4>2*x)==true
Test Passed
  Expression: (x in [0,1,2],y in x:4,(y + 4 > 2x) == true)

julia> @test_forall x in (1-1,0+1,sqrt(4)), y in x:4, (y+4>2*x)==true
Test Passed
  Expression: (x in (1 - 1,0 + 1,sqrt(4)),y in x:4,(y + 4 > 2x) == true)

julia> @test_forall x in ["a","b"], y in ["z","w"], x*y in Set(["az","aw","bz","bw"])
Test Passed
  Expression: (x in ["a","b"],y in ["z","w"],x * y in Set(["az","aw","bz","bw"]))

# Bad design: throws UndefVarError: x not defined, because outer loop for y variable refers to the value of x coming after.
julia> @test_forall y in x:4,x in 0:2, (y+4>2*x)==true
Error During Test
  Test threw an exception of type UndefVarError
  Expression: (y in x:4,x in 0:2,(y + 4 > 2x) == true)
  UndefVarError: x not defined
```


<a target='_blank' href='https://github.com/pkalikman/Checkers.jl/tree/d1f4793bba5344e2836500683672f9c924d1a05a/src/./test-forall.jl#L1-L44' class='documenter-source'>source</a><br>

<a id='Checkers.@test_formany' href='#Checkers.@test_formany'>#</a>
**`Checkers.@test_formany`** &mdash; *Macro*.



```
@test_formany [ntests = 100] [maxtests = 1000] [logto = ""] [argument_data, proposition]
```

Takes proposition depending on some variables, generates sample of their values and tests the proposition. Returns `Pass` if proposition holds for all values in the sample, `Fail` if proposition does not hold for some value, and `Error` if a part of code could not be evaluated.

**Arguments**

Macro accepts a tuple of expressions that describe either statement of a test or specify optional keyword arguments.

Statement of a test must be a sequence of comma-separated expressions, where all but last expressions are read as `argument_data` and last statement is `proposition` depending on these arguments.

  * `argument_data` consists of arbitrarily many expressions containing

information about variables, their types and conditions on them. Expressions must have one of the following forms:

  * `a<x::T<b` or `a>x::T>b`, where middle variable `x` must be a symbol;

`T`  must be a type; bounds `a` & `b` can be arbitrary expressions;

  * `a<<x::T<b`, `a<x::T<<b`, `a>>x::T>b` or `a>x::T>>b`,

similar to the one above;

  * shorthand `x` instead of `x::T` may be used, e.g. `a<x<b`,

then type of variable defaults to `Float64`.

  * `proposition`: is the expression to be tested. Two types of propositions are allowed:

      * `proposition` of form `condition-->statement`, where `condition` and

    `statement` are boolean-valued expressions

      * `proposition` is boolean-valued expression itself

Optional keyword arguments include the following:

  * `ntests = 100`: number of tests that must be performed.
  * `maxtests = 1000`: maximal number of attempts to generate arguments

satisfying `condition`

  * `logto = "path_to_file"`: if provided then parsed as a path to file,

where log of tests will be recorded.

**Description**

Macro @test_formany is a test that attempts to generate sample of argument values of size `ntests` satisfying the `condition` if it is given. Then it checks whether the proposition holds for all elements in the sample. If number of attempts exceeds `maxtests` parameter before at least `ntests` values for arguments are generated, macro gives output `Base.Test.Error`.

If `proposition` is of form `condition-->statement` (see arguments list), then test checks whether implication holds. Namely, the test passes if whenever `condition` evaluates to `true` for generated argument values, then `statement` also evaluates to `true`.

If `proposition` is just a boolean-valued expression, code simply checks whether `prop` holds for generated values.

Some caution is required to avoid vacuous conditions. If test is unable to generate values satisfying the `condition` after `maxtests` attempts, output of the test is Base.Test.Error as mentioned before.

Default for optional keyword arguments is the following: `ntests = 100, maxtests = 1000`. If only `ntests` parameter is specified, `maxtests = 10*ntests`. If `logto = "path_to_file"` is given, log of test will be written to corresponding file,for example:

  * `@test_formany ntests = 10 maxtests = 1000  logto =  "./test_log.csv" 1<x::Float32<10, proposition`
  * `@test_formany ntests = 50 logto = "./test_log.csv" 1<x<10, proposition` ## maxtests = 500
  * `@test_formany logto = "./test_log.csv" 1<x<<Inf, proposition` ## ntests = 100; maxtests = 1000
  * `@test_formany ntests = 50 maxtests = 1000 1<x<10, proposition` ## not logged
  * `@test_formany 1<x::Int32<Inf, proposition logto = "./test_log.csv" maxtests = 1000 ntests = 10` ## order is not important

**Examples**

```julia
julia> @test_formany 100>x::Float64>10, x+10<y::Float64<<1000, y-5<z::Float64<Inf, z>x+5
Test Passed
  Expression: (:((100 > x::Float64 > 10,x + 10 < y::Float64 << 1000,y - 5 < z::Float64 < Inf,z > x + 5)),)

julia> @test_formany ntests = 1000 100>x::Float64>10, x+10<y::Float64<<1000, y-5<z::Float64<Inf, z>x+6
String["x = 25.18875813550991","y = 35.192306691353075","z = 31.183953098939906"]
Test Failed
  Expression: (:(ntests = 1000),:((100 > x::Float64 > 10,x + 10 < y::Float64 << 1000,y - 5 < z::Float64 < Inf,z > x + 6)))

## example of bad design for generators:
julia> @test_formany -1000<x::Float64<1000, x>999-->x+1>1000
Error During Test
  Test threw an exception of type ErrorException
  Expression: (:((-1000 < x::Float64 < 1000,$(Expr(:-->, :(x > 999), :(x + 1 > 1000))))),)
  Found only 1/100 values satisfying given condition.

## log is increasing
julia> @test_formany Inf>x::Float64>0,Inf>y::Float64>0, x<y-->log(x)<log(y) ntests = 1000
Test Passed
  Expression: (:((Inf > x::Float64 > 0,Inf > y::Float64 > 0,$(Expr(:-->, :(x < y), :(log(x) < log(y)))))),:(ntests = 1000))

## f(x) = x^3 is not convex on [-100,100]
julia> @test_formany 0<a<1,-100<x<100,-100<y<100,(a*x+(1-a)*y)^3<a*x^3+(1-a)*y^3
String["a = 0.39535367198058546","x = -13.538004569422625","y = 0.8504731053549079"]
Test Failed
  Expression: (:((0 < a < 1,-100 < x < 100,-100 < y < 100,(a * x + (1 - a) * y) ^ 3 < a * x ^ 3 + (1 - a) * y ^ 3)),)

## f(x) = x^3 is convex on [-100,100]
julia> @test_formany 0<a<1,0<x<100,0<y<100, (a*x+(1-a)*y)^3<=a*x^3+(1-a)*y^3
Test Passed
  Expression: (:((0 < a < 1,0 < x < 100,0 < y < 100,(a * x + (1 - a) * y) ^ 3 <= a * x ^ 3 + (1 - a) * y ^ 3)),)

## Cobb-Douglas utility function is concave
julia> function respects_concavity(f,t,x1,x2)
                  f(t*x1+(1-t)*x2) > t * f(x1) + (1-t) * f(x2)
              end

julia> function respects_weak_concavity(f,t,x1,x2)
                  f(t*x1+(1-t)*x2) >= t * f(x1) + (1-t) * f(x2)
              end

julia> function cobb_douglas(a,x)
                  prod(x.^a)
              end

# This passes the @test_formany, since probability of discovering a counter-example with a = .5 is zero.
julia> @test_formany 0<t<1, 0<a<1, 1<x1<10, 1<x2<10, 1<y1<10, 1<y2<10,respects_concavity(x -> cobb_douglas([a,1-a],x),t,[x1,y1],[x2,y2])
Test Passed
  Expression: (:((0 < t < 1,0 < a < 1,1 < x1 < 10,1 < x2 < 10,1 < y1 < 10,1 < y2 < 10,respects_concavity((x->begin  # REPL[5], line 1:
                    cobb_douglas([a,1 - a],x)
                end),t,[x1,y1],[x2,y2]))),)

julia> @test_formany 0<t<1, 0<a<1, 1<x1<10, 1<x2<10, 1<y1<10, 1<y2<10,respects_weak_concavity(x -> cobb_douglas([a,1-a],x),t,[x1,y1],[x2,y2])
Test Passed
  Expression: (:((0 < t < 1,0 < a < 1,1 < x1 < 10,1 < x2 < 10,1 < y1 < 10,1 < y2 < 10,respects_weak_concavity((x->begin  # REPL[6], line 1:
                    cobb_douglas([a,1 - a],x)
                end),t,[x1,y1],[x2,y2]))),)

## handling errors
julia> @test_formany -1<x<1, abs(log(x))>0
Error During Test
  Test threw an exception of type DomainError
  Expression: (:((-1 < x < 1,abs(log(x)) > 0)),)
  DomainError
```


<a target='_blank' href='https://github.com/pkalikman/Checkers.jl/tree/d1f4793bba5344e2836500683672f9c924d1a05a/src/./test-formany.jl#L1-L142' class='documenter-source'>source</a><br>

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


<a target='_blank' href='https://github.com/pkalikman/Checkers.jl/tree/d1f4793bba5344e2836500683672f9c924d1a05a/src/./test-exists.jl#L1-L40' class='documenter-source'>source</a><br>


<a id='Index-1'></a>

## Index

- [`Checkers.@test_exists`](index.md#Checkers.@test_exists)
- [`Checkers.@test_forall`](index.md#Checkers.@test_forall)
- [`Checkers.@test_formany`](index.md#Checkers.@test_formany)

