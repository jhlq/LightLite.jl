include("photons.jl")
import Base: getindex, setindex!

abstract type Component end
reset!(c::Component)=nothing
mutable struct Emitter<:Component
	loc::Tuple{Int,Int,Int}
	dir::Tuple{Int,Int,Int}
	pol
	label::String
end
newEmitter()=Emitter((0,0,0),(1,0,0),[1,0],"~")
function makegrid(layers=3,startlocs=[(0,0,2)],groundlevel=false)
	grid=Set{Tuple}()
	push!(grid,startlocs...)
	connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0), (0,0,1),(1,0,1),(0,1,1),(0,0,-1),(1,0,-1),(1,-1,-1)]
	if groundlevel
		connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0)]
	end
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
end
function newBoard(shells=6,initlocs=[(0,0,2)],grid=0,map=Dict())
	if grid==0
		grid=makegrid(shells,initlocs)
	end
	for loc in grid
		map[loc]=0
	end
	board=Board(string(round(Integer,time())),grid,shells,map,[],false,[],photons(0),[])
	return board
end
getindex(b::Board,x::Int,y::Int,z::Int)=haskey(b.map,(x,y,z)) ? b.map[(x,y,z)] : nothing
getindex(b::Board,x::Int,y::Int)=getindex(b,x,y,2)
setindex!(b::Board,c::Component,x::Int,y::Int,z::Int)=b.map[(x,y,z)]=c
setindex!(b::Board,c::Component,x::Int,y::Int)=setindex!(b,c,x,y,2)
function place!(b::Board,c::Component,loc::Tuple)
	if length(loc)!=3
		error("Tuple "*string(loc)*" needs to contain 3 elements.")
	end
	if isa(b[loc...],Component)
		#remove!
		println("Occupied")
		return
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
function place!(b::Board,c::Component,loc::Array)
	if length(loc)==2
		push!(loc,2)
	end
	place!(b,c,Tuple(loc))
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

mutable struct Gate<:Component
	loc::Tuple{Int,Int,Int}
	photons::Array{Int}
	vars::Array{AbstractFloat}
	makemat::Function
	boardmods!::Function
	label::String
end
function reset!(g::Gate)
	g.photons=[]
end
function apply!(b::Board,gate::Gate)
	m=gate.makemat(b.state,gate.photons)
	b.state.state=m*b.state.state
	gate.boardmods!(b,gate.photons)
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
		push!(measure.results,measure!(b.state,measure.photons[end-n+i]))
	end
end
mutable struct Mirror<:Component
	loc::Tuple{Int,Int,Int}
	orientation::Tuple{Int,Int,Int}
	photons::Array{Int}
	label::String
end
newMirror()=Mirror((0,0,0),(1,1,0),[],"")
function apply!(b::Board,mirror::Mirror)
	n=length(mirror.photons)
	for i in 1:n
		p=b.photons[mirror.photons[i]]
		ndir=[0,0,0]
		ndir[1]=p.dir[2]*mirror.orientation[1]
		ndir[2]=p.dir[1]*mirror.orientation[2]
		p.dir=Tuple(ndir)
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
#	push!(board.sequence,(:expand,[shells,initlocs]))
	return "<3"
end
