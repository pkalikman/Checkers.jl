function is_symbol_and_type(ex)
	isa(ex, Expr) && ex.head == :(::) && length(ex.args) == 2 && isa(ex.args[1],Symbol)
end

function parse_argument_data(exprs::Expr)
	vars = Any([nothing, nothing, []])
	for ex in exprs.args[1:end-1]

		## x::Mytype
		if is_symbol_and_type(ex)
			sym, typ = ex.args
			vars = hcat(vars, Any([nothing, nothing, []]))

			vars[1, end] = sym
			vars[2, end] = typ

		## a < x < b or a > x > b
		elseif isa(ex, Expr) && length(ex.args) == 5
			if is_symbol_and_type(ex.args[3])
				sym, typ = ex.args[3].args
			elseif isa(ex.args[3], Symbol)  # Default to Float64 here
				sym, typ = ex.args[3], Float64
			else
				error("Could not argument data $ex.")
			end
			vars = hcat(vars, Any([nothing, nothing, []]))
			vars[1, end] = sym
			vars[2, end] = typ

			if ex.args[2] == :< && ex.args[4] == :<     ## a<x<b
				push!(vars[3, end], ex.args[1], ex.args[5], true, true)
			elseif ex.args[2] == :> && ex.args[4] == :> ## a>x>b
				push!(vars[3, end], ex.args[5], ex.args[1], true, true)
			else
				error("Could not parse argument data $ex")
			end

		elseif isa(ex, Expr) && length(ex.args) == 3 ## a<<x<b, a>>x>b, a<x<<b or a>x>>b
			if ex.args[1] == :<

				## a<<x<b
				if isa(ex.args[2], Expr) &&	length(ex.args[2].args) == 3 && ex.args[2].args[1] == :<<
					if is_symbol_and_type(ex.args[2].args[3])
						sym, typ = ex.args[2].args[3].args
					elseif isa(ex.args[2].args[3], Symbol)  # Default to Float64 here
						sym, typ = ex.args[2].args[3], Float64
					else
						error("Could not argument data $ex.")
					end
					vars = hcat(vars, Any([nothing, nothing, []]))
					vars[1, end] = sym
					vars[2, end] = typ
					push!(vars[3, end], ex.args[2].args[2], ex.args[3], false, true)

				## a<x<<b
				elseif isa(ex.args[3], Expr) && length(ex.args[3].args) == 3 && ex.args[3].args[1] == :<<
					if is_symbol_and_type(ex.args[3].args[2])
						sym, typ = ex.args[3].args[2].args
					elseif isa(ex.args[3].args[2], Symbol)  # Default to Float64 here
						sym, typ = ex.args[3].args[2], Float64
					else
						error("Could not argument data $ex.")
					end
					vars = hcat(vars, Any([nothing, nothing, []]))
					vars[1, end] = sym
					vars[2, end] = typ
					push!(vars[3, end], ex.args[2], ex.args[3].args[3], true, false)
				else
					error("Could not argument data $ex.")
				end

			elseif ex.args[1] == :>

				## a>>x>b
				if isa(ex.args[2], Expr) && length(ex.args[2].args) == 3 && ex.args[2].args[1] == :>>
					if is_symbol_and_type(ex.args[2].args[3])
						sym, typ = ex.args[2].args[3].args
					elseif isa(ex.args[2].args[3], Symbol)  # Default to Float64 here
						sym, typ = ex.args[2].args[3], Float64
					else
						error("Could not argument data $ex.")
					end
					vars = hcat(vars, Any([nothing, nothing, []]))
					vars[1, end] = sym
					vars[2, end] = typ
					push!(vars[3, end], ex.args[3], ex.args[2].args[2], true, false)

				## a>x>>b
				elseif isa(ex.args[3], Expr) && length(ex.args[3].args) == 3 && ex.args[3].args[1] == :>>
					if is_symbol_and_type(ex.args[3].args[2])
						sym, typ = ex.args[3].args[2].args
					elseif isa(ex.args[3].args[2], Symbol)  # Default to Float64 here
						sym, typ = ex.args[3].args[2], Float64
					else
						error("Could not argument data $ex.")
					end
					vars = hcat(vars, Any([nothing, nothing, []]))
					vars[1, end] = sym
					vars[2, end] = typ
					push!(vars[end, 3], ex.args[3].args[3], ex.args[2], false, true)
				else
					error("Could not parse argument data $ex")
				end
			else
				error("Could not parse argument data $ex")
			end
		# push arguments to the last column
		elseif isa(vars[1, end], Symbol) 
			push!(vars[3, end], ex)
		else
			error("Could not parse argument data $ex.")
		end
	end
	return vars[:,2:end]
end
