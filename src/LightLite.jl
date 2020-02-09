module LightLite
export Photon, photon, Photons, photons, p, states, X, Y, Z, H, rx, ry, rz, cnot, toffoli!, apply!, measure!, Board, newBoard, components, place!, step!, reset!, setinput!, gatefuns, trap!, run!, run, Screen, newScreen, load, load!, examples, example

dir=joinpath(homedir(),".lightlite","circuits")
if !ispath(dir)
	mkpath(dir)
end

include("ll.jl")

end # module
