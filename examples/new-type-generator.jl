using Checkers

type ExampleType
	parameter::Float64
end

## Fully qualify 'custom_generator' if not explicitly importing from Checkers
function Checkers.custom_generator(a::Number, b::Number, type_a::Bool, type_b::Bool, mytype)
    (size) -> ExampleType(a+(b-a)*rand(Float64))   
end

@testset "Testing custom generator for ExampleType" begin
	@test_formany 1 < x::ExampleType < 10, x.parameter == 1
	@test_formany 1 < x::ExampleType < 10, 1 < x.parameter < 10
end
