
function lambda_arg_types(f::Function)
    [var for var in code_lowered(f)[1].specTypes.types[2:end]]
end

# Simple properties
function property(prop::Function, typs::Vector, ntests)
    arggens = [size -> generator(typ, size) for typ in typs]
    quantproperty(prop, typs, ntests, arggens...)
end
property(prop::Function, typs::Vector) = property(prop, typs, 100)
property(prop::Function, ntests) = property(prop, lambda_arg_types(prop), ntests)
property(prop::Function) = property(prop, 100)

# Conditional properties
function condproperty(prop::Function, typs::Vector, ntests, maxtests, argconds...)
    arggens = [size -> generator(typ, size) for typ in typs]
    check_property(prop, arggens, argconds, ntests, maxtests)
end
condproperty(prop::Function, args...) = condproperty(prop, lambda_arg_types(prop), args...)

# Quantified properties (custom generators)
function quantproperty(prop::Function, typs::Vector, ntests, arggens...)
    argconds = [(_...)->true for t in typs]
    check_property(prop, arggens, argconds, ntests, ntests)
end
quantproperty(prop::Function, args...) = quantproperty(prop, lambda_arg_types(prop), args...)

function check_property(prop::Function, arggens, argconds, ntests, maxtests)
    totalTests = 0
	counterexamples = false
    for i in 1:ntests
        goodargs = false
        args = []
        while !goodargs
            totalTests += 1
            if totalTests > maxtests
                println("Arguments exhausted after $i tests.")
                return
            end
            args = [arggen(div(i,2)+3) for arggen in arggens]
            goodargs = reduce(&,[cond(args...) for cond in argconds])
        end
        if !prop(args...)
		println("Falsifiable, after $i tests:\n$args")
		counterexamples = true
		return false
            #error("Falsifiable, after $i tests:\n$args")
        end
    end
	if !counterexamples
	    println("OK, passed $ntests tests.")
	return true
	end
end

function check_existence(prop::Function, arggens, argconds, ntests, maxtests)
    totalTests = 0
	findings = false
    for i in 1:ntests
        goodargs = false
        args = []
        while !goodargs
            totalTests += 1
            if totalTests > maxtests
                println("Arguments exhausted after $i tests.")
                return
            end
            args = [arggen(div(i,2)+3) for arggen in arggens]
            goodargs = reduce(&,[cond(args...) for cond in argconds])
        end
        if prop(args...)
            println("Found necessary value after $i tests:\n$args")
            findings = true
	     return true #break
        end
    end
     if !findings	
		println("Could not prove existence after $ntests tests.")
		return false
	end
end

# Default generators for primitive types
generator{T<:Unsigned}(::Type{T}, size) = convert(T, rand(1:size))
generator{T<:Signed}(::Type{T}, size) = convert(T, rand(-size:size))
# Fima: replaced .* with * in the next line (was it typo?)
generator{T<:AbstractFloat}(::Type{T}, size) = convert(T, (rand()-0.5)*size)   
# This won't generate interesting UTF-8, but doing that is a Hard Problem
generator{T<:AbstractString}(::Type{T}, size) = convert(T, randstring(size))

generator(::Type{Any}, size) = error("Property variables cannot by typed Any.")

# Generator for array types
function generator{T,n}(::Type{Array{T,n}}, size)
    dims = [rand(1:size) for i in 1:n]
    reshape([generator(T, size) for x in 1:prod(dims)], dims...)
end

# Generator for composite types
function generator{C}(::Type{C}, size)
    if C.types == ()
        error("No generator defined for type $C.")
    end
    C([generator(T, size) for T in C.types]...)
end

macro not(b)
	return :(!$b)
end

