using Gtk, Graphics, Cairo
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
		nameentry=GtkEntry()
		loadbtn=GtkButton("Load")
		stepbtn=GtkButton("Step")
		resetbtn=GtkButton("Reset")
		set_gtk_property!(nameentry,:text,screen.board.name)
		scorelabel=GtkLabel("")
		newslabel=GtkLabel("")
		scalemaxfac=30
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
		placebtn=GtkButton("Place component at")
		expbtn=GtkButton("Expand board at (X,Y)")
		centerbtn=GtkButton("Center board on (X,Y)")
		deletecheck=GtkCheckButton("Remove on click")
		set_gtk_property!(deletecheck,:active,screen.delete)
		clabel1=GtkLabel("Place")
		clabel2=GtkLabel("")
		withlabel=GtkLabel("with")
		compscombo=GtkComboBoxText()
		staind=0;staindset=false
		for c in keys(components)
			push!(compscombo,c)
			if !staindset && c=="Emitter"
				staindset=true
			elseif !staindset
				staind+=1
			end
		end
		set_gtk_property!(compscombo,:active,staind)
		g=GtkGrid()
		row=1
		g[1,row]=savebtn
		g[2,row]=nameentry
		g[3,row]=loadbtn
		row+=1
		g[1,row]=scorelabel
		g[2,row]=newslabel
		row+=1
		g[2,row]=stepbtn
		g[3,row]=resetbtn
		row+=1
		g[1,row]=clabel1
		g[3,row]=clabel2
		g[2,row]=compscombo
		row+=1
		g[2,row]=deletecheck
		row+=1
		g[1,row]=zlabel
		g[2,row]=zoomscale
		row+=1
		g[1,row]=xlabel
		g[2,row]=xoscale
		row+=1
		g[1,row]=ylabel
		g[2,row]=yoscale
		row+=1
		g[2,row]=placebtn
		row+=1
		g[1,row]=xexplabel
		g[2,row]=spexpx
		row+=1
		g[1,row]=yexplabel
		g[2,row]=spexpy
		row+=1
		g[3,row]=withlabel
		g[2,row]=expbtn
		row+=1
		g[1,row]=shellexplabel
		g[2,row]=spexpshell
		row+=1
		g[2,row]=centerbtn
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
		id = signal_connect(stepbtn, "clicked") do widget
			step!(screen.board)
			drawboard(screen)
		end
		id = signal_connect(resetbtn, "clicked") do widget
			reset!(screen.board)
			drawboard(screen)
		end
		id = signal_connect(zoomscale, "value-changed") do widget
			wval=Gtk.G_.value(widget)
			screen.sizemod=wval/10
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			#center!(screen,(x,y))
			drawboard(screen)
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
		id = @guarded signal_connect(expbtn, "clicked") do widget
			x=Int(Gtk.G_.value(spexpx))
			y=Int(Gtk.G_.value(spexpy))
			r=Gtk.G_.value(spexpshell)
			remain=expandboard!(screen.board,Integer(r),[(x,y,2)])
			drawboard(screen)
		end
		id = signal_connect(centerbtn, "clicked") do widget
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			center!(screen,(x,y))
		end
		id = signal_connect(placebtn, "clicked") do widget
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			nu=components[Gtk.bytestring( GAccessor.active_text(compscombo) )]
			place!(screen.board,nu,[Int(x),Int(y)])
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
		nu=components[Gtk.bytestring( GAccessor.active_text(compscombo) )]
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
		exists=in(hex,keys(screen.board.map))
		if exists
			comp=screen.board[hex...]
			if screen.delete==true && screen.board[hex...]!=0
				remove!(board,hex)
			elseif comp==0
				place!(board,nu,hex)
			elseif isa(comp,Emitter) && (event.state&4 == 4) #ctrl
				comp.pol=X*comp.pol
			end
			drawboard(screen,ctx,w,h)
			reveal(widget)
		end
	end
	#placeseq!(board)	
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
		if isa(comp,Emitter)
			if comp.pol==[1,0]
				set_source_rgb(ctx,1,0,0)
			elseif comp.pol==[0,1]
				set_source_rgb(ctx,0,1,0)
			end
		elseif isa(comp,Measure) && length(comp.results)>0
			if comp.results[end]==0
				set_source_rgb(ctx,1,0,0)
			elseif comp.results[end]==1
				set_source_rgb(ctx,0,1,0)
			end
		else
			set_source_rgb(ctx,1,1,1)
		end
		arc(ctx,floc[1],floc[2],rad, 0, 2pi)
		fill(ctx)
		set_source_rgb(ctx,0,0,0) 
		select_font_face(ctx, "Sans", Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_BOLD);
		set_font_size(ctx, 2*rad);
		move_to(ctx, floc[1]-rad/2, floc[2]+rad/2);
		show_text(ctx, comp.label);
		stroke(ctx);
	end
	for p in screen.board.photons
		offset=(offx,offy)
		if p.loc[3]==1
			offset=offset.+(-cos(pi/6)*size,sin(pi/6)*size)
		elseif p.loc[3]==3
			offset=offset.+(-cos(pi/6)*size,-sin(pi/6)*size)
		end
		loc=hex_to_pixel(p.loc[1],p.loc[2],size)
		floc=(loc[1]+offset[1]+w/2,loc[2]+offset[2]+h/2)
		rad=size*0.866/3*abs(p.amp)
		set_source_rgb(ctx,1,1,1) 
		arc(ctx, floc[1],floc[2],rad, 0, 2pi)
		fill(ctx)
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
