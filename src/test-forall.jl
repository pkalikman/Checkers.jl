"""
    @test_forall argument_data, prop

Check statement of proposition over all tuples of values of variables, specified in `argument_data`. Generate Pass/Fail/Error output for Base.Test. 

# Arguments
* `argument_data`: comma separated expression with arbitrarily many statements, containing information about ranges of variables. Statements must have form `x in iter`, where `x` is symbol and `iter` is any expression valid in `"for x in iter"` syntax used in construction of for-loops. In particular, `iter` can be `a:b`, where `a` & `b` are integer-valued expressions; or array/tuple-valued expression.
* `prop` is boolean-valued expression for proposition to be checked for arguments in specified ranges (see Examples below).

# Details
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
"""
macro test_forall(factex::Expr)
  ex = begin
    try
    if factex.head != :tuple
        error("Expression of unsupported format for @test_forall: $factex")
    end
    # Defining ex
	iterate = :()		
	for p in factex.args[1:end-1]
		iterate = Expr(:block,iterate.args...,:($(esc(p.args[2]))=$(esc(p.args[3]))))
	end
	prop = quote
		res = res && $(esc(factex.args[end]))
		if !res
			fail_data = $(esc(factex.args[end]))
			break
		end
	end
	ex = Expr(:for,iterate,prop)
  catch err
    ex =
        quote
		throw($err)
        end
  end # try
  ex
  end # begin
    #println(ex)
    quote
	res = true
	fail_data = false
	result = try
          $ex
          res ? Pass(:test,$(Expr(:quote, factex)), nothing, nothing) :
                      Fail(:test,$(Expr(:quote, factex)), fail_data, nothing)
        catch err
          Error(:test_error,$(Expr(:quote, factex)), err, catch_backtrace())
        end
        record(get_testset(), result)
    end
end