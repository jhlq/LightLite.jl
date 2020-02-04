using LinearAlgebra
mutable struct Photon
	pol::Array{Complex{AbstractFloat},1}
end
photon()=Photon([1,0])
p(c::Complex)=abs(c^2)
p(pho::Photon)=p(pho.pol[2])
X=[0 1;1 0]
Y=[0 -1im;1im 0]
Z=[1 0;0 -1]
H=[1 1;1 -1]/sqrt(2)
S=[1 0;0 1im]
rx(th)=[cos(th/2) -1im*sin(th/2);-1im*sin(th/2) cos(th/2)]
ry(th)=[cos(th/2) -sin(th/2);sin(th/2) cos(th/2)]
rz(th)=[1 0;0 exp(1im*th)]

function apply!(pho::Photon,gate::Matrix)
	pho.pol=gate*pho.pol
end
mutable struct Photons
	n::Int
	state::Array{Complex{AbstractFloat},1}
	labels::Array{String}
end
function photons(n::Int)
	s=zeros(Complex{AbstractFloat},2^n)
	s[1]=1
	l=["0","1"]
	for i in 2:n
		l=kron(l,["0","1"])
	end
	ps=Photons(n,s,l)
	return ps
end
function makemat(n::Int,ia::Array{Int},gates::Array)
	mc=Matrix[]
	for i in 1:n
		push!(mc,I(2))
	end
	for iai in 1:length(ia)
		mc[ia[iai]]=gates[iai]
	end
	return kron(mc...)
	m=kron(mc[1],mc[2])
	for i in 3:n
		m=kron(m,mc[i])
	end
	return m
end
function apply!(ps::Photons,i::Int,gate::Matrix)
	m=makemat(ps.n,[i],[gate])
	ps.state=m*ps.state
end
function apply!(ps::Photons,ia::Array{Int},gates::Array)
	m=makemat(ps.n,ia,gates)
	ps.state=m*ps.state
end
function apply!(ps::Photons,ct::Array{Int},f::Function)
	m=f(ct,ps)
	ps.state=m*ps.state
end
function measure!(ps::Photons,n::Int)
	p0=0.0
	w0=Complex{AbstractFloat}[]
	w1=Complex{AbstractFloat}[]
	for i in 1:length(ps.state)
		if ps.labels[i][n]=='0'
			p0+=p(ps.state[i])
			push!(w0,ps.state[i])
			push!(w1,0)
		else
			push!(w1,ps.state[i])
			push!(w0,0)
		end
	end
	if rand()>p0
		w1=w1/sqrt(1-p0)
		ps.state=w1
		return 1
	else
		w0=w0/sqrt(p0)
		ps.state=w0
		return 0
	end
end
function p(ps::Photons)
	d=Dict{String,AbstractFloat}()
	tot=0.0
	for i in 1:length(ps.labels)
		pr=p(ps.state[i])
		d[ps.labels[i]]=pr
		tot+=pr
	end
	d["tot"]=tot
	return d
end
function matches(label::String,s::String)
	for i in 1:length(label)
		if !(s[i]=='*' || label[i]==s[i])
			return false
		end
	end
	return true
end
function states(ps::Photons,s::String)
	if length(ps.labels[1])!=length(s)
		error("State contains "*string(length(ps.labels[1]))*" qubits but "*s*" refers "*string(length(s))*".")
	end
	ms=Int[]
	for i in 1:length(ps.labels)
		if matches(ps.labels[i],s)
			push!(ms,i)
		end
	end
	if length(ms)==0
		error(s*" matches no states.")
	end
	return ms
end
function p(ps::Photons,s::String)
	if in('*',s)
		ws=states(ps,s)
		d=Dict{String,AbstractFloat}()
		tot=0.0
		for w in ws
			tp=p(ps.state[w])
			d[ps.labels[w]]=tp
			tot+=tp
		end
		d[s]=tot
		d["tot"]=tot
		return d
	end
	si=findfirst(x->x==s,ps.labels)
	if !isa(si,Int)
		error("State "*s*" not found.")
	end
	return abs(ps.state[si])^2
end
function cnot(ct::Array{Int},ps::Photons)
	control=ct[1]
	target=ct[2]
	l=length(ps.state)
	m=zeros(l,l)
	for column in 1:l
		s=ps.labels[column]
		c=parse(Bool,s[control])
		if c
			t=parse(Bool,s[target])
			ns=s[1:target-1]*string(Int(!t))*s[target+1:end]
			nsi=findfirst(x->x==ns,ps.labels)
			m[column,nsi]=1
		else
			m[column,column]=1
		end
	end
	return m
end

function makegrid(layers=3,startlocs=[(0,0,2)],groundlevel=false)
	grid=Set{Tuple}()
	push!(grid,startlocs...)
	connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0), (0,0,1),(1,0,1),(0,1,1),(0,0,-1),(1,0,-1),(1,-1,-1)]
	if groundlevel
		connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0)]
	end
	for layer in 1:layers
		tgrid=Array{Tuple,1}()
		for loc in grid
			if loc[3]==2
				for c in connections
					x,y,z=loc
					x+=c[1];y+=c[2];z+=c[3]
					push!(tgrid,(x,y,z))
				end
			end
		end
		for t in tgrid
			push!(grid,t)
		end
	end
	return grid
end
mutable struct Board
	grid
	map
end
function newboard(shells=6,initlocs=[(0,0,2)],grid=0,map=Dict())
	if grid==0
		grid=makegrid(shells,initlocs)
	end
	for loc in grid
		map[loc]=0
	end
	board=Board(grid,map)
	return board
end
mutable struct ScreenBoard
	board::Board
	c #GtkCanvas
	sizemod::Number #zoom
	size::Number
	offsetx::Number 
	offsety::Number
	panx::Number 
	pany::Number
	bgcolor #background
	gridcolor
end
function newscreenboard(board=0,sizemod=5,size=30,offsetx=0,offsety=0,bgcolor=(0,0,0),gridcolor=(1/2,1/2,1/2),grid=0,c=@GtkCanvas())
	if board==0
		board=newboard()
	end
	sb=ScreenBoard(board,c,sizemod,size,offsetx,offsety,0,0,bgcolor,gridcolor)
	return sb
end
function newwindow(name=string(round(Integer,time())),boardparams=[];unitparams=["standard"],map=Dict(),unit=0,color=(1,0,0),colors=colorsets[1],colind=1,colmax=3,colock=false,delete=false,sequence=[newunit((1,0,0),(-1,1,2),units["queen"]),newunit((0,1,0),(0,-1,2),units["queen"]),newunit((0,0,1),(1,0,2),units["queen"])],board=0,printscore=false,points=[0.0,0,0,0,0],season=0,win=0,window=(900,700),autoharvest=true)
	if board==0
		board=newboard(boardparams...)
	end
	for loc in board.grid
		map[loc]=0
	end
	game=Game(name,map,Group[],Unit[],Unit[],unitparams,color,colors,colind,colmax, colock,delete,sequence,board,printscore,points,season,win,window,0,0,Dict(),autoharvest)
	if win==0
		box=GtkBox(:h)
		savebtn=GtkButton("Save")
		loadbtn=GtkButton("Load")
		nameentry=GtkEntry()
		set_gtk_property!(nameentry,:text,game.name)
		scorelabel=GtkLabel("")#pointslabel(game))
		newslabel=GtkLabel("")#infolabel(game))
		passbtn=GtkButton("Next color")
		backbtn=GtkButton("Prev color")
		#colabel=GtkLabel(string(game.color))
		#autoharvestcheck = GtkCheckButton("Autoharvest")
		#set_gtk_property!(autoharvestcheck,:active,game.autoharvest)
		colockcheck=GtkCheckButton("Lock color")
		set_gtk_property!(colockcheck,:active,game.colock)
		scalemaxfac=100
		zoomscale = GtkScale(false, 1:scalemaxfac*10)
		zlabel=GtkLabel("Zoom")
		zadj=Gtk.Adjustment(zoomscale)
		set_gtk_property!(zadj,:value,game.board.sizemod*10)
		omax=scalemaxfac*30
		xoscale = GtkScale(false, -omax:omax)
		xlabel=GtkLabel("Pan x")
		xadj=Gtk.Adjustment(xoscale)
		set_gtk_property!(xadj,:value,game.board.panx)
		yoscale = GtkScale(false, -omax:omax)
		ylabel=GtkLabel("Pan y")
		yadj=Gtk.Adjustment(yoscale)
		set_gtk_property!(yadj,:value,game.board.pany)
		spexpx=GtkSpinButton(-1000:1000)
		Gtk.G_.value(spexpx,0)
		spexpy=GtkSpinButton(-1000:1000)
		Gtk.G_.value(spexpy,0)
		spexpshell=GtkSpinButton(0:3000)
		Gtk.G_.value(spexpshell,game.board.shells+1)
		xexplabel=GtkLabel("X")
		yexplabel=GtkLabel("Y")
		shellexplabel=GtkLabel("radius")
		placebtn=GtkButton("Place unit at")
		expbtn=GtkButton("Expand board at (X,Y)")
		centerbtn=GtkButton("Center board on (X,Y)")
		deletecheck=GtkCheckButton("Enable deletion")
		set_gtk_property!(deletecheck,:active,game.delete)
		clabel1=GtkLabel("Place")
		clabel2=GtkLabel("units")
		withlabel=GtkLabel("with")
		unitscombo=GtkComboBoxText()
		staind=0;staindset=false
		for c in keys(units)
			push!(unitscombo,c)
			if !staindset && c=="standard"
				staindset=true
			elseif !staindset
				staind+=1
			end
		end
		set_gtk_property!(unitscombo,:active,staind)
		g=GtkGrid()
		g[1,1]=savebtn
		g[2,1]=nameentry
		g[3,1]=loadbtn
		g[1,2]=scorelabel
		g[2,2]=newslabel
		g[2,4]=deletecheck
		g[1,3]=passbtn
		g[1,4]=backbtn
		g[2,3]=colockcheck
		g[1,5]=clabel1
		g[3,5]=clabel2
		g[2,5]=unitscombo
		g[1,6]=zlabel
		g[1,7]=xlabel
		g[1,8]=ylabel
		g[2,6]=zoomscale
		g[2,7]=xoscale
		g[2,8]=yoscale
		g[2,9]=placebtn
		g[1,10]=xexplabel
		g[1,11]=yexplabel
		g[2,10]=spexpx
		g[2,11]=spexpy
		g[1,13]=shellexplabel
		g[2,13]=spexpshell
		g[3,12]=withlabel
		g[2,12]=expbtn
		g[2,14]=centerbtn
		push!(box,game.board.c)	
		push!(box,g)
		game.g=g
		game.gui[:scorelabel]=scorelabel
		game.gui[:newslabel]=newslabel
		game.gui[:yoscale]=yoscale
		game.gui[:xoscale]=xoscale
		game.gui[:zadj]=zadj
		game.gui[:xadj]=xadj
		game.gui[:yadj]=yadj
		game.gui[:colockcheck]=colockcheck
		game.gui[:deletecheck]=deletecheck
		set_gtk_property!(box,:expand,game.board.c,true)
		game.win=GtkWindow(box,"Weilianqi $name",window[1],window[2])
		showall(game.win)
		id = signal_connect(savebtn, "clicked") do widget
			game.name=nameentry.text[String]
			save(game)
		end
		id = signal_connect(loadbtn, "clicked") do widget
			@sigatom loadgame(nameentry.text[String])
		end
		id = signal_connect(passbtn, "clicked") do widget
			pass!(game,colockcheck.active[Bool])
		end
		id = signal_connect(backbtn, "clicked") do widget
			pass!(game,colockcheck.active[Bool],true)
		end
		signal_connect(unitscombo, "changed") do widget, others...
			unitname=Gtk.bytestring( GAccessor.active_text(unitscombo) ) 
			game.unitparams[end]=unitname
		end
		id = signal_connect(zoomscale, "value-changed") do widget
			wval=Gtk.G_.value(widget)
			game.board.sizemod=wval/10+exp(wval/100)
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			center(game,(x,y))
		end
		id = signal_connect(xoscale, "value-changed") do widget
			game.board.panx=-Gtk.G_.value(widget)*10
			drawboard(game)
		end
		id = signal_connect(yoscale, "value-changed") do widget
			game.board.pany=-Gtk.G_.value(widget)*10
			drawboard(game)
		end
		id = signal_connect(colockcheck, "clicked") do widget
			game.colock=widget.active[Bool]
		end
		id = signal_connect(deletecheck, "clicked") do widget
			game.delete=widget.active[Bool]
		end
		id = signal_connect(expbtn, "clicked") do widget
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			r=Gtk.G_.value(spexpshell)
			remain=expandboard!(game,Integer(r),[(x,y,2)])
		end
		id = signal_connect(centerbtn, "clicked") do widget
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			center(game,(x,y))
		end
		id = signal_connect(placebtn, "clicked") do widget
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			nu=newunit(game.color,(x,y,2),units[game.unitparams[end]])
			placeunit!(game,nu)
			sync!(game)
			drawboard(game)
		end
	end
	@guarded function drawsignal(widget)
		ctx=getgc(widget)
		h=height(widget)
		w=width(widget)
		game.window=(w,h)
		game.board.size=game.window[2]/(game.board.shells*game.board.sizemod)
		drawboard(game,ctx,w,h)
	end
	draw(drawsignal,game.board.c)
	game.board.c.mouse.button1press = @guarded (widget, event) -> begin
		ctx=getgc(widget)
		h=height(game.board.c)
		w=width(game.board.c)
		nu=newunit(game.color,0,units[game.unitparams[end]])
		size=game.board.size
		offx=game.board.offsetx+game.board.panx
		offy=game.board.offsety+game.board.pany
		q,r=pixel_to_hex(event.x-w/2-offx,event.y-h/2-offy,size)
		maindiff=abs(round(q)-q)+abs(round(r)-r)
		qup,rup=pixel_to_hex(event.x-w/2+size*cos(pi/6)-offx,event.y-h/2+sin(pi/6)*size-offy,size)
		updiff=abs(round(qup)-qup)+abs(round(rup)-rup)
		qdown,rdown=pixel_to_hex(event.x-w/2+size*cos(pi/6)-offx,event.y-h/2-sin(pi/6)*size-offy,size)
		downdiff=abs(round(qdown)-qdown)+abs(round(rdown)-rdown)
		if length(nu.pl)==1
			best=(nu.pl[1]+1)%3+1
		else
			best=findmin([maindiff,updiff,downdiff])[2]
		end
		hex=[(round(Int,q),round(Int,r),2),(round(Int,qup),round(Int,rup),3),(round(Int,qdown),round(Int,rdown),1)][best]
		nu.loc=hex
		exists=in(hex,keys(game.map))
		if exists
			if game.delete==true && game.map[hex]!=0 && isa(game.map[hex],Unit)
				removeunit!(game,game.map[hex])
			elseif game.map[hex]==0 && placeable(game,nu) 
				placeunit!(game,nu)
				if !game.colock
					game.colind=game.colind%game.colmax+1
					game.color=game.colors[game.colind]
				end
			end
			sync!(game)
			drawboard(game,ctx,w,h)
			reveal(widget)
		end
		sync!(game) #sync twice to correct corruptions of reality, usually works
	end
	placeseq!(game)	
	sync!(game)
	show(game.board.c)
	return game
end

