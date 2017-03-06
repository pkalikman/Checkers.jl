# If you want to write expressions of the form
#     @test_formany x::MyType, f(x)
# without going through the steps of writing
#     @test_formany 1 < x < 10, 1 < y < 10, f(MyType(x,y))...
# You can define a custom generator. An example is below.

using Checkers

type ExampleType
	field1::Float64
end

## Fully qualify 'custom_generator' if not explicitly importing from Checkers
#TODO: Let's explain more how this works and also show a more complicated
#example that doesn't just wrap a single number.
function Checkers.custom_generator(a::Number, b::Number, type_a::Bool, type_b::Bool, mytype)
    (size) -> ExampleType(a+(b-a)*rand(Float64))
end


@testset "Testing custom generator for ExampleType" begin
    #This should pass
	@test_formany 1 < x::ExampleType < 10, 1 < x.field1 < 10
    #This should fail because we did not design the generator
    #to choose only 1 as the value of field1.
	@test_formany 1 < x::ExampleType < 10, x.field1 == 1
end

# elementary example with complex types
type multifield
	field1::Float64
	field2::Float64
	field3::Float64
end

function Checkers.custom_generator{T<:multifield}(var_type::Type{T}, p::Number)
	return (size) -> multifield(p*rand()/size, p*rand(), p*rand()*size)
end

@test_exists mf::multifield, 10, mf.field1<.1 && 1< mf.field2 <10 && mf.field3>100
