using Checkers

import Base.Test: record, finish, Result, Pass, Fail, Error, AbstractTestSet

function is_tiny(x)
    abs(x) < 10.0^(-6)
end

function is_huge(x)
    x > 10.0^(6)
end

function is_increasing(f::Function)
            eval(:(@test_formany -Inf<x::Float64<Inf, -Inf<y::Float64<Inf, x < y --> $f(x) < $f(y)))
end

@test isa( ( @test_exists 0<x::Float64<<1, is_tiny(x) ) , Pass )

# Borrowed from julia/test/test.jl:
# Fail/Error results do not throw errors when tests are performed,
# so *this* set of tests can test for expected fails / errors and pass.
type NoThrowTestSet <: AbstractTestSet
    results::Vector
    NoThrowTestSet(desc) = new([])
end
record(ts::NoThrowTestSet, t::Result) = (push!(ts.results, t); t)
finish(ts::NoThrowTestSet) = ts.results

results = @testset NoThrowTestSet begin
	#1 Fail
	@test_formany 0<x::Float64<10, x<9 ntests = 1000
	#2 Fail
	@test_exists -Inf<x::Int64<Inf, x>10000
	#3 Fail
	is_increasing(x -> x^2)
	#4 Error: generator for y receives incorrect lower and upper bounds
	@test_formany Inf > x > 0, x<y<10, x>0
	#5 Pass
	@test_forall i in 1:20, 1==1
	#6 Pass
	is_increasing(x -> x)
	#7 Pass
	is_increasing(x -> x^3)
end

#Now the actual expectations:
expected = [Fail, Fail, Fail, Error, Pass, Pass, Pass]
@testset "@test_... macros behave as expected" begin
    for i in eachindex(expected)
        @test isa(results[i],expected[i])
    end
end

results_2 = @testset NoThrowTestSet begin
    @test_forall 100==100
    @test_formany maxtests=100 0 < x < 10, x < 11
    @test_exists maxtests=100 0 < x < 10, x < 10
    @test_exists ntests=100 0 < x < 10, x < 10
    @test_exists ntests=100 0 < x < 10, x < 9 --> x < 10
    @test_exists maxtests=100 0 < x < 10, x < 9 --> x < 10
    @test_exists 0 < x < 10, x < 9 --> x < 10
end
expected_2 = [Error, Pass, Pass, Pass, Pass, Pass, Pass]

results_3 = @testset NoThrowTestSet begin
    #Workaround from @TotalVerb on Julia Gitter
    temp_file = tempname()
    @eval (@test_formany logto=$temp_file 0 < x < 10, x < 11)
    rm(temp_file)

    #Should pass
    @test_formany 0<<x<1, x < 2

    #Should fail...formany wants all of them
    @test_formany 0<<x<1, x < 0.5

    #Should pass
    @test_exists ntests=1000 0<<x<1, x < 2

    #This should fail, because x will veer towards 1
    @test_exists ntests=1000 0<<x<1, x < 0.5

    #This should pass. Great!
    @test_exists ntests=1000 0<x<<1, x < 0.5

    #This should pass too.
    @test_exists ntests=1000 0<x<<1, x < 0.01

end

expected_3 = [Pass, Pass, Fail, Pass, Fail, Pass, Pass]
@testset "@test_... macros behave as expected" begin
    for i in eachindex(expected_3)
        @test isa(results_3[i],expected_3[i])
    end
end
