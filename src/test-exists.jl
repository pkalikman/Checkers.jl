"""
    @test_exists [ntests = 100][maxtests = 1000][logto = ""][argument_data, prop]


Generates sample of values for arguments in proposition. Returns `Pass`
if proposition holds for at least one value in the sample, `Fail` if proposition
does not hold for any values, and `Error` if a part of code could not
be evaluated. `Error` is given if after `maxtests` attempts to generate
argument values, number of arguments satisfying `condition` part of `prop`
is less than `ntests`.

# Description
Similar to `@test_formany`, see it's documentation for details.

# Examples
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
"""
macro test_exists(exprs...)
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
	generate_values = Expr(:block)
	values = Expr(:vect)
	for i in 1:num_of_vars
		next_expr = :($(esc(var_data[i,1]))=
			   custom_generator($(esc(var_data[i,2])),$(esc(var_data[i,3])),
			      $(esc(var_data[i,4])),$(esc(var_data[i,5])),$(esc(var_data[i,6])))(div(n,2)+3))

        push!(generate_values.args, next_expr)
        push!(values.args, :($(esc(var_data[i,1]))))
	end
#####
	if logging == ""    ## no logging
		inner_ex = quote try
            break_vals = []
			for n in 1:$maxtests
				$generate_values
				if $(esc(cond))
					num_good_args += 1
					res = res || $(esc(prop))
					if res
                        break_vals = $values
						break
					end
					if num_good_args >= $ntests
						break
					end
				end
			end
		        # no example but insufficient amount of tests
			if !res && num_good_args<$ntests
				nt = $ntests
 				error("Found only $num_good_args/$nt values satisfying given condition.")
			end
			res ? Pass(:test,
                        $(Expr(:quote, exprs)),
                        [string(s[1])*" = "*string(s[2]) for s in zip($(var_data[:,1]), break_vals)],
                        nothing) :
		   	   Fail(:test,$(Expr(:quote, exprs)), nothing, nothing)
		catch err
			Error(:test_error,$(Expr(:quote, exprs)), err, catch_backtrace())
		end end #quote #try
	else 		## logging is a path to file where the log is written to
		inner_ex = quote try
            break_vals = []
			log_file = open($logging,"a")
			writedlm(log_file,reshape([string(s) for s in $(var_data[:,1])],(1,$num_of_vars)),",")
			for n in 1:$maxtests
				$generate_values
				if $(esc(cond))
					num_good_args += 1
					res = res || $(esc(prop))
					writedlm(log_file,transpose(push!(convert(Vector{Any},$values),res)),",")
					if res
						break
					end
					if num_good_args >= $ntests
						break
					end
				end
			end
			close(log_file)
		        # no example but insufficient amount of tests
			if !res && num_good_args<$ntests
				nt = $ntests
 				error("Found only $num_good_args/$nt values satisfying given condition.")
			end
			res ? Pass(:test,
                        $(Expr(:quote, exprs)),
                        [string(s[1])*" = "*string(s[2]) for s in zip($(var_data[:,1]), break_vals)],
                        nothing) :
		   	   Fail(:test,$(Expr(:quote, exprs)), nothing, nothing)
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
		res = false
		result = $inner_ex
        if isa(result, Pass)
            println(result.data)
        end
		record(get_testset(), result)
	end
end
