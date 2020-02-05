include("photons.jl")
import Base: getindex, setindex!

abstract type Component end
mutable struct Emitter<:Component
	dir::Tuple{Int,Int,Int}
	pol
	loc::Tuple{Int,Int,Int}
end
newEmitter()=Emitter((1,0,0),[1,0],(0,0,0))
mutable struct Board
	grid
	map
	emitters::Array{Emitter}
	emitted::Bool
	photons::Array{Photon}
	state::Photons
end
function newBoard(shells=6,initlocs=[(0,0,2)],grid=0,map=Dict())
	if grid==0
		grid=makegrid(shells,initlocs)
	end
	for loc in grid
		map[loc]=nothing
	end
	board=Board(grid,map,[],false,[],photons(0))
	return board
end
getindex(b::Board,x::Int,y::Int,z::Int)=b.map[(x,y,z)]
getindex(b::Board,x::Int,y::Int)=getindex(b,x,y,2)
setindex!(b::Board,c::Component,x::Int,y::Int,z::Int)=b.map[(x,y,z)]=c
setindex!(b::Board,c::Component,x::Int,y::Int)=setindex!(b,c,x,y,2)
function place!(b::Board,c::Component,loc::Tuple)
	if length(loc)!=3
		error("Tuple "*string(loc)*" needs to contain 3 elements.")
	end
	if isa(b[loc...],Emitter)
		#delete emitter
		println("Occupied")
		return
	end
	c.loc=loc
	b[loc...]=c
	if isa(c,Emitter)
		push!(b.emitters,c)
	end
	return c
end
function place!(b::Board,c::Component,loc::Array)
	if length(loc)==2
		push!(loc,2)
	end
	place!(b,c,Tuple(loc))
end
function step!(b::Board)
	if !b.emitted
		for em in b.emitters
			push!(b.photons,Photon(em.pol,em.loc,em.dir,0,1))
		end
		b.state=photons(length(b.photons))
		b.emitted=true
	end
	cs=Component[]
	for pind in 1:length(b.photons)
		p=b.photons[pind]
		p.loc=p.loc.+p.dir
		p.amp+=p.der
		if abs(p.amp)>0.999
			p.der=-p.der
		end
		c=b[p.loc...]
		if isa(c,Component)
			push!(c.photons,pind)
			push!(cs,c)
		end
	end
	for c in cs
		apply!(b,c)
	end
		
end
function reset!(b::Board)
	b.photons=[]
	b.emitted=false
	b.state=photons(0)
end
mutable struct Gate<:Component
	loc::Tuple{Int,Int,Int}
	photons::Array{Int}
	makemat::Function
	boardmods!::Function
end
gates=Dict{String,Gate}()
gates["X"]=Gate((0,0,0),[],(state::Photons,photons::Array{Int})->makemat(state.n,photons,X),(b::Board,photons::Array{Int})->nothing)
function apply!(b::Board,gate::Gate)
	m=gate.makemat(b.state,gate.photons)
	b.state.state=m*b.state.state
	gate.boardmods!(b,gate.photons)
end

