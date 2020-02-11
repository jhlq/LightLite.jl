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
	selected::Tuple{Int,Int,Int}
	running::Bool
	fps::Number
end
function newScreen(board=0, sizemod=5, size=30, offsetx=0, offsety=0, bgcolor=(0,0,0), gridcolor=(1/2,1/2,1/2), grid=0, c=@GtkCanvas(), win=0, window=(900,700))
	if board==0
		board=newBoard()
	end
	screen=Screen(board,c,sizemod,size,offsetx,offsety,0,0,bgcolor,gridcolor,false,win,window,0,Dict(),(0,0,0),false,5)
	if win==0
		box=GtkBox(:h)
		savebtn=GtkButton("Save")
		nameentry=GtkEntry()
		loadbtn=GtkButton("Load")
		set_gtk_property!(nameentry,:text,screen.board.name)
		outputlabel=GtkLabel("")
		stepbtn=GtkButton("Step")
		resetbtn=GtkButton("Reset")
		runbtn=GtkButton("Run")
		spsteps=GtkSpinButton(1:1000000)
		Gtk.G_.value(spsteps,screen.board.maxsteps)
		run2btn=GtkButton("Run")
		spshots=GtkSpinButton(1:1000000)
		Gtk.G_.value(spshots,100)
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
		g[2,row]=outputlabel
		row+=1
		g[2,row]=stepbtn
		g[3,row]=resetbtn
		row+=1
		g[1,row]=runbtn
		g[2,row]=spsteps
		g[3,row]=GtkLabel("steps")
		row+=1
		g[1,row]=run2btn
		g[2,row]=spshots
		g[3,row]=GtkLabel("times")
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
		row+=1
		complab=GtkLabel("\nNothing selected.")
		g[2,row]=complab
		row+=1
		dirscombo=GtkComboBoxText()
		for c in keys(directions)
			push!(dirscombo,c)
		end
		id = @guarded signal_connect(dirscombo,"changed") do widget, others...
			screen.board[screen.selected...].dir=directions[Gtk.bytestring(GAccessor.active_text(dirscombo))]
			drawboard(screen)
		end
		g[2,row]=dirscombo
		spvar=GtkSpinButton(-1000:1000)
		id = @guarded signal_connect(spvar, "value-changed") do widget
			setvar!(screen.board[screen.selected...],Gtk.G_.value(widget))
			drawboard(screen)
		end
		row+=1
		g[2,row]=spvar
		push!(box,screen.c)	
		push!(box,g)
		screen.g=g
		screen.gui[:outputlabel]=outputlabel
		screen.gui[:yoscale]=yoscale
		screen.gui[:xoscale]=xoscale
		screen.gui[:zadj]=zadj
		screen.gui[:xadj]=xadj
		screen.gui[:yadj]=yadj
		screen.gui[:deletecheck]=deletecheck
		set_gtk_property!(box,:expand,screen.c,true)
		screen.win=GtkWindow(box,"LightLite",window[1],window[2])
		showall(screen.win)
		hide(dirscombo)
		hide(spvar)
		id = @guarded signal_connect(savebtn, "clicked") do widget
			screen.board.name=nameentry.text[String]
			save(screen.board)
			screen.win.title[String]="LightLite $(screen.board.name)"
		end
		id = @guarded signal_connect(loadbtn, "clicked") do widget
			nboard=load(nameentry.text[String])
			if nboard==nothing
				return
			end
			screen.board=nboard
			drawboard(screen)
			screen.win.title[String]="LightLite $(screen.board.name)"
		end
		id = @guarded signal_connect(stepbtn, "clicked") do widget
			screen.running=false
			step!(screen.board)
			drawboard(screen)
		end
		id = @guarded signal_connect(resetbtn, "clicked") do widget
			reset!(screen)
			drawboard(screen)
		end
		id = @guarded signal_connect(runbtn, "clicked") do widget
			screen.board.maxsteps=spsteps.value[Int]
			reset!(screen)
			@async run!(screen)
		end
		id = @guarded signal_connect(spsteps, "value-changed") do widget
			screen.board.maxsteps=spsteps.value[Int]
		end
		id = @guarded signal_connect(run2btn, "clicked") do widget
			shots=spshots.value[Int]
			d=run(screen.board,shots)
			println(d)
			str="\n"
			if !haskey(d,"shots")
				str*="No measures detected after $(screen.board.maxsteps) steps. Probabilities determined with one run.\n"
			else
				str*="Ran $shots times with steplimit $(screen.board.maxsteps).\n"
			end
			stra=String[]
			for k in keys(d)
				if k!="shots" && k!="tot" && d[k]!=0
					push!(stra,k*": $(d[k])\n")
				end
			end
			sort!(stra)
			for st in stra
				str*=st
			end
			info_dialog(str,screen.win)
		end
		id = @guarded signal_connect(zoomscale, "value-changed") do widget
			wval=Gtk.G_.value(widget)
			screen.sizemod=wval/10
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			drawboard(screen)
		end
		id = @guarded signal_connect(xoscale, "value-changed") do widget
			screen.panx=-Gtk.G_.value(widget)*10
			drawboard(screen)
		end
		id = @guarded signal_connect(yoscale, "value-changed") do widget
			screen.pany=-Gtk.G_.value(widget)*10
			drawboard(screen)
		end
		id = @guarded signal_connect(deletecheck, "clicked") do widget
			screen.delete=widget.active[Bool]
		end
		id = @guarded signal_connect(expbtn, "clicked") do widget
			x=Int(Gtk.G_.value(spexpx))
			y=Int(Gtk.G_.value(spexpy))
			r=Gtk.G_.value(spexpshell)
			remain=expandboard!(screen.board,Integer(r),[(x,y,2)])
			drawboard(screen)
		end
		id = @guarded signal_connect(centerbtn, "clicked") do widget
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			center!(screen,(x,y))
		end
		id = @guarded signal_connect(placebtn, "clicked") do widget
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
			if isa(comp,Emitter) && (event.state&4 == 4) #ctrl
				comp.pol=X*comp.pol
			elseif comp==0
				place!(screen.board,nu,hex)
			elseif screen.delete==true && comp!=0
				remove!(screen.board,hex)
				hide(dirscombo)
				hide(spvar)
				screen.selected=(0,0,0)
				GAccessor.text(complab,"")
			else
				hide(dirscombo)
				hide(spvar)
				screen.selected=hex
				GAccessor.text(complab,"\n"*id(comp)*" at "*string(hex))
				if :dir in fieldnames(typeof(comp))
					staind=0
					for c in keys(directions)
						if directions[c]==comp.dir
							break
						else
							staind+=1
						end
					end
					set_gtk_property!(dirscombo,:active,staind)
					show(dirscombo)
				else
					vars=getvars(comp)
					if length(vars)>0
						Gtk.G_.value(spvar,vars[1])
						show(spvar)
					end
				end
			end
			drawboard(screen,ctx,w,h)
			reveal(widget)
		end
	end
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
		if isa(comp,Mirror)
			set_source_rgb(ctx,0,0,1)
			coor=[cos(-pi/6+(comp.axis-1)*pi/3),sin(-pi/6+(comp.axis-1)*pi/3)]
			coor=1.5*rad.*coor
			move_to(ctx,floc[1]+coor[1],floc[2]+coor[2])
			rel_line_to(ctx,-2*coor[1],-2*coor[2])
			stroke(ctx)
			continue
		end
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
		if :dir in fieldnames(typeof(comp))
			pixdir=hex_to_pixel(comp.dir[1],comp.dir[2],rad)
			move_to(ctx,floc[1],floc[2])
			rel_line_to(ctx,pixdir[1],pixdir[2])
			stroke(ctx)
		end
		set_source_rgb(ctx,0,0,0) 
		select_font_face(ctx, "Sans", Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_BOLD);
		lablen=length(comp.label)
		set_font_size(ctx, rad+rad/lablen);
		move_to(ctx, floc[1]-rad+rad/(lablen*2), floc[2]+rad/2);
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
		rad=size*0.866/2*abs(p.amp)
		set_source_rgba(ctx,1,1,1,0.7) 
		arc(ctx, floc[1],floc[2],rad, 0, 2pi)
		fill(ctx)
	end
	op=length(screen.board.output)>15 ? "..."*screen.board.output[end-13:end] : screen.board.output
	GAccessor.text(screen.gui[:outputlabel],"Output: "*op)
	#showall(screen.win) #should probably look up the difference between all these revealing methods
	reveal(screen.c)
end
function drawboard(screen::Screen)
	ctx=getgc(screen.c)
	h=height(screen.c)
	w=width(screen.c)
	drawboard(screen,ctx,w,h)
end
function run!(screen::Screen,steps::Int)
	if !screen.running
		return
	elseif steps<1
		screen.running=false
		return
	end
	t0=time()
	step!(screen.board)
	steps-=1
	drawboard(screen)
	tt=1/screen.fps
	t=time()-t0
	rt=tt-t
	if rt>0
		sleep(rt)
	end
	run!(screen,steps)
end
function run!(screen::Screen)
	if screen.running
		println("Already running.")
		return
	end
	screen.running=true
	run!(screen,screen.board.maxsteps)
end
function reset!(screen::Screen)
	screen.running=false
	reset!(screen.board)
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
