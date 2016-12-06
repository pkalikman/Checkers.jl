using QuickCheck2
using Base.Test

@testset "EXAMPLES:" begin

## Examples for @test_forall macro. Returns 4 Passes; 1 Fail; 1 Error
@testset "@test_forall macro" begin
	@test_forall x in -1:1, x*(x-1)*(x+1) == 0 # test passed
	@test_forall x in -1:1, x*(x-2)*(x+1) == 0 # test failed
	@test_forall i in 1:2, x in -1:3, y in x+1:4, (x+i)^2<(y+i)^2 # test passed
	@test_forall x in [0,1,2], y in x:4, (y+4>2*x)==true # test passed
	@test_forall y in x:4, x in 0:2, (y+4>2*x)==true # bad design: throws UndefVarError: x not defined, because iteration over y comes earlier and refers to value of x
	@test_forall x in ["a","b"], y in ["z","w"], x*y in Set(["az","aw","bz","bw"]) # test passed
end

## Examples for @test_formany macro. Returns 3 Passes; 2 Fails; 1 Error
@testset "@test_formany macro" begin
	@test_formany 100>x>10, x+10<y<<1000, y-5<z<Inf,z>x+5 # test passed
	@test_formany 100>x>10, x+10<y<<1000, y-5<z<Inf, z>x+6 # test failed
	@test_formany ntests = 1000 Inf>x>0,Inf>y>0, x<y-->log(x)<log(y) # test passed
    @test_formany ntests = 100 maxtests = 100 0<x<10, 0<y<100, x^2>y^2-->x>y #will usually fail
    @test_formany ntests = 100 maxtests = 100000 0<x<10, 0<y<100, x^2>y^2-->x>y #will usually pass
	@test_formany -Inf<x<Inf, -Inf<y<Inf x<y-->log(x)<log(y) 1000 # test throws DomainError
	@test_formany 0<a<1,-100<x<100,-100<y<100,(a*x+(1-a)*y)^3<a*x^3+(1-a)*y^3 # test failed: x^3 is not convex on [-100,100]
	@test_formany 0<a<1,0<x<100,0<y<100, (a*x+(1-a)*y)^3<=a*x^3+(1-a)*y^3 # test passed
end

## Examples for @test_exists macro. Returns 5 Passes; 1 Fail
@testset "@test_exists macro" begin
	@test_exists ntests = 1000 -10<x<10, x^2>99  # test passed
	@test_exists ntests = 100000 0<x<10000, x>9999 # test passed
	@test_exists ntests = 100 0<x<10000, x>9999 # fails almost surely
	@test_exists 0<x<2*pi,x<y<2*pi,y<z<2*pi, sin(x)<sin(y)<sin(z) # test passes
	@test_exists ntests = 10000 0<x<2*pi,0<y<2*pi,0<z<2*pi, x<y<z --> sin(x)<sin(y)<sin(z) # test passes almost surely
	@test_exists 0<x1<2,x1<x2<2, x1<y<x2, (x1-1)^2*(x1+1)^2<(y-1)^2*(y+1)^2<(x2-1)^2*(x2+1)^2 # test passed
end

end # EXAMPLES
