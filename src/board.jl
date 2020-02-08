include("photons.jl")
import Base: getindex, setindex!

abstract type Component end
reset!(c::Component)=nothing
getvar(c::Component,i::Int=1)=(hasfield(typeof(c),:vars) && length(c.vars)>=i) ? c.vars[i] : nothing
getvars(c::Component)=hasfield(typeof(c),:vars) ? c.vars : Number[]
setvar!(c::Component,var::Number,i::Int=1)=(hasfield(typeof(c),:vars) && length(c.vars)>=i) ? c.vars[i]=var : nothing
function setvars!(c::Component,vars::Array)
	for vari in 1:length(vars)
		setvar!(c,var,vari)
	end
end
id(c::Component)=hasfield(typeof(c),:id) ? c.id : string(typeof(c))
mutable struct Emitter<:Component
	loc::Tuple{Int,Int,Int}
	dir::Tuple{Int,Int,Int}
	pol
	label::String
end
newEmitter()=Emitter((0,0,0),(1,0,0),[1,0],"~")
directions=Dict{String,Tuple{Int,Int,Int}}()
directions["right"]=(1,0,0)
directions["down right"]=(0,1,0)
directions["down left"]=(-1,1,0)
directions["left"]=(-1,0,0)
directions["up left"]=(0,-1,0)
directions["up right"]=(1,-1,0)
function makegrid(layers=3,startlocs=[(0,0,2)])
	grid=Set{Tuple}()
	push!(grid,startlocs...)
	connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0), (0,0,1),(1,0,1),(0,1,1),(0,0,-1),(1,0,-1),(1,-1,-1)]
	for layer in 1:layers
		tgrid=Array{Tuple,1}()
		for loc in grid
			if loc[3]==2
				for c in connections
					x,y,z=loc
					x+=c[1];y+=c[2];z+=c[3]
					push!(tgrid,(x,y,z))
				end
			end
		end
		for t in tgrid
			push!(grid,t)
		end
	end
	return grid
end
mutable struct Board
	name
	grid
	shells::Int
	map
	emitters::Array{Emitter}
	emitted::Bool
	photons::Array{Photon}
	state::Photons
	components::Array{Component}
	output::String
end
function newBoard(shells=6,initlocs=[(0,0,2)],grid=0,map=Dict())
	if grid==0
		grid=makegrid(shells,initlocs)
	end
	for loc in grid
		map[loc]=0
	end
	board=Board("circuit",grid,shells,map,[],false,[],photons(0),[],"")
	return board
end
getindex(b::Board,x::Int,y::Int,z::Int)=haskey(b.map,(x,y,z)) ? b.map[(x,y,z)] : nothing
getindex(b::Board,x::Int,y::Int)=getindex(b,x,y,2)
setindex!(b::Board,c::Component,x::Int,y::Int,z::Int)=b.map[(x,y,z)]=c
setindex!(b::Board,c::Component,x::Int,y::Int)=setindex!(b,c,x,y,2)
function place!(b::Board,c::Component,loc::Tuple,replace::Bool=false)
	if length(loc)!=3
		error("Tuple "*string(loc)*" needs to contain 3 elements.")
	end
	if isa(b[loc...],Component)
		if replace
			remove!(b,loc)
		else
			println(loc," is occupied.")
			return
		end
	end
	c=deepcopy(c)
	c.loc=loc
	b[loc...]=c
	if isa(c,Emitter)
		push!(b.emitters,c)
	end
	push!(b.components,c)
	return c
end
function place!(b::Board,c::Component,loc::Array,replace::Bool=false)
	if length(loc)==2
		push!(loc,2)
	end
	place!(b,c,Tuple(loc),replace)
end
function step!(b::Board,steps::Int=1)
	if !b.emitted
		for em in b.emitters
			push!(b.photons,Photon(em.pol,em.loc,em.dir,0,1,0))
		end
		b.state=photons(b.photons)
		b.emitted=true
	end
	for st in 1:steps
		cs=Component[]
		for pind in 1:length(b.photons)
			p=b.photons[pind]
			if p.trapped>0
				p.trapped-=1
				continue
			end
			p.loc=p.loc.+p.dir
			p.amp+=p.der
			if abs(p.amp)>0.999
				p.der=-p.der
			end
			c=b[p.loc...]
			if isa(c,Component) && hasfield(typeof(c),:photons)
				push!(c.photons,pind)
				push!(cs,c)
			end
		end
		for c in cs
			apply!(b,c)
		end
	end	
end
function reset!(b::Board)
	b.photons=[]
	for c in b.components
		reset!(c)
	end
	b.emitted=false
	b.state=photons(0)
	b.output=""
end
function remove!(b::Board,loc)
	if length(loc)==2
		loc=(loc[1],loc[2],2)
	end
	c=b.map[loc]
	if isa(c,Component)
		b.map[loc]=0
		for i in 1:length(b.components)
			if b.components[i].loc==loc
				deleteat!(b.components,i)
				break
			end
		end
		if isa(c,Emitter)
			for i in 1:length(b.emitters)
				if b.emitters[i].loc==loc
					deleteat!(b.emitters,i)
					break
				end
			end
		end
	end
end

mutable struct Gate<:Component #Single qubit gate
	loc::Tuple{Int,Int,Int}
	photons::Array{Int}
	mat::Matrix
	id::String
	label::String
end
function reset!(g::Gate)
	g.photons=[]
end
function apply!(b::Board,gate::Gate)
	m=makemat(b.state.n,gate.photons,gate.mat)
	b.state.state=m*b.state.state
	gate.photons=[]
end
#=getvar(g::Gate,i::Int)=length(g.vars)>=i ? nothing : g.vars[1]
function setvar!(g::Gate,var::Number,i::Int=1)
	g.vars[i]=var
end=#
mutable struct CNOT<:Component
	loc::Tuple{Int,Int,Int}
	photons::Array{Int}
	label::String
end
function apply!(b::Board,c::CNOT)
	if length(c.photons)>1
		b.state.state=cnot(b.state,c.photons)*b.state.state
		b.photons[c.photons[1]].trapped=0
		c.photons=[]
	else
		 b.photons[c.photons[1]].trapped=1073741824
	end
end
mutable struct CustomGate<:Component
	loc::Tuple{Int,Int,Int}
	vars::Array{Number}
	photons::Array{Int}
	id::String
	label::String
end
mutable struct Measure<:Component
	loc::Tuple{Int,Int,Int}
	photons::Array{Int}
	results::Array{Int}
	label::String
end
function reset!(g::Measure)
	g.photons=[]
	g.results=[]
end
function apply!(b::Board,measure::Measure)
	n=length(measure.photons)-length(measure.results)
	for i in 1:n
		mes=measure!(b.state,measure.photons[end-n+i])
		push!(measure.results,mes)
		b.output*=string(mes)
	end
end
mutable struct Mirror<:Component
	loc::Tuple{Int,Int,Int}
	axis::Int
	photons::Array{Int}
	label::String
end
getvars(g::Mirror)=[g.axis]
function setvar!(g::Mirror,var::Number,i::Int=1)
	g.axis=Int(round(var))
end
newMirror()=Mirror((0,0,0),1,[],"")
function flippeddir(pdir,a)
	dir=[pdir[1],-pdir[1]-pdir[2],pdir[2]]
	am=(a+4)%3+1
	ap=a%3+1
	dir[am],dir[ap]=dir[ap],dir[am]
	return (dir[1],dir[3],0)
end
function apply!(b::Board,mirror::Mirror)
	n=length(mirror.photons)
	a=mirror.axis
	for i in 1:n
		p=b.photons[mirror.photons[i]]
		p.dir=flippeddir(p.dir,a)
	end
	mirror.photons=[]
end
function expandboard!(board::Board,shells::Integer=6,initlocs=[(6,6,2)])
	patch=makegrid(shells,initlocs)
	for loc in patch
		if !in(loc,keys(board.map))
			board.map[loc]=0
			push!(board.grid,loc)
		end
	end
	return "<3"
end
function save(b::Board)
	str=""
	for c in b.components
		str*="Dict(:id=>\""*id(c)*"\",:loc=>"*string(c.loc)
		if hasfield(typeof(c),:dir)
			str*=",:dir=>"*string(c.dir)
		end
		if hasfield(typeof(c),:pol)
			str*=",:pol=>"*string(c.pol)
		end
		v=getvars(c)
		if length(v)>0
			str*=",:vars=>"*string(v)
		end
		str*=")\n"
	end
	dir=joinpath(homedir(),".lightlite","circuits",b.name)
	open(dir, "w") do io
		write(io,str);
	end
	println("Saved "*string(length(b.components))*" components at "*dir)
end
function load!(board::Board,name::String,absolute::Bool=false,offset::Tuple{Int,Int,Int}=(0,0,0))
	dir=absolute ? name : joinpath(homedir(),".lightlite","circuits",name)
	stra=readlines(dir)
	for str in stra
		if length(str)==0 || str[1]=='#'
			continue
		end
		d=eval(Meta.parse(str))
		c=components[d[:id]]
		place!(board,c,d[:loc]) #note that this deepcopies c
		for key in keys(d)
			if key==:vars
				setvars!(board[d[:loc]...],d[:vars])
			elseif key!=:loc && key!=:id
				setfield!(board[d[:loc]...],key,d[key])
			end
		end
	end
	return board
end
load(name::String,absolute::Bool=false)=load!(newBoard(),name,absolute)
