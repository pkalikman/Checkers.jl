using Checkers

@testset "Tests that Pass" begin
    @testset "Tests using @test_forall" begin
        @test_forall x in -1:1, x*(x-1)*(x+1) == 0
        @test_forall i in 1:2, x in -1:3, y in x+1:4, (x+i)^2<(y+i)^2
        @test_forall x in [0,1,2], y in x:4, 2*x < y+4
        @test_forall x in ["a","b"], y in ["z","w"], x*y in Set(["az","aw","bz","bw"])
    end

    @testset "Tests using @test_formany" begin
        #For each x in (10,100), for each y in (x+10,1000) sampling near x+10,
        #for each z in (y-5,∞), x+5 < z
        @test_formany 10<x<100, x+10<y<<1000, y-5<z<Inf, x+5 < z
        #Test 1000 times that log is increasing on (0,∞).
        @test_formany ntests = 1000 Inf>x>0,Inf>y>0, x<y-->log(x)<log(y)
        #Try to test 100 times, but stop after 100_000 tests, that
        #f(x) = x^2 is strictly increasing. Strictly speaking this test could
        #error, but it probably won't.
        @test_formany ntests = 100 maxtests = 100_000 0<x<10, 0<y<100, x^2>y^2-->x>y
        #Test that f(x) = x^3 is convex on (0,100)
        @test_formany 0<a<1, 0<x<100, 0<y<100, (a*x+(1-a)*y)^3<=a*x^3+(1-a)*y^3
    end

    @testset "Tests using @test_exists" begin
        @test_exists ntests = 1000 -10<x<10, x^2>99  # test passed
        @test_exists ntests = 100000 0<x<10000, x>9999 # test passed
        @test_exists 0<x<2*pi,x<y<2*pi,y<z<2*pi, sin(x)<sin(y)<sin(z)
        @test_exists ntests = 10000 0<x<2*pi,0<y<2*pi,0<z<2*pi, x<y<z --> sin(x)<sin(y)<sin(z)
        @test_exists 0<x1<2,x1<x2<2, x1<y<x2, (x1-1)^2*(x1+1)^2<(y-1)^2*(y+1)^2<(x2-1)^2*(x2+1)^2
    end

end

#TODO: Make this a doctest too.
#Test Summary:   | Pass  Total
#  Tests that Pass |   13     13

@testset "Tests that Fail" begin
    #Fails because 1 is not a root
	@test_forall x in -1:1, x*(x-2)*(x+1) == 0
    #Fails because of a situation akin to 11=x, 21.1=y, 16.5=z
	@test_formany 10<x<100, x+10<y<<1000, y-5<z<Inf, x+6 < z
    #Fails because f(x) = x^3 is not convex over (-100,100)
	@test_formany 0<a<1,-100<x<100,-100<y<100,(a*x+(1-a)*y)^3<a*x^3+(1-a)*y^3
    #Fails because it does not do enough tests to find the unlikely witness
	@test_exists ntests = 100 0<x<10000, x>9999
end

#TODO: The witness to failure should be displayed.

@testset "Tests that Error During Test (without making it to Fail)" begin
    #(Usually) errors because the antecedent will not be met 100 times.
    @test_formany ntests = 100 maxtests = 100 0<x<10, 0<y<100, x^2>y^2-->x>y #will usually fail
    #Errors due to bad expression design:
        #throws UndefVarError: x not defined,
        #because iteration over y comes earlier yet refers to value of x
	@test_forall y in x:4, x in 0:2, 2*x < y+4
    #Errors with a DomainError because it will test log(negative values)
	@test_formany -Inf<x<Inf, -Inf<y<Inf, x<y-->log(x)<log(y)
end
