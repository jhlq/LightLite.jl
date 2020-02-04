include("photons.jl")
import Base: getindex, setindex!

abstract type Component end
mutable struct Emitter<:Component
	dir
	pol
	loc::Tuple{Int,Int,Int}
end
newEmitter()=Emitter([1,0],0,(0,0,0))
mutable struct Board
	grid
	map
	emitters
	emitted::Bool
end
function newBoard(shells=6,initlocs=[(0,0,2)],grid=0,map=Dict())
	if grid==0
		grid=makegrid(shells,initlocs)
	end
	for loc in grid
		map[loc]=nothing
	end
	board=Board(grid,map)
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
	if isa(b[loc],Emitter)
		#delete emitter
		error("Occupied")
	end
	c.loc=loc
	b[loc]=c
	if isa(c,Emitter)
		push!(b.emitters,c)
	end
	return c
end
function place!(b::Board,c::Component,loc::Array)
	if length(loc)==2
		push!(loc,2)
	end
	place!(b,c,Tuple(loc)
end

