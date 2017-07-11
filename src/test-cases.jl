"""
    @test_cases [ntests = 100] [maxtests = 1000] [logto = ""] [working_mode = :none] [argument_data, proposition]

    Takes proposition depending on some variables, generates samples of their values
    and tests the proposition. Prints number of samples for which the proposition evaluated to `true`.

## Arguments

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
  * `x::T`, where `T` is a julia type for which function `custom_generator(x::T...)`
  is specified (see ~/examples/new-type-generator.jl for more details).
  * For inequalities shorthand `x` instead of `x::T` may be used, e.g. `a<x<b`,
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

* `working_mode = :none`: accepts one of three symbols: `:none`, :test_formany`,
  `:test_exists`. For modes different from `:none` see documentation for `@test_formany`
  and `@test_exists`.

## Description

Macro `@test_cases` provides a convenient syntax for testing a boolean-valued
proposition multiple times against randomly generated input. Output prints number
of cases for which the proposition was satisfied.

The macro attempts to generate a sample of values for all variables identified in
`argument_data`. Value of every variable is generated according to its type `T`
and rules specified for this type in function `custom_generator(x::T...)`.
Generated input is used to evaluate the statement of the test.

If `proposition` is just a boolean-valued expression, code simply checks whether
`prop` holds for generated values.

If `proposition` is of form `condition-->statement` (see arguments list),
then test checks whether implication holds. Namely, the test passes if whenever
`condition` evaluates to `true`, then `statement` also evaluates to `true`.

In the latter setting the test breaks and returns error, if the number of attempts to
generate argument values satisfying `condition` exceeds `maxtests` parameter before
succesfully performing `ntests` checks of `proposition`. Thus, some caution is
required to avoid vacuous conditions. Failure to generate `ntests` values
satisfying the `condition` in `maxtests` attempts results in error.

Default for optional keyword arguments is the following: `ntests = 100, maxtests = 1000`.
If only `ntests` parameter is specified, `maxtests = 10*ntests`. If `logto = "path_to_file"`
is given, log of test will be written to corresponding file,for example:

* `@test_cases ntests = 10 maxtests = 1000  1<x<10, proposition logto =  "./test_log.csv"`

Working mode argument has default `working_mode = :none` and is designed to
refer to @test_cases` code from other macros `@test_formany` and `@test_exists`.
Macro calls `@test_cases working_mode = :test_formany argument_data, proposition`
and `@test_formany argument_data, proposition` are fully equivalent.

## Examples

```julia
# example with default genenerator that draws values from uniform distribution
@test_cases ntests = 10000 0<x<100, x>=50
Test passed in 5035/10000 simulations.

# simulated values can be recorded, using `logto` optional field
## theoretical expectation .5*log(2) +.5 ~ 0.847...
@test_cases ntests = 10000 1<x<1, 0<y<1, x*y <.5 logto =  "./test_log.csv"
Test passed in 8399/10000 simulations.

#elementary example of testing cdf properties using Checkers
type gaussian_rv
	val::Float64
end

function Checkers.custom_generator{T<:gaussian_rv}(var_type::Type{T}, mu::Number, sigma::Number)
	return (size) -> gaussian_rv(mu + sigma*randn())
end

@test_cases x::gaussian_rv, 0, 1, x.val<1.96 ntests = 10000
Test passed in 9777/10000 simulations.
```
"""
macro test_cases(exprs...)
    # everything is embedded in try/catch block and if it can't be compiled,
    # cathch-part returns Error type object from Base.test
    output_expr = try

    #  identify pseduo-keyword arguments
    maxtests = 0; ntests = 0; logto = ""
    # working mode
    working_mode = :none # can be :test_formany or :test_exists

    prop = :(); cond = :()

    # parsing expression
	var_data = Array(Any, 3, 1)
    for ex in exprs
        if isa(ex, Expr) && ex.head == :tuple  # parsing statements about
            var_data = parse_argument_data(ex) # variables, condition and
            if ex.args[end].head == :-->       # proposition
                prop = ex.args[end].args[2]
                cond = ex.args[end].args[1]
            else
                prop = ex.args[end]
                cond = true
            end
        elseif isa(ex, Expr) && ex.head == :(=) # parsing pseduo-keyword arguments
            if ex.args[1] == :ntests
                ntests = ex.args[2]
            elseif ex.args[1] == :maxtests
                maxtests = ex.args[2]
            elseif ex.args[1] == :logto
                logto = ex.args[2]
            elseif ex.args[1] == :mode
                if ex.args[2] in (:test_formany, :test_exists, :none)
                    working_mode = ex.args[2]
                else
                    error("Unrecognized mode $(ex.args[2]).")
                end
            else
                error("Invalid macro input $ex.")
            end
        else
            error("Invalid macro input $ex.")
        end
    end

    # setting default parameters for ntests and maxtests
    if ntests == 0
        ntests = 100
    end
    if maxtests == 0
        maxtests = 10 * ntests
    end

    # creating a block expression `generate_values` and expression values
    # that stores references to generated variable
    num_of_vars = size(var_data,2)
    generate_values = Expr(:block)
    values = Expr(:vect)
    for i in 1:num_of_vars
        params = Expr(:call, :custom_generator, esc(var_data[2,i]))
        for p in var_data[3,i]
            push!(params.args, esc(p))
        end
        next_expr = :($(esc(var_data[1,i]))= $params(div(n,2)+3))
        push!(generate_values.args, next_expr)
        push!(values.args, :($(esc(var_data[1,i]))))
    end
    # defining innermost expression in the loop running tests
    inner_ex = quote
        num_good_args += 1
        tmp = $(esc(prop))::Bool
        num_passes += tmp

        # possibly log here

        # possibly record break_values and break if mode = test_exists/test_formany

        if num_good_args >= $ntests
            break
        end
    end

    if logto != ""
        insert!(inner_ex.args, length(inner_ex.args) - 1,
         quote
             writedlm(log_file, transpose(push!(convert(Vector{Any},$values),tmp)), ",")
         end
        )
    end

    if working_mode == :test_formany
        insertion_ex = quote
            if !tmp
                break_values = $values
                break_test = true
                break
            end
        end

        insert!(inner_ex.args, length(inner_ex.args) - 1, insertion_ex)
    end

    if working_mode == :test_exists
        insertion_ex = quote
            if tmp
                break_values = $values
                break_test = true
                break
            end
        end

        insert!(inner_ex.args, length(inner_ex.args) - 1, insertion_ex)
    end

    # defining output expression
    output_expr = quote
        num_good_args = 0
        num_passes = 0
        break_values = []
        break_test = false

        # possibly open file to log values

        for n in 1:$maxtests
            $generate_values

            if $(esc(cond))
                $inner_ex
            end
        end

        if !break_test && num_good_args < $ntests
            nt = $ntests
            error("Found only $num_good_args/$nt values satisfying given condition.")
        end

        # if logging close file here

        # if mode == none print the result
        # else specify result in Pass/Fail format
    end

    # depending on pseudo-args modify the output_expr
    if working_mode == :none
        show_result_expr = quote
            nt = $ntests
            print_with_color(:green, "Test passed in $num_passes/$nt simulations.\n")
        end
        push!(output_expr.args, show_result_expr)
    end

    if logto!= ""
        logging_expr = quote
            log_file = open($logto,"a")
            writedlm(log_file,
                reshape([string(s) for s in $(var_data[1,:])],(1,$num_of_vars)),",")
        end

        unshift!(output_expr.args, logging_expr)
        push!(output_expr.args, quote close(log_file) end)
    end

    if working_mode == :test_formany
        insertion_ex = quote
            result = !break_test ?
                 Pass(:test,$(Expr(:quote, exprs)), nothing, nothing) :
                 Fail(:test,
                    $(Expr(:quote, exprs)),
                    [string(s[1])*" = "*string(s[2]) for s in zip($(var_data[1,:]), break_values)],
                    nothing)

            if isa(result, Fail)
                println(result.data)
            end

            record(get_testset(), result)
        end

        push!(output_expr.args, insertion_ex)
    end

    if working_mode == :test_exists
        insertion_ex = quote
            result = break_test ?
                Pass(:test,
                    $(Expr(:quote, exprs)),
                    [string(s[1])*" = "*string(s[2]) for s in zip($(var_data[1,:]), break_values)],
                    nothing) :
                Fail(:test,$(Expr(:quote, exprs)), nothing, nothing)

            if isa(result, Pass)
                println(result.data)
            end

            record(get_testset(), result)
        end

        push!(output_expr.args, insertion_ex)
    end

    output_expr = Expr(:try, output_expr, :err,
        quote
            result = Error(:test_error, $(Expr(:quote, exprs)), err, catch_backtrace())
            record(get_testset(), result)
        end
        )

    output_expr

    # if something of the above didn't work, will return error
    catch err
        output_expr = quote
        	result = Error(:test_error, $(Expr(:quote, exprs)), $err, catch_backtrace())
            record(get_testset(), result)
        end
    end

    return output_expr
end
