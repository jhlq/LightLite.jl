module LightLite
export newgame, save, loadgame, expandboard!, checkharvest, center, setcolorset, getgroup, newunit, units, sync!, string2game, loadgame!, placeunit!, Unit, Game, Group
using Gtk, Graphics

dir=joinpath(homedir(),".lightlite","saves")
if !ispath(dir)
	mkpath(dir)
end

include("ll.jl")

end # module
