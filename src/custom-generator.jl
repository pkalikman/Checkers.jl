function custom_generator{T<:Union{AbstractFloat,Integer}}(var_type::Type{T},
    a::Number, b::Number, type_a::Bool, type_b::Bool,
    p::Float64 = 1.5)
    if a > b
        error("Generator received incorrect lower and upper bounds:
        $a > $b")
    end
	if a == -Inf && b == Inf
               if var_type<:AbstractFloat
                   return (size)->(rand(var_type)-.5)*var_type(p)*size
               elseif var_type<:Integer
                   return (size)->rand(Vector{var_type}(-size:size))
               else
                   error("Generator for type $var_type is not specified.")
               end
	elseif b == Inf && type_a == false  # a<<x
		if var_type<:Integer
			return (size) -> var_type(a)+var_type(100)*rand(Vector{var_type}(1:size))
		elseif var_type<:AbstractFloat
			return (size) -> var_type(a)+rand(var_type)*var_type(p)^(size-1)
		else
			error("Generator for type $var_type is not specified.")
		end
	elseif b == Inf && type_a == true  # a<x
		if var_type<:Integer
			return (size) -> var_type(a)+rand(Vector{var_type}(1:size))
		elseif var_type<:AbstractFloat
			return (size) -> var_type(a)+rand(var_type)*var_type(p)*size
		else
			error("Generator for type $var_type is not specified.")
		end
	elseif a == -Inf && type_b == false  # x<<b
		if var_type<:Integer
			return (size) -> var_type(b)-var_type(100)*rand(Vector{var_type}(1:size))
		elseif var_type<:AbstractFloat
			return (size) -> var_type(b)-rand(var_type)*var_type(p)^(size-1)
		else
			error("Generator for type $var_type is not specified.")
		end
	elseif a == -Inf && type_b == true  # x<b
		if var_type<:Integer
			return (size) -> var_type(b)-rand(Vector{var_type}(1:size))
		elseif var_type<:AbstractFloat
			return (size) -> var_type(b)-rand(var_type)*var_type(p)*size
		else
			error("Generator for type $var_type is not specified.")
		end
	elseif  abs(a)!=Inf && abs(b)!=Inf && var_type<:AbstractFloat
		if (type_a,type_b) == (true,true)  # x<a<b
			return (size)->var_type(a)+(var_type(b)-var_type(a))*rand(var_type)  # choose uniform [a,b]
		elseif (type_a,type_b) == (true,false) # a<x<<b
			return (size)->var_type(a)+(var_type(b)-var_type(a))*rand(var_type)/var_type(p)^(size-1)
		elseif (type_a,type_b) == (false,true) # a<<x<b
			return (size)->var_type(b)-(var_type(b)-var_type(a))*rand(var_type)/var_type(p)^(size-1)
		end
	else
		error("Could not specify generator for $a,$b,$var_type")
	end
end
