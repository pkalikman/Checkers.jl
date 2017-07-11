"""
    @test_forall argument_data, prop

Checks `prop` on each tuples of values specified in `argument_data`. 
Returns `Pass` if `prop` holds for all values tested,
`Fail` if `prop` does not hold for some tested value, 
and `Error` if a part of code could not be evaluated.

## Arguments

* `argument_data`: a sequence of at least one comma-separated expression(s),
  specifying the sets of values for individual variables.  
  Expressions must have the form `x in iter`, 
  where `x` is any symbol that will be treated as a dummy variable, 
  and `iter` is any iterable expression, 
  i.e. one valid in constructing a for loop: `"for x in iter"`.
  In particular, `iter` can be `a:b`, 
  where `a` & `b` are integer-valued expressions; an array; or a set.

* `prop` is boolean-valued expression of the proposition to be checked for
  arguments in specified ranges, 
  with reference to the dummy variables named in `argument_data`.

## Details

`@test_forall` constructs a nested sequence of for-loops,
and checks that `prop` evaluates to `true` 
for all combinations of values of variables specified by the loops. 
In set-theoretic terms, `@test_forall` tests 
`prop` on the Cartesian product of the sets of variables
specified in `argument_data`.

Loops are generated from `argument_data` inductively, 
starting with the outermost loop as the leftmost expression,
to the innermost loop as the rightmost. 
Variable ranges may depend on the values of previously referenced
variables (see third example).

## Examples

```julia
julia> @test_forall x in -1:1, x*(x-1)*(x+1) == 0
Test Passed
  Expression: (x in -1:1,x * (x - 1) * (x + 1) == 0)

julia> @test_forall x in -1:1, x*(x-2)*(x+1) == 0
Test Failed
  Expression: (x in -1:1,x * (x - 2) * (x + 1) == 0)

julia> @test_forall x in [0,1,2], y in x:4, y+4 > 2*x 
Test Passed
  Expression: (x in [0,1,2],y in x:4,(y + 4 > 2x) == true)

julia> @test_forall x in (1-1, 0+1, sqrt(4)), y in x:4, y+4 > 2*x
Test Passed
  Expression: (x in (1 - 1,0 + 1,sqrt(4)),y in x:4,(y + 4 > 2x) == true)

julia> @test_forall x in ["a","b"], y in ["z","w"], x*y in Set(["az","aw","bz","bw"])
Test Passed
  Expression: (x in ["a","b"],y in ["z","w"],x * y in Set(["az","aw","bz","bw"]))

# Bad design: throws UndefVarError: x not defined
# The outer loop for `y` refers to `x`, which comes later in `argument_data`.
julia> @test_forall y in x:4, x in 0:2, y+4 > 2*x
Error During Test
  Test threw an exception of type UndefVarError
  Expression: (y in x:4,x in 0:2,(y + 4 > 2x) == true)
  UndefVarError: x not defined
```
"""
macro test_forall(factex::Expr)
    ex = begin
        try
            if factex.head != :tuple
                error("Expression of unsupported format for @test_forall: $factex")
            end
            # Defining ex
            iterate = Expr(:block)
            for p in factex.args[1:(end-1)]
                #TODO: Rename these intelligibly
                key = p.args[2]
                val = p.args[3]
                push!(iterate.args,:($(esc(key))=$(esc(val))))
            end
            prop = 
                quote
                    res = res && $(esc(factex.args[end]))
                    if !res
                        fail_data = $(esc(factex.args[end]))
                        break
                    end
                end
            Expr(:for,iterate,prop)
        catch err
            quote
                throw($err)
            end
        end 
    end 
    quote
        res = true
        fail_data = false
        result = 
            try
                $ex
                if res
                    Pass(:test,$(Expr(:quote, factex)), nothing, nothing)
                else
                    Fail(:test,$(Expr(:quote, factex)), fail_data, nothing)
                end
            catch err
                Error(:test_error,$(Expr(:quote, factex)), err, catch_backtrace())
            end
        record(get_testset(), result)
    end
end
