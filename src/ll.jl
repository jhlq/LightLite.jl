include("screen.jl")

function toffoli!(ps::Photons,cct::Array{Int})
	T=rz(pi/4)
	Tdg=rz(-pi/4)
	apply!(ps,cct[3],H)
	apply!(ps,[cct[2],cct[3]],cnot)
	apply!(ps,cct[3],Tdg)
	apply!(ps,[cct[1],cct[3]],cnot)
	apply!(ps,cct[3],T)
	apply!(ps,[cct[2],cct[3]],cnot)
	apply!(ps,cct[3],Tdg)
	apply!(ps,[cct[1],cct[3]],cnot)
	apply!(ps,cct[2],Tdg)
	apply!(ps,cct[3],T)
	apply!(ps,[cct[1],cct[2]],cnot)
	apply!(ps,cct[3],H)
	apply!(ps,cct[2],Tdg)
	apply!(ps,[cct[1],cct[2]],cnot)
	apply!(ps,cct[1],T)
	apply!(ps,cct[2],S)
end

components=Dict{String,Component}()
components["X"]=Gate((0,0,0),[],X,"X","X")
components["Y"]=Gate((0,0,0),[],Y,"Y","Y")
components["Z"]=Gate((0,0,0),[],Z,"Z","Z")
components["H"]=Gate((0,0,0),[],H,"H","H")
components["CNOT"]=CNOT((0,0,0),[],"cx") #⊕
components["Measure"]=Measure((0,0,0),[],[],"∡")
components["Emitter"]=newEmitter()
components["Mirror"]=newMirror()
#=components["rx"]=Gate((0,0,0),[4],[],(state::Photons,photons::Array{Int},vars::Array{Number})->makemat(state.n,photons,rx(pi/vars[1])),(b::Board,photons::Array{Int})->deleteat!(photons,1:length(photons)),"rx")
components["ry"]=Gate((0,0,0),[4],[],(state::Photons,photons::Array{Int},vars::Array{Number})->makemat(state.n,photons,ry(pi/vars[1])),(b::Board,photons::Array{Int})->deleteat!(photons,1:length(photons)),"ry")
components["rz"]=Gate((0,0,0),[4],[],(state::Photons,photons::Array{Int},vars::Array{Number})->makemat(state.n,photons,rz(pi/vars[1])),(b::Board,photons::Array{Int})->deleteat!(photons,1:length(photons)),"rz")
=#
gatefuns=Dict{String,Function}() #define apply! for CustomGates

