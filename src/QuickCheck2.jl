module QuickCheck2

using Base.Test
import Base.Test: Result, Pass, Fail, Error, record, get_testset

export property, condproperty, quantproperty
export @test_formany, @test_forall, @test_exists, @not

for (dir, filename) in [

		(".", "test-formany.jl"),
		(".", "test-exists.jl"),
		(".", "test-forall.jl"),
		(".", "parse-argument-data.jl"),
		(".", "custom-generator.jl"),
		(".", "quickcheck-original.jl"),
	]

include(joinpath(dir, filename))
end

end #of module
