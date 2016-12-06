using QuickCheck2
using Base.Test

function is_tiny(x)
    abs(x) < 10.0^(-6)
end

function is_huge(x)
    x > 10.0^(6)
end

function is_increasing(f::Function)
            eval(:(@test_formany -Inf<x::Float64<Inf, -Inf<y::Float64<Inf, x < y --> $f(x) < $f(y)))
end

@test isa( ( @test_exists 0<x::Float64<<1, is_tiny(x) ) , Base.Test.Pass )

## borrowed from julia/test/test.jl, Fail/Error results do not throw errors when tests are performed.
type NoThrowTestSet <: Base.Test.AbstractTestSet
    results::Vector
    NoThrowTestSet(desc) = new([])
end
Base.Test.record(ts::NoThrowTestSet, t::Base.Test.Result) = (push!(ts.results, t); t)
Base.Test.finish(ts::NoThrowTestSet) = ts.results

fails = @testset NoThrowTestSet begin
	#1 Fail
	@test_formany 0<x::Float64<10, x<9 ntests = 1000
	#2 Fail
	@test_exists -Inf<x::Int64<Inf, x>10000
	#3 Fail
	is_increasing(x -> x^2)
	#4 Error: types of variables must be specified
	@test_formany Inf > x > 0, x<y<10, x>0
	#5 Pass
	@test_forall i in 1:20, 1==1
	#6 Pass
	is_increasing(x -> x)
	#7 Pass
	is_increasing(x -> x^3)
end

for i in 1:3
    @test isa(fails[i], Base.Test.Fail)
end

@test isa(fails[4],Base.Test.Error)

for i in 5:7
	@test isa(fails[i],Base.Test.Pass)
end

    #Note is_increasing is a property of the function, so what I really want
    #this to mean is "not @test is_increasing(x->x^2)", i.e.
    #"this test fails."
    #This is slightly different from the @exists idea above, because
    #(a) I'm not trying to help the test find a counterexample, but just
    #declaring that when it does I'm happy, and
    #(b) I'm obscuring where the property is. In other words to express this
    #in terms of an @exists I'd have to write
    #@exists x::Float64, y::Float64, x < y, x^2 > y^2
    #But I don't want to think about that at *all*. I just want to say
    #"x^2 is not increasing" and trust that random examples will figure this
    #out.
    #Maybe think about a syntax that makes it feasible to also specify
    #a generator form with this sort of test, if I have some idea about
    #how to guide it.
