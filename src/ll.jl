include("screen.jl")

components=Dict{String,Component}()
components["X"]=Gate((0,0,0),[],[],(state::Photons,photons::Array{Int})->makemat(state.n,photons,X),(b::Board,photons::Array{Int})->nothing,"X")
components["Y"]=Gate((0,0,0),[],[],(state::Photons,photons::Array{Int})->makemat(state.n,photons,Y),(b::Board,photons::Array{Int})->nothing,"Y")
components["Z"]=Gate((0,0,0),[],[],(state::Photons,photons::Array{Int})->makemat(state.n,photons,Z),(b::Board,photons::Array{Int})->nothing,"Z")
components["H"]=Gate((0,0,0),[],[],(state::Photons,photons::Array{Int})->makemat(state.n,photons,H),(b::Board,photons::Array{Int})->nothing,"H")
components["Measure"]=Measure((0,0,0),[],[],"∡")
components["Emitter"]=newEmitter()
