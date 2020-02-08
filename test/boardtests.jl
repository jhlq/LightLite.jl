g=makegrid(1)
@test length(g)==13

b=newBoard()
l=b[0,0]
@test l==nothing
place!(b,newEmitter(),[0,0])
@test isa(b[0,0],Emitter)
@test b.emitted==false
@test length(b.photons)==0
step!(b)
@test b.emitted==true
@test length(b.photons)==1
@test b.photons[1].loc==b.emitters[1].loc.+b.emitters[1].dir
step!(b)
@test b.photons[1].loc==b.emitters[1].loc.+b.emitters[1].dir.*2
@test b.photons[1].amp==0
step!(b);step!(b);step!(b)
@test b.photons[1].amp==1
reset!(b)
@test b.emitted==false
@test length(b.photons)==0
place!(b,gates["X"],[0,1])
b.emitters[1].dir=(0,1,0)
step!(b)
@test p(b.state,"1")==1

b=newBoard()
place!(b,newEmitter(),[0,0])
place!(b,newMirror(),[1,0])
step!(b,10)
@test b.photons[1].dir!=(1,0,0)
@test b.photons[1].loc[1]<0 || b.photons[1].loc[2]>0

b=newBoard(examples["Bellstate"])
run!(b)
@test b.output=="11" || b.output=="00"
d=run(b)
@test isapprox(d["11"]+d["00"],1)

b=newBoard(examples["and"])
setinput!(b,"00")
d=run(b)
@test isapprox(d["0"],1)
setinput!(b,"10")
d=run(b)
@test isapprox(d["0"],1)
setinput!(b,"01")
d=run(b)
@test isapprox(d["0"],1)
setinput!(b,"11")
d=run(b)
@test isapprox(d["1"],1)
