module LightLite
export Photons, photons, Board, newBoard, place!, gates, expandboard!, Screen, newScreen, center, setcolorset, sync!, string2board, load!

dir=joinpath(homedir(),".lightlite","circuits")
if !ispath(dir)
	mkpath(dir)
end

include("ll.jl")

end # module
