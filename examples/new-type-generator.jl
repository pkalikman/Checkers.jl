using QuickCheck2, Base.Test

type mytype
	parameter::Float64
end

QuickCheck2.custom_generator(a::Number, b::Number, type_a::Bool, type_b::Bool, mytype) = (size) -> mytype(a+(b-a)*rand(Float64))   ## Note `QuickCheck2` prefix!

@testset "new type generator test" begin  #
	@test_formany 1<x::mytype<10, x.parameter==1
	@test_formany 1<x::mytype<10, 10>x.parameter>1
end