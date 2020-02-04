mutable struct Screen
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
function newScreen(board=0,sizemod=5,size=30,offsetx=0,offsety=0,bgcolor=(0,0,0),gridcolor=(1/2,1/2,1/2),grid=0,c=@GtkCanvas())
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

