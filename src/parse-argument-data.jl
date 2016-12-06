function symbol_and_type(ex::Expr)
	if ex.head == :(::) && isa(ex.args[1],Symbol)
		return ex.args[1], ex.args[2]
	else
		error("Could not recognize symbol with type: $ex")
	end
end
symbol_and_type(s::Symbol) = s, Float64


function is_new(s::Symbol,arr::Vector)
	reduce(&,arr.!=s)
end

function parse_argument_data(ex::Expr)
	if ex.head != :tuple
		error("Expression of unsupported format: $ex")
	end
	new_var_row = reshape([nothing,-Inf,Inf,false,false,nothing],(1,6))
	vars = new_var_row
	for p in ex.args[1:end-1]
		if length(p.args) == 5 ## a<x<b or a>x>b
			sym, typ = symbol_and_type(p.args[3])
			if is_new(sym, vars[2:end,1])
				vars = vcat(vars, new_var_row)	
				ind = size(vars,1)
			else 
				ind = find(vars[:,1],sym)[1]
			end
			vars[ind,1] = sym 
			vars[ind,4] = true
			vars[ind,5] = true
			vars[ind,6] = typ
			if p.args[2] == :< && p.args[4] == :<     ## a<x<b
				vars[ind,2] = p.args[1]
				vars[ind,3] = p.args[5]
			elseif p.args[2] == :> && p.args[4] == :> ## a>x>b
				vars[ind,2] = p.args[5]
				vars[ind,3] = p.args[1]
			else
				error("Could not parse argument data $p")
			end

		elseif length(p.args) == 3 ## a<<x<b, a>>x>b, a<x<<b or a>x>>b
			if p.args[1] == :<

				if isa(p.args[2], Expr) &&		## a<<x<b
				   length(p.args[2].args) == 3 && p.args[2].args[1] == :<<
					sym, typ = symbol_and_type(p.args[2].args[3])
					if is_new(sym, vars[2:end,1])
						vars = vcat(vars, new_var_row)	
						ind = size(vars,1)
					else 
						ind = find(vars[:,1],sym)[1]
					end
					vars[ind,1] = sym
					vars[ind,2] = p.args[2].args[2]
					vars[ind,3] = p.args[3]
					vars[ind,4] = false
					vars[ind,5] = true
					vars[ind,6] = typ

				elseif isa(p.args[3], Expr) &&		## a<x<<b
				   length(p.args[3].args) == 3 && p.args[3].args[1] == :<<
					sym, typ = symbol_and_type(p.args[3].args[2])
					if is_new(sym, vars[2:end,1])
						vars = vcat(vars, new_var_row)	
						ind = size(vars,1)
					else 
						ind = find(vars[:,1],sym)[1]
					end
					vars[ind,1] = sym
					vars[ind,2] = p.args[2]
					vars[ind,3] = p.args[3].args[3]
					vars[ind,4] = true
					vars[ind,5] = false
					vars[ind,6] = typ
				else
					error("Could not parse argument data $p")
				end

			elseif p.args[1] == :>
				if isa(p.args[2], Expr) &&		## a>>x>b
				   length(p.args[2].args) == 3 && p.args[2].args[1] == :>>
					sym, typ = symbol_and_type(p.args[2].args[3])
					if is_new(sym, vars[2:end,1])
						vars = vcat(vars, new_var_row)	
						ind = size(vars,1)
					else 
						ind = find(vars[:,1],sym)[1]
					end
					vars[ind,1] = sym
					vars[ind,2] = p.args[3]
					vars[ind,3] = p.args[2].args[2]
					vars[ind,4] = true
					vars[ind,5] = false
					vars[ind,6] = typ
				elseif isa(p.args[3], Expr) &&	## a>x>>b
				   length(p.args[3].args) == 3 && p.args[3].args[1] == :>>
					sym, typ = symbol_and_type(p.args[3].args[2])
					if is_new(sym, vars[2:end,1])
						vars = vcat(vars, new_var_row)	
						ind = size(vars,1)
					else 
						ind = find(vars[:,1],sym)[1]
					end
					vars[ind,1] = sym
					vars[ind,2] = p.args[3].args[3]
					vars[ind,3] = p.args[2]
					vars[ind,4] = false
					vars[ind,5] = true
					vars[ind,6] = typ
				else
					error("Could not parse argument data $p")
				end
			else
				error("Could not parse argument data $p")
			end
		else
			error("Could not parse argument data $p")
		end
	end
	vars = vars[2:end,:]
	vars
end