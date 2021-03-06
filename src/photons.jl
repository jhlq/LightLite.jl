using LinearAlgebra
mutable struct Photon
	pol::Array{Complex{AbstractFloat},1}
	loc
	dir
	amp::Number
	der::Number
	trapped::Int
end
photon()=Photon([1,0],(0,0,0),(1,0,0),1,-1,0)
p(c::Complex)=abs(c)^2
p(pho::Photon)=p(pho.pol[2])
X=[0 1;1 0]
Y=[0 -1im;1im 0]
Z=[1 0;0 -1]
H=[1 1;1 -1]/sqrt(2)
S=[1 0;0 1im]
rx(th)=[cos(th/2) -1im*sin(th/2);-1im*sin(th/2) cos(th/2)]
ry(th)=[cos(th/2) -sin(th/2);sin(th/2) cos(th/2)]
rz(th)=[1 0;0 exp(1im*th)]

function apply!(pho::Photon,gate::Matrix)
	pho.pol=gate*pho.pol
end
mutable struct Photons
	n::Int
	state::Array{Complex{AbstractFloat},1}
	labels::Array{String}
end
function photons(n::Int)
	if n<1
		return Photons(n,[],[])
	end
	s=zeros(Complex{AbstractFloat},2^n)
	s[1]=1
	l=bitstates(n)
	ps=Photons(n,s,l)
	return ps
end
function bitstates(n::Int)
	l=["0","1"]
	for i in 2:n
		l=kron(l,["0","1"])
	end
	return l
end
function photons(bits::String)
	ap=Array[]
	for b in bits
		if b=='0'
			push!(ap,[1,0])
		elseif b=='1'
			push!(ap,[0,1])
		end
	end
	n=length(ap)
	if n<1
		return Photons(n,[],[])
	end
	s=ap[1]
	l=["0","1"]
	for i in 2:n
		s=kron(s,ap[i])
		l=kron(l,["0","1"])
	end
	ps=Photons(n,s,l)
	return ps
end
function photons(ap::Array{Photon})
	n=length(ap)
	if n<1
		return Photons(n,[],[])
	end
	s=ap[1].pol
	l=["0","1"]
	for i in 2:n
		s=kron(s,ap[i].pol)
		l=kron(l,["0","1"])
	end
	ps=Photons(n,s,l)
	return ps
end
function makemat(n::Int,ia::Array{Int},gates::Array)
	if n==1
		return gates[1]
	end
	mc=Matrix[]
	for i in 1:n
		push!(mc,[1 0;0 1])
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
function makemat(n::Int,ia::Array{Int},gate::Matrix)
	gates=[gate]
	for i in 2:length(ia)
		push!(gates,gate)
	end
	return makemat(n,ia,gates)
end
function apply!(ps::Photons,i::Int,gate::Matrix)
	m=makemat(ps.n,[i],[gate])
	ps.state=m*ps.state
end
function apply!(ps::Photons,ia::Array{Int},gates::Array)
	m=makemat(ps.n,ia,gates)
	ps.state=m*ps.state
end
function apply!(ps::Photons,ct::Array{Int},f::Function)
	m=f(ps,ct)
	if isa(m,Matrix)
		ps.state=m*ps.state
	end
end
function measure!(ps::Photons,n::Int)
	p0=0.0
	w0=Complex{AbstractFloat}[]
	w1=Complex{AbstractFloat}[]
	for i in 1:length(ps.state)
		if ps.labels[i][n]=='0'
			p0+=p(ps.state[i])
			push!(w0,ps.state[i])
			push!(w1,0)
		else
			push!(w1,ps.state[i])
			push!(w0,0)
		end
	end
	if rand()>p0
		w1=w1/sqrt(1-p0)
		ps.state=w1
		return 1
	else
		w0=w0/sqrt(p0)
		ps.state=w0
		return 0
	end
end
function p(ps::Photons)
	d=Dict{String,AbstractFloat}()
	tot=0.0
	for i in 1:length(ps.labels)
		pr=p(ps.state[i])
		d[ps.labels[i]]=pr
		tot+=pr
	end
	d["tot"]=tot
	return d
end
function matches(label::String,s::String)
	for i in 1:length(label)
		if !(s[i]=='*' || label[i]==s[i])
			return false
		end
	end
	return true
end
function states(ps::Photons,s::String)
	if length(ps.labels[1])!=length(s)
		error("State contains "*string(length(ps.labels[1]))*" qubits but "*s*" refers "*string(length(s))*".")
	end
	ms=Int[]
	for i in 1:length(ps.labels)
		if matches(ps.labels[i],s)
			push!(ms,i)
		end
	end
	if length(ms)==0
		error(s*" matches no states.")
	end
	return ms
end
function states(ps::Photons)
	d=Dict{String,Complex}()
	for i in 1:length(ps.state)
		if ps.state[i]!=0
			d[ps.labels[i]]=ps.state[i]
		end
	end
	return d
end
function p(ps::Photons,s::String)
	if in('*',s)
		ws=states(ps,s)
		d=Dict{String,AbstractFloat}()
		tot=0.0
		for w in ws
			tp=p(ps.state[w])
			d[ps.labels[w]]=tp
			tot+=tp
		end
		d[s]=tot
		d["tot"]=tot
		return d
	end
	si=findfirst(x->x==s,ps.labels)
	if !isa(si,Int)
		error("State "*s*" not found.")
	end
	return abs(ps.state[si])^2
end
function cnot(ps::Photons,ct::Array{Int})
	control=ct[1]
	target=ct[2]
	l=length(ps.state)
	m=zeros(l,l)
	for column in 1:l
		s=ps.labels[column]
		c=parse(Bool,s[control])
		if c
			t=parse(Bool,s[target])
			ns=s[1:target-1]*string(Int(!t))*s[target+1:end]
			nsi=findfirst(x->x==ns,ps.labels)
			m[column,nsi]=1
		else
			m[column,column]=1
		end
	end
	return m
end
