macro test_cases(exprs...)
    #  identify pseduo-keyword arguments
    maxtests = 0; ntests = 0; logging = ""
    # working mode
    working_mode = :none # can be :test_formany or :test_exists

    prop = :(); cond = :()

    # parsing expression
	var_data = Array(Any,1,6)
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
                logging = ex.args[2]
            elseif ex.args[1] == :mode
                mode = ex.args[2]
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

    # defining output expression
    output_expr = quote
        test_success = false
        num_good_args = 0

        num_passes = 0
        break_values = []

        for n in 1:$maxtests
            $generate_values
            if $(esc(cond))
				num_good_args += 1

                tmp = $(esc(prop))
                num_passes += tmp
                if num_good_args >= $ntests
                    break
                end
            end
        end

        if num_good_args < $ntests
            nt = $ntests
            error("Found only $num_good_args/$nt values satisfying given condition.")
        end
    end

    # depending on pseudo-args modify the output_expr
    if working_mode == :none
        show_result_expr = quote
            nt = $ntests
            print_with_color(:green, "Test passed in $num_passes/$nt simulations.\n")
        end
        push!(output_expr.args, show_result_expr)
    end


    # writedlm(log_file,transpose(push!(convert(Vector{Any},$values),res)),",")
    if logging != ""
        logging_expr = quote
            log_file = open($logging,"a")
            writedlm(log_file,
                reshape([string(s) for s in $(var_data[:,1])],(1,$num_of_vars)),",")
        end


        insert!(output_expr.args[10].args[2].args[4].args[2].args, 5,
            quote writedlm(log_file,transpose(push!(convert(Vector{Any},$values),tmp)),",") end)
        unshift!(output_expr.args, logging_expr)
        push!(output_expr.args, quote close(log_file) end)
    end

    return output_expr
end
