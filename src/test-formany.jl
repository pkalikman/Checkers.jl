"""
    @test_formany [ntests = 100] [maxtests = 1000] [logto = ""] [argument_data, proposition]

Takes proposition depending on some variables, generates sample of their values
and tests the proposition. Returns `Pass` if proposition holds for all values
in the sample, `Fail` if proposition does not hold for some value, and `Error`
if a part of code could not be evaluated.

# Arguments

Macro accepts a tuple of expressions that describe either statement of a test
or specify optional keyword arguments.

Statement of a test must be a sequence of comma-separated expressions, where
all but last expressions are read as `argument_data` and last statement is
`proposition` depending on these arguments.

* `argument_data` consists of arbitrarily many expressions containing
information about variables, their types and conditions on them. Expressions
must have one of the following forms:

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

# Description
Macro @test_formany is a test that attempts to generate sample of argument values
of size `ntests` satisfying the `condition` if it is given. Then it checks whether
the proposition holds for all elements in the sample. If number of attempts
exceeds `maxtests` parameter before at least `ntests` values for arguments
are generated, macro gives output `Base.Test.Error`.

If `proposition` is of form `condition-->statement` (see arguments list),
then test checks whether implication holds. Namely, the test passes if whenever
`condition` evaluates to `true` for generated argument values, then `statement`
also evaluates to `true`.

If `proposition` is just a boolean-valued expression, code simply checks whether
`prop` holds for generated values.

Some caution is required to avoid vacuous conditions. If test is unable to
generate values satisfying the `condition` after `maxtests` attempts, output
of the test is Base.Test.Error as mentioned before.

Default for optional keyword arguments is the following: `ntests = 100, maxtests = 1000`.
If only `ntests` parameter is specified, `maxtests = 10*ntests`. If
`logto = "path_to_file"` is given, log of test will be written to corresponding
file,for example:

* `@test_formany ntests = 10 maxtests = 1000  logto =  "./test_log.csv" 1<x::Float32<10, proposition`
* `@test_formany ntests = 50 logto = "./test_log.csv" 1<x<10, proposition` ## maxtests = 500
* `@test_formany logto = "./test_log.csv" 1<x<<Inf, proposition` ## ntests = 100; maxtests = 1000
* `@test_formany ntests = 50 maxtests = 1000 1<x<10, proposition` ## not logged
* `@test_formany 1<x::Int32<Inf, proposition logto = "./test_log.csv" maxtests = 1000 ntests = 10` ## order is not important

# Examples
```julia
julia> @test_formany 100>x::Float64>10, x+10<y::Float64<<1000, y-5<z::Float64<Inf, z>x+5
Test Passed
  Expression: (:((100 > x::Float64 > 10,x + 10 < y::Float64 << 1000,y - 5 < z::Float64 < Inf,z > x + 5)),)

julia> @test_formany ntests = 1000 100>x::Float64>10, x+10<y::Float64<<1000, y-5<z::Float64<Inf, z>x+6
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
"""
macro test_formany(exprs...)
   inner_ex = try
	maxtests = 0; ntests = 0
	prop = :(); cond = :()
	logging  = ""
	var_data = Array(Any,1,6)
	for ex in exprs
		if isa(ex, Expr) && ex.head == :tuple
			var_data = parse_argument_data(ex)
			if ex.args[end].head == :-->
				prop = ex.args[end].args[2]
				cond = ex.args[end].args[1]
			else
				prop = ex.args[end]
				cond = true
			end
		elseif isa(ex, Expr) && ex.head == :(=)
			if ex.args[1] == :ntests
				ntests = ex.args[2]
			elseif ex.args[1] == :maxtests
				maxtests = ex.args[2]
			elseif ex.args[1]== :logto
				logging = ex.args[2]
			else
				error("Invalid macro input $ex.")
			end
		else
			error("Invalid macro input $ex.")
		end
	end
	if ntests == 0
		ntests = 100
	end
	if maxtests == 0
		maxtests = 10*ntests
	end
	num_of_vars = size(var_data,1)
	generate_values = :()
	values = :([])
	for i in 1:num_of_vars
		next_expr = :($(esc(var_data[i,1]))=
			   custom_generator($(esc(var_data[i,2])),$(esc(var_data[i,3])),
			      $(esc(var_data[i,4])),$(esc(var_data[i,5])),$(esc(var_data[i,6])))(div(n,2)+3))
		generate_values = Expr(:block,generate_values.args...,next_expr)
		values = Expr(:vect, values.args..., :($(esc(var_data[i,1]))))
	end
#####
	if logging == ""    ## no logging
		inner_ex = quote try
			for n in 1:$maxtests
				$generate_values
				if $(esc(cond))
					num_good_args += 1
					res = res && $(esc(prop))
					if !res
						fail_data = $(esc(prop))
						break
					end
					if num_good_args >= $ntests
						break
					end
				end
			end
		        # no counter-example but insufficient amount of tests
			if res && num_good_args<$ntests
				nt = $ntests
 				error("Found only $num_good_args/$nt values satisfying given condition.")
			end
			res ? Pass(:test,$(Expr(:quote, exprs)), nothing, nothing) :
		   	   Fail(:test,$(Expr(:quote, exprs)), fail_data, nothing)
		catch err
			Error(:test_error,$(Expr(:quote, exprs)), err, catch_backtrace())
		end end #quote #try
	else 		## logging is a path to file where the log is written to
		inner_ex = quote try
			log_file = open($logging,"a")
			writedlm(log_file,reshape([string(s) for s in $(var_data[:,1])],(1,$num_of_vars)),",")
			for n in 1:$maxtests
				$generate_values
				if $(esc(cond))
					num_good_args += 1
					res = res && $(esc(prop))
					writedlm(log_file,transpose(push!(convert(Vector{Any},$values),res)),",")
					if !res
						fail_data = $(esc(prop))
						break
					end
					if num_good_args >= $ntests
						break
					end
				end
			end
			close(log_file)
		        # no counter-example but insufficient amount of tests
			if res && num_good_args<$ntests
				nt = $ntests
 				error("Found only $num_good_args/$nt values satisfying given condition.")
			end
			res ? Pass(:test,$(Expr(:quote, exprs)), nothing, nothing) :
		   	   Fail(:test,$(Expr(:quote, exprs)), fail_data, nothing)
		catch err
			Error(:test_error,$(Expr(:quote, exprs)), err, catch_backtrace())
		end end #quote #try
	end
	inner_ex
#####
   catch err
	inner_ex = quote
		Error(:test_error,$(Expr(:quote, exprs)), $err, catch_backtrace())
	end
   end # try defining inner_ex
	return quote
		num_good_args = 0
		res = true
		fail_data = false
		result = $inner_ex
		record(get_testset(), result)
	end
end
