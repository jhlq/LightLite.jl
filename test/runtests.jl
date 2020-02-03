using LightLite
using Test

p1=photon()
@test p(p1)==0
apply!(p1,X)
@test p(p1)==1
apply!(p1,H)
@test p(p1)<0.51 && p(p1)>0.49
apply!(p1,Z);apply!(p1,Y);apply!(p1,H)
@test p(p1)>0.99

ps=photons(2)
apply!(ps,1,X)
@test p(ps,"10")==1
apply!(ps,2,X)
@test p(ps,"11")==1

ps=photons(2)
apply!(ps,[1,2],cnot)
@test p(ps,"01")==0
apply!(ps,1,X)
@test p(ps,"10")==1
apply!(ps,[1,2],cnot)
@test p(ps,"11")==1
apply!(ps,[2,1],cnot)
@test p(ps,"11")==0

ps=photons(3)
apply!(ps,[1,2,3],[H,H,H])
pr=p(ps)
@test isapprox(pr[1],1/(2^3))
@test isapprox(sum(pr),1)
@test length(states(ps,"*1*"))==4
@test length(states(ps,"*01"))==2
result=measure!(ps,1)
pr0=p(ps,"0**")
pr1=p(ps,"1**")
if result==1
	@test pr0["tot"]<0.01 && isapprox(pr1["tot"],1)
else 
	@test pr1["tot"]<0.01 && isapprox(pr0["tot"],1)
end
@test isapprox(sum(p(ps)),1)

g=makegrid(1)
@test length(g)==13
