p1=photon()
@test p(p1)==0
apply!(p1,X)
@test p(p1)==1
apply!(p1,H)
@test p(p1)<0.51 && p(p1)>0.49
apply!(p1,Z);apply!(p1,Y);apply!(p1,H)
@test p(p1)>0.99

ps=photons(1)
apply!(ps,1,Z)
@test isapprox(p(ps,"0"),1)

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
@test isapprox(pr["100"],1/(2^3))
@test isapprox(pr["tot"],1)
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
@test isapprox(p(ps)["tot"],1)

function andgate(b1,b2)
	ps=photons(3)
	if b1>0
		apply!(ps,1,X)
	end
	if b2>0
		apply!(ps,2,X)
	end
	apply!(ps,3,ry(-pi/4)) #cH
	apply!(ps,[1,3],cnot)
	apply!(ps,3,ry(pi/4))
	apply!(ps,3,H) #cZ
	apply!(ps,[2,3],cnot)
	apply!(ps,3,H)
	apply!(ps,3,ry(-pi/4)) #cH
	apply!(ps,[1,3],cnot)
	apply!(ps,3,ry(pi/4))
	return ps
end
@test isapprox(p(andgate(0,0),"**0")["tot"],1)
@test isapprox(p(andgate(0,1),"**0")["tot"],1)
@test isapprox(p(andgate(1,0),"**0")["tot"],1)
@test isapprox(p(andgate(1,1),"**1")["tot"],1)

ps=photons("100")
apply!(ps,[1,2,3],toffoli!)
@test isapprox(p(ps,"**0")["tot"],1)
ps=photons("010")
apply!(ps,[1,2,3],toffoli!)
@test isapprox(p(ps,"**0")["tot"],1)
ps=photons("110")
apply!(ps,[1,2,3],toffoli!)
@test isapprox(p(ps,"**1")["tot"],1)

function halfadder(b1,b2)
	ps=photons(4)
	if b1>0
		apply!(ps,1,X)
	end
	if b2>0
		apply!(ps,2,X)
	end
	apply!(ps,[1,3],cnot)
	apply!(ps,[2,3],cnot)
	apply!(ps,[1,2,4],toffoli!)
	return ps
end
@test isapprox(p(halfadder(0,0),"**00")["tot"],1)
@test isapprox(p(halfadder(0,1),"**10")["tot"],1)
@test isapprox(p(halfadder(1,0),"**10")["tot"],1)
@test isapprox(p(halfadder(1,1),"**01")["tot"],1)

S=rz(pi/2)
ps=photons(2);apply!(ps,1,X);apply!(ps,1,S);apply!(ps,1,X)
@test isapprox(imag(ps.state[1]),1)
ps=photons(2);apply!(ps,[1,2],[X,X]);apply!(ps,[1,2],[S,S]);apply!(ps,[1,2],[X,X])
@test isapprox(real(ps.state[1]),-1)

#https://qiskit.org/textbook/ch-states/unique-properties-qubits.html
ps=photons(1);apply!(ps,1,ry(-pi/4));pr=p(ps) #Z measure
@test pr["0"]>0.8 && pr["1"]>0.1
ps=photons(1);apply!(ps,1,ry(-pi/4));apply!(ps,1,H);pr=p(ps) #X measure
@test pr["1"]>0.8 && pr["0"]>0.1
function hardy!(ps::Photons,pinds::Array{Int}) #paradox
	apply!(ps,pinds[1],ry(1.911))
	apply!(ps,pinds,cnot)
	apply!(ps,pinds[2],ry(0.785))
	apply!(ps,pinds,cnot)
	apply!(ps,pinds[2],ry(2.356))
end
ps=photons(2)
apply!(ps,[2,1],hardy!)
@assert p(ps)["00"]<0.01 #if Z measure is 0 on either the other has to be 1
psc1=deepcopy(ps)
psc2=deepcopy(ps)
apply!(psc1,1,H)
apply!(psc2,2,H)
@assert p(psc1)["11"]<0.01 && p(psc2)["11"]<0.01 #if X measure is 1 on either measuring Z on the other has to give 0 
apply!(psc1,2,H) #classically this means measuring X on both cannot give 11
@assert p(psc1)["11"]>0.08 #surprise!
