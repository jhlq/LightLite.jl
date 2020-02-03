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
apply!(ps,[1,2],cnot)
@test p(ps,"11")==1
apply!(ps,[2,1],cnot)
@test p(ps,"11")==0

g=makegrid(1)
@test length(g)==13
