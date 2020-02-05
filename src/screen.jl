using Gtk, Graphics
include("board.jl")

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
	delete::Bool
	win #GtkWindow
	window #initial aspect ratio, funnily named...
	g #GtkGrid
	gui::Dict #Gtk placeholder
end
function newScreen(board=0, sizemod=5, size=30, offsetx=0, offsety=0, bgcolor=(0,0,0), gridcolor=(1/2,1/2,1/2), grid=0, c=@GtkCanvas(), win=0, window=(900,700))
	if board==0
		board=newBoard()
	end
	screen=Screen(board,c,sizemod,size,offsetx,offsety,0,0,bgcolor,gridcolor,false,win,window,0,Dict())
	if win==0
		box=GtkBox(:h)
		savebtn=GtkButton("Save")
		loadbtn=GtkButton("Load")
		nameentry=GtkEntry()
		set_gtk_property!(nameentry,:text,screen.board.name)
		scorelabel=GtkLabel("")
		newslabel=GtkLabel("")
		scalemaxfac=100
		zoomscale = GtkScale(false, 1:scalemaxfac*10)
		zlabel=GtkLabel("Zoom")
		zadj=Gtk.Adjustment(zoomscale)
		set_gtk_property!(zadj,:value,screen.sizemod*10)
		omax=scalemaxfac*30
		xoscale = GtkScale(false, -omax:omax)
		xlabel=GtkLabel("Pan x")
		xadj=Gtk.Adjustment(xoscale)
		set_gtk_property!(xadj,:value,screen.panx)
		yoscale = GtkScale(false, -omax:omax)
		ylabel=GtkLabel("Pan y")
		yadj=Gtk.Adjustment(yoscale)
		set_gtk_property!(yadj,:value,screen.pany)
		spexpx=GtkSpinButton(-1000:1000)
		Gtk.G_.value(spexpx,0)
		spexpy=GtkSpinButton(-1000:1000)
		Gtk.G_.value(spexpy,0)
		spexpshell=GtkSpinButton(0:3000)
		Gtk.G_.value(spexpshell,screen.board.shells+1)
		xexplabel=GtkLabel("X")
		yexplabel=GtkLabel("Y")
		shellexplabel=GtkLabel("radius")
		placebtn=GtkButton("Place comp at")
		expbtn=GtkButton("Expand board at (X,Y)")
		centerbtn=GtkButton("Center board on (X,Y)")
		deletecheck=GtkCheckButton("Enable deletion")
		set_gtk_property!(deletecheck,:active,screen.delete)
		clabel1=GtkLabel("Place")
		clabel2=GtkLabel("comps")
		withlabel=GtkLabel("with")
		compscombo=GtkComboBoxText()
		staind=0;staindset=false
		for c in keys(gates)
			push!(compscombo,c)
			if !staindset && c=="X"
				staindset=true
			elseif !staindset
				staind+=1
			end
		end
		set_gtk_property!(compscombo,:active,staind)
		g=GtkGrid()
		g[1,1]=savebtn
		g[2,1]=nameentry
		g[3,1]=loadbtn
		g[1,2]=scorelabel
		g[2,2]=newslabel
		g[2,4]=deletecheck
		g[1,5]=clabel1
		g[3,5]=clabel2
		g[2,5]=compscombo
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
		push!(box,screen.c)	
		push!(box,g)
		screen.g=g
		screen.gui[:scorelabel]=scorelabel
		screen.gui[:newslabel]=newslabel
		screen.gui[:yoscale]=yoscale
		screen.gui[:xoscale]=xoscale
		screen.gui[:zadj]=zadj
		screen.gui[:xadj]=xadj
		screen.gui[:yadj]=yadj
		screen.gui[:deletecheck]=deletecheck
		set_gtk_property!(box,:expand,screen.c,true)
		screen.win=GtkWindow(box,"Weilianqi $(screen.board.name)",window[1],window[2])
		showall(screen.win)
		id = signal_connect(savebtn, "clicked") do widget
			screen.board.name=nameentry.text[String]
			save(screen.board)
		end
		id = signal_connect(loadbtn, "clicked") do widget
			@sigatom load(nameentry.text[String])
		end
		signal_connect(compscombo, "changed") do widget, others...
			#compname=Gtk.bytestring( GAccessor.active_text(compscombo) ) 
			#screen.compparams[end]=compname
		end
		id = signal_connect(zoomscale, "value-changed") do widget
			wval=Gtk.G_.value(widget)
			screen.sizemod=wval/10+exp(wval/100)
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			center!(screen,(x,y))
		end
		id = signal_connect(xoscale, "value-changed") do widget
			screen.panx=-Gtk.G_.value(widget)*10
			drawboard(screen)
		end
		id = signal_connect(yoscale, "value-changed") do widget
			screen.pany=-Gtk.G_.value(widget)*10
			drawboard(screen)
		end
		id = signal_connect(deletecheck, "clicked") do widget
			screen.delete=widget.active[Bool]
		end
		id = signal_connect(expbtn, "clicked") do widget
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			r=Gtk.G_.value(spexpshell)
			remain=expandboard!(screen,Integer(r),[(x,y,2)])
		end
		id = signal_connect(centerbtn, "clicked") do widget
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			center(screen,(x,y))
		end
		id = signal_connect(placebtn, "clicked") do widget
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			nu=gates[Gtk.bytestring( GAccessor.active_text(compscombo) )]
			place!(screen,nu)
			sync!(screen)
			drawboard(screen)
		end
	end
	@guarded function drawsignal(widget)
		ctx=getgc(widget)
		h=height(widget)
		w=width(widget)
		screen.window=(w,h)
		screen.size=screen.window[2]/(screen.board.shells*screen.sizemod)
		drawboard(screen,ctx,w,h)
	end
	draw(drawsignal,screen.c)
	screen.c.mouse.button1press = @guarded (widget, event) -> begin
		ctx=getgc(widget)
		h=height(screen.c)
		w=width(screen.c)
		#nu=newcomp(screen.color,0,gates[Gtk.bytestring( GAccessor.active_text(compscombo) )])
		nu=gates[Gtk.bytestring( GAccessor.active_text(compscombo) )]
		size=screen.size
		offx=screen.offsetx+screen.panx
		offy=screen.offsety+screen.pany
		q,r=pixel_to_hex(event.x-w/2-offx,event.y-h/2-offy,size)
		maindiff=abs(round(q)-q)+abs(round(r)-r)
		qup,rup=pixel_to_hex(event.x-w/2+size*cos(pi/6)-offx,event.y-h/2+sin(pi/6)*size-offy,size)
		updiff=abs(round(qup)-qup)+abs(round(rup)-rup)
		qdown,rdown=pixel_to_hex(event.x-w/2+size*cos(pi/6)-offx,event.y-h/2-sin(pi/6)*size-offy,size)
		downdiff=abs(round(qdown)-qdown)+abs(round(rdown)-rdown)
		best=findmin([maindiff,updiff,downdiff])[2]
		hex=[(round(Int,q),round(Int,r),2),(round(Int,qup),round(Int,rup),3),(round(Int,qdown),round(Int,rdown),1)][best]
		#nu.loc=hex
		exists=in(hex,keys(screen.board.map))
		if exists
			if screen.delete==true# && screen.map[hex]!=0 && isa(screen.map[hex],Unit)
				remove!(board,screen.map[hex])
			else#if screen.map[hex]==0 && placeable(screen,nu) 
				place!(board,nu,hex)
			end
			#sync!(screen)
			drawboard(screen,ctx,w,h)
			reveal(widget)
		end
		#sync!(screen) #sync twice to correct corruptions of reality, usually works
	end
	#placeseq!(board)	
	#sync!(screen)
	show(screen.c)
	return screen
end

function hex_to_pixel(q,r,size)
    x = size * sqrt(3) * (q + r/2)
    y = size * 3/2 * r
    return x, y
end
function pixel_to_hex(x,y,size)
    q = (x * sqrt(3)/3 - y / 3) / size
    r = y * 2/3 / size
    return (q, r)
end
function triangle(ctx,x,y,size,up=-1)
	polygon(ctx, [Point(x,y),Point(x+size,y),Point(x+size/2,y+up*size)])
	fill(ctx)
end
function hexlines(ctx,x,y,size)
	size*=2
	move_to(ctx,x-size/4,y-size*sin(pi/3)/2)
	rel_line_to(ctx,size/2,size*sin(pi/3))
	move_to(ctx,x-size/2,y)
	rel_line_to(ctx,size,0)
	move_to(ctx,x+size/4,y-size*sin(pi/3)/2)
	rel_line_to(ctx,-size/2,size*sin(pi/3))
	stroke(ctx)
end
function drawboard(screen,ctx,w,h)
	screen.size=screen.window[2]/(screen.board.shells*screen.sizemod)
	size=screen.size
	rectangle(ctx, 0, 0, w, h)
	set_source_rgb(ctx, screen.bgcolor...)
	fill(ctx)
	#set_source_rgb(ctx, screen.color...)
	#arc(ctx, size, size, 3size, 0, 2pi)
	#fill(ctx)
	offx=screen.offsetx+screen.panx
	offy=screen.offsety+screen.pany
	set_source_rgb(ctx, screen.gridcolor...)
	for loc in screen.board.grid
		if loc[3]==2
			x,y=hex_to_pixel(loc[1],loc[2],size)
			hexlines(ctx,x+w/2+offx,y+h/2+offy,size)
		end
	end
	for comp in screen.board.components
		offset=(offx,offy)
		if comp.loc[3]==1
			offset=offset.+(-cos(pi/6)*size,sin(pi/6)*size)
		elseif comp.loc[3]==3
			offset=offset.+(-cos(pi/6)*size,-sin(pi/6)*size)
		end
		loc=hex_to_pixel(comp.loc[1],comp.loc[2],size)
		floc=(loc[1]+offset[1]+w/2,loc[2]+offset[2]+h/2)
		rad=size*0.866/2
		#comp border:
		set_source_rgb(ctx,screen.gridcolor...) 
		arc(ctx, floc[1],floc[2],rad+1, 0, 2pi)
		stroke(ctx)
		set_source_rgb(ctx,(1,1,1)...)
		#set_source_rgb(ctx,comp.color...)
		arc(ctx,floc[1],floc[2],rad, 0, 2pi) #why isn't the circle radius the distance between locs? Whyyyy whyyyy someone pleeease fiiix. It's kinda cute with those small dots. Also they fit perfectly within the triangles
		fill(ctx)
		#=if !isempty(comp.graphic)
			set_source_rgb(ctx,screen.bgcolor...)
			points=Point[]
			for p in comp.graphic
				push!(points,Point(floc[1]+rad*p[1],floc[2]+rad*p[2]))
			end
			polygon(ctx,points)
			fill(ctx)
		end=#
	end
	#showall(screen.win) #should probably look up the difference between all these revealing methods
	reveal(screen.c)
end
function drawboard(screen::Screen)
	ctx=getgc(screen.c)
	h=height(screen.c)
	w=width(screen.c)
	drawboard(screen,ctx,w,h)
end

function expandboard!(screen::Screen,shells::Integer=6,initlocs=[(6,6,2)],reveal=true)
	patch=makegrid(shells,initlocs)
	for loc in patch
		if !in(loc,keys(screen.map))
			screen.map[loc]=0
			push!(screen.board.grid,loc)
		end
	end
	push!(screen.sequence,(:expand,[shells,initlocs]))
	if reveal #without this there is sometimes some severe error (when loadicing)
		drawboard(screen)
	end
	return "<3"
end
function zoom!(screen,factor)
	screen.sizemod*=factor
	drawboard(screen)
end
function center!(screen,hex)
	#screen.sizemod=Gtk.G_.value(screen.gui[:zadj])/10
	screen.size=screen.window[2]/(screen.board.shells*screen.sizemod)
	loc=hex_to_pixel(hex[1],hex[2],screen.size)
	screen.offsetx=-loc[1]+Gtk.G_.value(screen.gui[:xadj])
	screen.offsety=-loc[2]+Gtk.G_.value(screen.gui[:yadj])
	drawboard(screen)
	return true
end
