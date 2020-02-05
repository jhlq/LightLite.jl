include("screen.jl")

gates=Dict{String,Gate}()
gates["X"]=Gate((0,0,0),[],(state::Photons,photons::Array{Int})->makemat(state.n,photons,X),(b::Board,photons::Array{Int})->nothing)


