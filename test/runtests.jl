using LightLite
using Test

include("photonstests.jl")

g=makegrid(1)
@test length(g)==13

b=newBoard()
l=b[0,0]
@test length(l.photons)==0
@test l.component==nothing
place!(b,newEmitter(),[0,0])
@test isa(b[0,0],Emitter)
@test b.emitted==false
step!(b)
@test b.emitted==true
@test length(b.photons)==1
@test b.photons[1].loc==b.emitters[1].loc.+b.emitters.dir
