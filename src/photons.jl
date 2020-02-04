using LinearAlgebra
mutable struct Photon
	pol::Array{Complex{Float64},1}
end
photon()=Photon([1,0])
p(pho::Photon)=abs(pho.pol[2]^2)
X=[0 1;1 0]
Y=[0 -1im;1im 0]
Z=[1 0;0 -1]
H=[1 1;1 -1]/sqrt(2)

function apply!(pho::Photon,gate::Matrix)
	pho.pol=gate*pho.pol
end
mutable struct Photons
	n::Int
	state::Array{Complex{Float64},1}
	labels::Array{String}
end
function photons(n::Int)
	s=zeros(Complex{Float64},n^2)
	s[1]=1
	l=["0","1"]
	for i in 2:n
		l=kron(l,["0","1"])
	end
	ps=Photons(n,s,l)
	return ps
end
function makemat(n::Int,ia::Array{Int},gates::Array)
	mc=Matrix[]
	for i in 1:n
		push!(mc,I(2))
	end
	for iai in 1:length(ia)
		mc[ia[iai]]=gates[iai]
	end
	return kron(mc...)
	m=kron(mc[1],mc[2])
	for i in 3:n
		m=kron(m,mc[i])
	end
	return m
end
function apply!(ps::Photons,i::Int,gate::Matrix)
	m=makemat(ps.n,[i],[gate])
	ps.state=m*ps.state
end
function apply!(ps::Photons,ia::Array{Int},gates::Array{Matrix})
	m=makemat(ps.n,ia,gates)
	ps.state=m*ps.state
end
function p(ps::Photons,s::String)
	si=findfirst(x->x==s,ps.labels)
	if !isa(si,Int)
		error("State "*s*" not found.")
	end
	return abs(ps.state[si])^2
end
function cnot(column::Int,ct::Array{Int},ps::Photons)
	s=ps.labels[column]
	control=ct[1]
	target=ct[2]
	c=parse(Bool,s[control])
	a=zeros(ps.n)
	if c
		t=parse(Bool,s[target])
		ns=s[1:target-1]*string(Int(!t))*s[target+1:end]
		nsi=findfirst(x->x==ns,ps.labels)
		a[nsi]=1
	else
		a[column]=1
	end
	return a
end
