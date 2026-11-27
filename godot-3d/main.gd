extends Node3D
var toon:Shader=load("res://toon.gdshader")
var outl:Shader=load("res://outline.gdshader")
var player:Node3D
var arml:Node3D; var armr:Node3D; var legl:Node3D; var legr:Node3D
var cam:Camera3D
var joy_vec:=Vector2.ZERO
var joy_id:=-1
var joy_center:=Vector2.ZERO
var knob:Control; var base:Control
var walk_t:=0.0
var last_min:=-1
var mode:='select'
var ui:CanvasLayer
var scene_layer:Control
var scene_lines:Array=[]
var scene_i:=0
var scene_done:={}
var sc_bg:TextureRect; var sc_name:Label; var sc_txt:Label; var sc_face:TextureRect; var hud_face:TextureRect
var select_layer:Control
var who_pick:='girl'
var stats:={'الدراسة':50,'العلاقات':50,'الصحة':50,'الفلوس':50,'المجتمع':50}
var stats_layer:Control
var choice_btns:Array=[]
var stat_lbls:Array=[]
var choices_on:=false
var hud_time:Label; var hud_clock:Control; var hud_min:=480.0
var petals:CPUParticles3D

var mcache:={}
var no_outline:=false
func mat(c:Color, outline:=true, th:=0.025)->Material:
	if no_outline: outline=false
	var key:=str(c)+str(outline)+str(th)
	if mcache.has(key): return mcache[key]
	var m:=ShaderMaterial.new(); m.shader=toon; m.set_shader_parameter("albedo",c)
	if outline:
		var o:=ShaderMaterial.new(); o.shader=outl; o.set_shader_parameter("thickness",th); m.next_pass=o
	mcache[key]=m
	return m
var batching:=false
var batches:={}
func mesh_xf(parent:Node,m:Mesh,c:Color,xf:Transform3D,outline:=true,th:=0.025)->MeshInstance3D:
	var mt:=mat(c,outline,th)
	if batching and (parent==self or (parent is Node3D and parent.get_parent()==self and parent!=player)):
		var pxf:Transform3D=Transform3D.IDENTITY if parent==self else (parent as Node3D).transform
		var fx_:=pxf*xf; bt(mt,fx_.origin).append_from(m,0,Transform3D(Basis(),-chunk_o(fx_.origin))*fx_)
		return MeshInstance3D.new()
	var n:=MeshInstance3D.new(); n.mesh=m; n.material_override=mt; n.transform=xf; parent.add_child(n); return n
func chunk_o(o:Vector3)->Vector3:
	return Vector3(floor(o.x/45.0)*45.0+22.5,0,floor(o.z/45.0)*45.0+22.5)
func bt(mt:Material,o:Vector3)->SurfaceTool:
	var key:=str(mt.get_instance_id())+"_"+str(int(floor(o.x/45.0)))+"_"+str(int(floor(o.z/45.0)))
	if not batches.has(key): batches[key]={"mt":mt,"st":SurfaceTool.new(),"o":chunk_o(o)}
	return batches[key].st
func flush_batches():
	for k in batches.keys():
		var e:Dictionary=batches[k]
		var st:SurfaceTool=e.st
		var n:=MeshInstance3D.new(); n.mesh=st.commit(); n.material_override=e.mt; n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; n.position=e.o; n.visibility_range_end=(85.0 if absf(e.o.x)<400 else 0.0); add_child(n)
	batches.clear(); batching=false
func mesh(parent:Node,m:Mesh,c:Color,pos:=Vector3.ZERO,outline:=true,th:=0.025)->MeshInstance3D:
	if batching: return mesh_xf(parent,m,c,Transform3D(Basis(),pos),outline,th)
	var n:=MeshInstance3D.new(); n.mesh=m; n.material_override=mat(c,outline,th); n.position=pos; parent.add_child(n); return n
func box(parent:Node,size:Vector3,c:Color,pos:Vector3,outline:=true)->MeshInstance3D:
	var b:=BoxMesh.new(); b.size=size; return mesh(parent,b,c,pos,outline,0.04)
func cap(r:float,h:float)->CapsuleMesh:
	var m:=CapsuleMesh.new(); m.radius=r; m.height=h; m.radial_segments=10; m.rings=3; return m
func sph(r:float)->SphereMesh:
	var m:=SphereMesh.new(); m.radius=r; m.height=r*2; m.radial_segments=12; m.rings=6; return m

func _ready():
	RenderingServer.global_shader_parameter_add('snow',RenderingServer.GLOBAL_VAR_TYPE_FLOAT,0.0)
	RenderingServer.global_shader_parameter_add('night',RenderingServer.GLOBAL_VAR_TYPE_FLOAT,0.0)
	env=Environment.new()
	var sky:=ProceduralSkyMaterial.new()
	sky.sky_top_color=Color(0.2,0.5,0.95); sky.sky_horizon_color=Color(0.8,0.9,1.0); sky.ground_horizon_color=Color(0.85,0.9,0.95); sky.ground_bottom_color=Color(0.6,0.65,0.7)
	var s:=Sky.new(); var psm:=PanoramaSkyMaterial.new(); psm.panorama=load('res://art/sky.jpg'); s.sky_material=psm
	env.background_mode=Environment.BG_SKY; env.sky=s
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color(0.86,0.9,1.0); env.ambient_light_energy=0.55
	env.glow_enabled=false; env.glow_intensity=0.35; env.glow_bloom=0.0; env.glow_hdr_threshold=1.4; env.tonemap_mode=Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure=0.8; env.adjustment_enabled=true; env.adjustment_saturation=1.4; env.adjustment_contrast=1.1; env.adjustment_brightness=1.03
	env.fog_enabled=true; env.fog_light_color=Color(0.86,0.92,1.0); env.fog_density=0.012
	var we:=WorldEnvironment.new(); we.environment=env; add_child(we)
	sun=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-42,-55,0); sun.light_color=Color(1,0.9,0.72); sun.light_energy=0.7; sun.shadow_enabled=false; sun.directional_shadow_max_distance=60; sun.shadow_blur=2.0; add_child(sun)
	if OS.has_feature('mobile'):
		get_viewport().scaling_3d_scale=0.6; Engine.max_fps=30
	build_street()
	build_player()
	no_outline=false
	cam=Camera3D.new(); cam.fov=55; cam.far=140.0; add_child(cam)
	build_ui()
	var vg:=TextureRect.new(); vg.texture=load('res://art/vignette.png'); vg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; vg.size=get_viewport().get_visible_rect().size; vg.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(vg); ui.move_child(vg,0)
	petal_fx()
	build_select(); build_scene_ui(); build_phone(); spawn_npcs(); spawn_peds(); spawn_cars(); build_audio()
	if 'shot' in OS.get_cmdline_user_args() and not ('select' in OS.get_cmdline_user_args()): pick('girl')

var jp:Font=load("res://fonts/jp_s.ttf")
var ar:Font=load("res://fonts/arabic.ttf")
func tag(txt:String,pos:Vector3,rot_y:float,size:float,col:Color,font:Font,outline:=Color(0.15,0.1,0.2)):
	var l:=Label3D.new(); l.text=txt; l.font=font; l.font_size=96; l.pixel_size=size; l.position=pos; l.rotation_degrees.y=rot_y
	l.modulate=col; l.outline_modulate=outline; l.outline_size=16; add_child(l)
func line(a:Vector3,b:Vector3,r:float,c:Color):
	var m:=CylinderMesh.new(); m.top_radius=r; m.bottom_radius=r; m.height=a.distance_to(b); m.radial_segments=4; m.rings=1
	var up:=(b-a).normalized(); var ax:=Vector3.UP.cross(up); var bs:=Basis()
	if ax.length()>0.001: bs=Basis(ax.normalized(),acos(clamp(Vector3.UP.dot(up),-1,1)))
	mesh_xf(self,m,c,Transform3D(bs,(a+b)/2),false)
func wire(a:Vector3,b:Vector3,sag:float):
	var prev=a
	for i in range(1,5):
		var t=i/4.0; var p=a.lerp(b,t); p.y-=sag*sin(t*PI)
		line(prev,p,0.015,Color(0.12,0.12,0.15)); prev=p

var pshader:Shader
var pmats:={}
var pmeshes:={}
func pmat(tint:Color,acc:Color,glow:=0.0)->Material:
	var key:=str([tint,acc,glow])
	if pmats.has(key): return pmats[key]
	if pshader==null: pshader=load("res://prop.gdshader")
	var m:=ShaderMaterial.new(); m.shader=pshader
	m.set_shader_parameter("glow",glow); m.set_shader_parameter("tint",Vector3(tint.r,tint.g,tint.b)); m.set_shader_parameter("accent",Vector3(acc.r,acc.g,acc.b))
	var o:=ShaderMaterial.new(); o.shader=outl; o.set_shader_parameter("thickness",0.035); m.next_pass=o
	pmats[key]=m; return m
func pglb(name:String,pos:Vector3,ry:float,tint:=Color(1,1,1),acc:=Color(1,1,1)):
	if not pmeshes.has(name):
		var inst:Node=(load("res://props/"+name+".glb") as PackedScene).instantiate()
		var f:={}; _collect(inst,f); pmeshes[name]=(f.values()[0] as MeshInstance3D).mesh; inst.free()
	var xf:=Transform3D(Basis(Vector3.UP,deg_to_rad(ry)),pos); var mt:=pmat(tint,acc,1.0 if (name.begins_with('bld') or name=='lamp') else 0.0)
	if batching:
		bt(mt,pos).append_from(pmeshes[name],0,Transform3D(Basis(),-chunk_o(pos))*xf)
	else:
		var n:=MeshInstance3D.new(); n.mesh=pmeshes[name]; n.material_override=mt; n.transform=xf; add_child(n)

func strip(ns:bool,c:float,t0:float,t1:float,gaps:Array):
	var len:=absf(t1-t0); var mid:=(t0+t1)*0.5
	var P=func(off:float,t:float,y:float)->Vector3: return Vector3(c+off,y,t) if ns else Vector3(t,y,c+off)
	var S=func(w:float,l:float,h:float)->Vector3: return Vector3(w,h,l) if ns else Vector3(l,h,w)
	box(self,S.call(9.0,len,0.2),Color(0.62,0.6,0.6),P.call(0.0,mid,-0.1),false)
	# segments between gaps
	var lo:=minf(t0,t1); var hi:=maxf(t0,t1)
	var cuts:=[[lo,hi]]
	for g in gaps:
		var gl:=minf(g.x,g.y); var gh:=maxf(g.x,g.y); var nc:=[]
		for sg in cuts:
			if gh<=sg[0] or gl>=sg[1]: nc.append(sg)
			else:
				if gl>sg[0]: nc.append([sg[0],gl])
				if gh<sg[1]: nc.append([gh,sg[1]])
		cuts=nc
	for sg in cuts:
		var l2:float=sg[1]-sg[0]; var m2:float=(sg[0]+sg[1])*0.5
		if l2<0.5: continue
		for side in [-1,1]:
			box(self,S.call(0.14,l2,0.01),Color(1,1,1),P.call(side*4.0,m2,0.02),false)
			box(self,S.call(5.4,l2,0.35),Color(0.8,0.76,0.72),P.call(side*7.5,m2,0.0),false)
			box(self,S.call(0.4,l2,0.5),Color(0.72,0.7,0.68),P.call(side*4.9,m2,0.05),false)
		var n:=int(l2/4.0)
		for k in range(n): box(self,S.call(0.12,2.2,0.01),Color(0.98,0.98,0.9),P.call(0.0,sg[0]+2.0+k*4.0,0.02),false)
func overlaps(a0:float,a1:float,gaps:Array)->bool:
	for g in gaps:
		if a1>g.x and a0<g.y: return true
	return false
func world_row(ns:bool,c:float,t:float,idx:int,sak:bool):
	var cols=[Color(0.9,0.84,0.72),Color(0.7,0.78,0.85),Color(0.86,0.7,0.62),Color(0.78,0.82,0.7),Color(0.92,0.9,0.86),Color(0.68,0.66,0.74)]
	var accs=[Color(0.95,0.3,0.3),Color(0.25,0.55,0.95),Color(0.35,0.75,0.5),Color(0.95,0.7,0.2)]
	for side in [-1,1]:
		var h:=7.0+float((idx*7+side*3+20)%5)*2.2
		var vi:int=clampi(int(round((h-7.0)/2.2)),0,4)
		var pos:=Vector3(c+side*13.5,0,t) if ns else Vector3(t,0,c+side*13.5)
		var ry:float=(0.0 if side<0 else 180.0) if ns else (-90.0 if side<0 else 90.0)
		pglb("bld_"+str(vi),pos,ry,cols[(idx+(1 if side>0 else 0))%6],accs[((idx+(1 if side>0 else 0))%6)%4])
	if sak:
		var pp:=Vector3(c-5.9,0,t) if ns else Vector3(t,0,c-5.9)
		sakura(pp,idx)
	if idx%3==0:
		var bp:=Vector3(c+6.3,0.2,t-3) if ns else Vector3(t-3,0.2,c+6.3)
		bike(bp,90.0 if ns else 0.0,Color(0.3,0.5,0.8)); 
		var vp:=Vector3(c-6.2,0.2,t+1) if ns else Vector3(t+1,0.2,c-6.2)
		vending(vp,(90.0 if ns else 0.0) if true else 0.0,Color(0.9,0.2,0.25))
	if idx%2==0:
		pole(Vector3(c+5.1,0,t) if ns else Vector3(t,0,c+5.1))

func build_park():
	# park behind the right-side opening of the main street (x 9..60, z -19..-2)
	box(self,Vector3(51,0.12,18),Color(0.45,0.72,0.4),Vector3(34.5,0.0,-10.5),false)
	box(self,Vector3(51,0.14,3),Color(0.9,0.84,0.7),Vector3(34.5,0.0,-10.5),false)
	box(self,Vector3(8,0.14,17),Color(0.9,0.84,0.7),Vector3(13.0,0.0,-10.5),false)
	box(self,Vector3(3,0.14,17),Color(0.9,0.84,0.7),Vector3(34.5,0.0,-10.5),false)
	pglb("fountain",Vector3(34.5,0.1,-10.5),0.0)
	var fw:=CPUParticles3D.new(); fw.position=Vector3(34.5,1.6,-10.5); fw.amount=40; fw.lifetime=1.3; fw.direction=Vector3(0,1,0); fw.spread=22; fw.initial_velocity_min=2.2; fw.initial_velocity_max=3.2; fw.gravity=Vector3(0,-7,0)
	var fm:=SphereMesh.new(); fm.radius=0.06; fm.height=0.12; fm.radial_segments=6; fm.rings=3; var fmt:=StandardMaterial3D.new(); fmt.albedo_color=Color(0.75,0.92,1,0.8); fmt.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; fmt.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; fm.material=fmt; fw.mesh=fm; fw.visibility_range_end=60.0; add_child(fw)
	for k in range(5):
		var x:=20.0+k*9.0
		pglb("bench",Vector3(x,0.1,-7.2),0.0,Color(1,1,1),Color(1,1,1))
		pglb("bench",Vector3(x+4.0,0.1,-13.8),180.0)
		pglb("lamp",Vector3(x+2.0,0.1,-5.0),0.0)
		pglb("lamp",Vector3(x+2.0,0.1,-16.0),0.0)
	for k in range(6):
		var fx:=18.0+k*7.5
		pglb("flowers",Vector3(fx,0.1,-3.2),0.0,Color(1,1,1),[Color(1,0.5,0.6),Color(1,0.85,0.3),Color(0.8,0.6,1)][k%3])
		pglb("flowers",Vector3(fx+3.0,0.1,-18.0),0.0,Color(1,1,1),[Color(1,0.85,0.3),Color(1,0.5,0.6),Color(0.9,0.9,1)][k%3])
	for k in range(7):
		sakura(Vector3(16.0+k*7.0+(k%2)*2.0,0.1,-2.2-(k%3)*0.6),k+3)
		sakura(Vector3(18.0+k*7.0,0.1,-18.5+(k%2)*0.4),k+1)
	for k in range(4): sakura(Vector3(27.0+k*10.0,0.1,-10.5+(1 if k%2==0 else -1)*5.0),k+9)
func build_world():
	build_park()
	var gA:=Vector2(-28.8,-48.7); var gB:=Vector2(-90,-110)
	# N-S side streets
	for x0 in [-70.0,70.0]:
		strip(true,x0,6.0,-112.0,[gA,gB])
		for i in range(10):
			if i==4 or i==5: continue
			world_row(true,x0,-float(i)*9.5+4,i+int(x0)%7,i%2==0)
	# E-W avenues
	for z0 in [-38.75,-100.0]:
		var gx:=[Vector2(-10.2,10.2),Vector2(59.8,80.2),Vector2(-80.2,-59.8)]
		strip(false,z0,-112.0,112.0,gx)
		var m:=-12
		while m<=11:
			var x:=9.5*float(m)+4.0
			if not overlaps(x-4.4,x+4.4,gx): world_row(false,z0,x,m+int(-z0)%5+20,m%2==0)
			m+=1
func pole(p:Vector3):
	pglb("pole",p,0.0)

func bike(p:Vector3,ry:float,c:Color):
	pglb("bike",p-Vector3(0,0.2,0),ry,Color(1,1,1),c)

func vending(p:Vector3,ry:float,c:Color):
	pglb("vending",p-Vector3(0,0.2,0),ry,Color(1,1,1),c)

func shop(side:int,z:float,kind:int):
	var fx=side*(13.5-3.55)
	var ry=90.0 if side<0 else -90.0
	if kind%2==0:
		tag(["コンビニ 24","ラーメン","本屋","カフェ"][kind%4],Vector3(fx-side*0.85,3.05,z),ry,0.011,Color(1,1,1),jp)
		tag(["كونبيني ٢٤ ساعة","مطعم رامن","مكتبة","كافيه"][kind%4],Vector3(fx-side*0.85,2.5,z),ry,0.008,Color(1,0.95,0.7),ar)

func building(side:int,z:float,h:float,c:Color,i:int):
	var cols=[Color(0.95,0.3,0.3),Color(0.25,0.55,0.95),Color(0.35,0.75,0.5),Color(0.95,0.7,0.2)]
	var kind:=i+(1 if side>0 else 0)
	var vi:int=clampi(int(round((h-7.0)/2.2)),0,4)
	pglb("bld_"+str(vi),Vector3(side*13.5,0,z),0.0 if side<0 else 180.0,c,cols[(kind%6)%4])

func build_street():
	batching=true
	box(self,Vector3(320,0.2,320),Color(0.55,0.62,0.5),Vector3(0,-0.25,-50),false)
	strip(true,0.0,6.0,-112.0,[Vector2(-28.8,-48.7),Vector2(-90,-110)])
	for c in range(4):
		var zc=-c*36.0-6
		for k in range(8): box(self,Vector3(8.0,0.01,0.55),Color(1,1,1),Vector3(0,0.025,zc-k*1.0),false)
	var cols=[Color(0.9,0.84,0.72),Color(0.7,0.78,0.85),Color(0.86,0.7,0.62),Color(0.78,0.82,0.7),Color(0.92,0.9,0.86),Color(0.68,0.66,0.74)]
	for i in range(10):
		for side in ([] if i==4 or i==5 else ([-1] if i==1 or i==2 else [-1,1])):
			var h=7.0+float((i*7+side*3+20)%5)*2.2
			var z=-float(i)*9.5+4
			building(side,z,h,cols[(i+(1 if side>0 else 0))%cols.size()],i)
			shop(side,z,i+(1 if side>0 else 0))
		sakura(Vector3(-5.9,0,-float(i)*9.5-1),i) if i%2==0 else null
		if i%2==0: pglb("lamp",Vector3(5.7,0.1,-float(i)*9.5-8.6),0.0)
		else: pglb("lamp",Vector3(-5.7,0.1,-float(i)*9.5-3.0),180.0)
		sakura(Vector3(5.9,0,-float(i)*9.5-6),i+3) if i%2==1 else null
		if i%3==0:
			bike(Vector3(-6.3,0.2,-float(i)*9.5-4),90,Color(0.3,0.5,0.8)); bike(Vector3(-6.3,0.2,-float(i)*9.5-5.0),90,Color(0.85,0.4,0.4))
			vending(Vector3(6.2,0.2,-float(i)*9.5+1),-90,Color(0.9,0.2,0.25))
		if i%3==1:
			vending(Vector3(-6.2,0.2,-float(i)*9.5-1),90,Color(0.2,0.5,0.9)); bike(Vector3(6.3,0.2,-float(i)*9.5-2),90,Color(0.3,0.7,0.5))
		if i%2==0:
			pole(Vector3(-5.1,0,-float(i)*9.5)); pole(Vector3(5.1,0,-float(i)*9.5))
	build_world()
	# wires: along street and across
	for side in [-1,1]:
		for i in range(0,9,2):
			var z1=-float(i)*9.5; var z2=-float(i+2)*9.5
			for dy in [8.4,7.6]:
				for dz in [-1.0,1.0]:
					wire(Vector3(side*5.1+0.0,dy,z1+dz),Vector3(side*5.1,dy,z2+dz),0.7)
	for i in range(0,10,2):
		var z=-float(i)*9.5
		for dz in [-1.0,0.0,1.0]: wire(Vector3(-5.1,8.4,z+dz),Vector3(5.1,8.4,z+dz),0.9)
	flush_batches()

func lamp(p:Vector3):
	box(self,Vector3(0.15,3.4,0.15),Color(0.3,0.25,0.35),p+Vector3(0,1.7,0))
	var m:=mesh(self,sph(0.28),Color(1,0.9,0.6),p+Vector3(0,3.5,0),false)

var tree_mat:Material
func sakura(p:Vector3,i:int):
	var nm:="sakura_"+str(i%3)
	if tree_mat==null: tree_mat=pmat(Color(1,1,1),Color(1,0.78,0.88)).duplicate()
	if not pmeshes.has(nm): pglb_load(nm)
	var n:=MeshInstance3D.new(); n.mesh=pmeshes[nm]; n.material_override=tree_mat
	n.transform=Transform3D(Basis(Vector3.UP,deg_to_rad(float(i*47))),p); n.visibility_range_end=90.0; add_child(n)
func pglb_load(name:String):
	var inst:Node=(load("res://props/"+name+".glb") as PackedScene).instantiate()
	var f:={}; _collect(inst,f); pmeshes[name]=(f.values()[0] as MeshInstance3D).mesh; inst.free()

func limb(parent:Node,pos:Vector3,len:float,r:float,c:Color)->Node3D:
	var pivot:=Node3D.new(); pivot.position=pos; parent.add_child(pivot)
	mesh(pivot,cap(r,len),c,Vector3(0,-len/2,0),true,0.02)
	return pivot


var cshader:Shader
var cmats:={}
func cmat(skin:Color,hair:Color,top:Color,bot:Color,acc:Color,iris:Color)->Material:
	var key:=str([skin,hair,top,bot,acc,iris])
	if cmats.has(key): return cmats[key]
	if cshader==null: cshader=load("res://char.gdshader")
	var m:=ShaderMaterial.new(); m.shader=cshader
	m.set_shader_parameter("p_skin",Vector3(skin.r,skin.g,skin.b)); m.set_shader_parameter("p_hair",Vector3(hair.r,hair.g,hair.b))
	m.set_shader_parameter("p_top",Vector3(top.r,top.g,top.b)); m.set_shader_parameter("p_bot",Vector3(bot.r,bot.g,bot.b))
	m.set_shader_parameter("p_acc",Vector3(acc.r,acc.g,acc.b)); m.set_shader_parameter("p_iris",Vector3(iris.r,iris.g,iris.b))
	var o:=ShaderMaterial.new(); o.shader=outl; o.set_shader_parameter("thickness",0.02); m.next_pass=o
	cmats[key]=m; return m
func load_char(kind:String,mt:Material)->Dictionary:
	var ps:PackedScene=load("res://chars/"+kind+".glb")
	var inst:Node3D=ps.instantiate()
	var root:=Node3D.new(); var d:={}
	var found:={}
	_collect(inst,found)
	for k in found.keys():
		var mi:MeshInstance3D=found[k]
		mi.get_parent().remove_child(mi)
		mi.material_override=mt
		root.add_child(mi)
		mi.transform=Transform3D(Basis(),mi.position) if false else mi.transform
		d[k]=mi
	inst.free()
	d.root=root
	return d
func _collect(n:Node,out:Dictionary):
	if n is MeshInstance3D: out[String(n.name)]=n
	for c in n.get_children(): _collect(c,out)
func make_girl(skin:Color,hair:Color,top:Color,skirtc:Color,ribbon:Color,long_hair:=true,glasses:=false)->Dictionary:
	var iris:=Color(0.35,0.2,0.65) if hair.v<0.5 else Color(0.2,0.45,0.7)
	return load_char(("girl_long" if long_hair else "girl_bob")+("_g" if glasses else ""),cmat(skin,hair,top,skirtc,ribbon,iris))
func make_boy(skin:Color,hair:Color,spiky:bool,tie:=Color(0.7,0.1,0.15))->Dictionary:
	var iris:=Color(0.25,0.35,0.2) if spiky else Color(0.2,0.25,0.55)
	return load_char("boy_spiky" if spiky else "boy_soft",cmat(skin,hair,Color(0.14,0.22,0.45),Color(0.5,0.52,0.56),tie,iris))

func make_girl_old(skin:Color,hair:Color,top:Color,skirtc:Color,ribbon:Color,long_hair:=true)->Dictionary:
	var root:=Node3D.new()
	var sock=Color(0.97,0.97,1)
	var d:={}
	d.legl=limb(root,Vector3(-0.12,0.9,0),0.9,0.075,skin); d.legr=limb(root,Vector3(0.12,0.9,0),0.9,0.075,skin)
	for sx in [-1,1]:
		mesh(root,cap(0.085,0.45),sock,Vector3(sx*0.12,0.33,0),true,0.015)
		var sh:=mesh(root,sph(0.11),Color(0.25,0.15,0.2),Vector3(sx*0.12,0.07,0.05),true,0.015); sh.scale=Vector3(1,0.6,1.5)
	mesh(root,cap(0.23,0.75),Color(1,1,1),Vector3(0,1.32,0))
	var col:=mesh(root,cap(0.25,0.4),top,Vector3(0,1.5,0),true,0.02); col.scale=Vector3(1.05,0.4,1.05)
	var bow:=mesh(root,sph(0.07),ribbon,Vector3(0,1.5,0.22),false); bow.scale=Vector3(1.8,1,0.7)
	var skirt:=CylinderMesh.new(); skirt.top_radius=0.2; skirt.bottom_radius=0.42; skirt.height=0.38
	mesh(root,skirt,skirtc,Vector3(0,0.98,0),true,0.025)
	d.arml=limb(root,Vector3(-0.31,1.56,0),0.65,0.06,Color(1,1,1)); d.armr=limb(root,Vector3(0.31,1.56,0),0.65,0.06,Color(1,1,1))
	for p in [d.arml,d.armr]: mesh(p,sph(0.065),skin,Vector3(0,-0.68,0),false)
	var neck:=mesh(root,cap(0.07,0.2),skin,Vector3(0,1.72,0),false)
	var head:=Node3D.new(); head.position=Vector3(0,2.0,0); root.add_child(head)
	var hs:=mesh(head,sph(0.36),skin,Vector3.ZERO); hs.scale=Vector3(1.0,0.92,0.95)
	var back:=mesh(head,sph(0.4),hair,Vector3(0,0.04,-0.06)); back.scale=Vector3(1.0,0.98,0.95)
	var fr:=mesh(head,sph(0.38),hair,Vector3(0,0.15,0.04)); fr.scale=Vector3(1.0,0.5,0.9)
	for k in range(5):
		var bang:=mesh(head,sph(0.1),hair,Vector3((k-2)*0.14,0.2-abs(k-2)*0.03,0.3),true,0.012); bang.scale=Vector3(1,1.5,0.6)
	for sx in [-1,1]:
		var eye:=mesh(head,sph(0.1),Color(1,1,1),Vector3(sx*0.15,-0.02,0.3),false); eye.scale=Vector3(1,1.25,0.4)
		var iris:=mesh(head,sph(0.075),Color(0.35,0.2,0.65) if hair.v<0.5 else Color(0.2,0.45,0.7),Vector3(sx*0.15,-0.03,0.33),false); iris.scale=Vector3(1,1.3,0.4)
		mesh(head,sph(0.035),Color(0.08,0.04,0.15),Vector3(sx*0.15,-0.03,0.345),false)
		mesh(head,sph(0.03),Color(1,1,1),Vector3(sx*0.15+0.03,0.02,0.36),false)
		var br:=mesh(head,sph(0.05),hair,Vector3(sx*0.15,0.12,0.33),false); br.scale=Vector3(1.6,0.25,0.3)
		var bl:=mesh(head,sph(0.05),Color(1,0.6,0.65),Vector3(sx*0.22,-0.12,0.3),false); bl.scale=Vector3(1.4,0.6,0.3)
		var tail:=mesh(head,cap(0.11,0.9),hair,Vector3(sx*0.34,-0.35,-0.12),true,0.02) if long_hair else null
		var bw:=mesh(head,sph(0.06),ribbon,Vector3(sx*0.3,0.28,0.05),false); bw.scale=Vector3(1.6,1,0.8)
	mesh(head,sph(0.02),Color(0.9,0.45,0.5),Vector3(0,-0.17,0.34),false)
	if long_hair: mesh(root,cap(0.2,1.1),hair,Vector3(0,1.45,-0.28),true,0.02)
	d.root=root
	return d

func make_boy_old(skin:Color,hair:Color,spiky:bool,tie:=Color(0.7,0.1,0.15))->Dictionary:
	var root:=Node3D.new(); var d:={}
	var navy=Color(0.17,0.3,0.6); var grey=Color(0.5,0.52,0.56)
	d.legl=limb(root,Vector3(-0.14,0.95,0),0.95,0.09,grey); d.legr=limb(root,Vector3(0.14,0.95,0),0.95,0.09,grey)
	for sx in [-1,1]:
		var sh:=mesh(root,sph(0.12),Color(0.3,0.2,0.18),Vector3(sx*0.14,0.07,0.06),true,0.015); sh.scale=Vector3(1,0.6,1.6)
	var tor:=mesh(root,cap(0.3,0.95),navy,Vector3(0,1.4,0)); tor.scale=Vector3(1.1,1,0.8)
	mesh(root,box_mesh(0.14,0.5,0.04),Color(1,1,1),Vector3(0,1.5,0.25),false)
	mesh(root,box_mesh(0.07,0.45,0.04),tie,Vector3(0,1.45,0.27),false)
	d.arml=limb(root,Vector3(-0.38,1.68,0),0.75,0.075,navy); d.armr=limb(root,Vector3(0.38,1.68,0),0.75,0.075,navy)
	for p in [d.arml,d.armr]: mesh(p,sph(0.07),skin,Vector3(0,-0.78,0),false)
	mesh(root,cap(0.08,0.2),skin,Vector3(0,1.9,0),false)
	var head:=Node3D.new(); head.position=Vector3(0,2.15,0); root.add_child(head)
	var hs:=mesh(head,sph(0.34),skin,Vector3.ZERO); hs.scale=Vector3(0.95,1.0,0.95)
	var top:=mesh(head,sph(0.37),hair,Vector3(0,0.1,-0.03)); top.scale=Vector3(1.0,0.75,1.0)
	for k in range(7 if spiky else 5):
		var a2=-1.2+k*(2.4/(6 if spiky else 4))
		var sp:=mesh(head,cap(0.07,0.35 if spiky else 0.2),hair,Vector3(sin(a2)*0.22,0.38,0.05+cos(a2)*0.08),true,0.012)
		sp.rotation_degrees.z=-a2*40; sp.rotation_degrees.x=-15
	for sx in [-1,1]:
		var eye:=mesh(head,sph(0.08),Color(1,1,1),Vector3(sx*0.14,-0.02,0.28),false); eye.scale=Vector3(1,1.2,0.4)
		var iris:=mesh(head,sph(0.06),Color(0.25,0.35,0.2) if spiky else Color(0.2,0.25,0.55),Vector3(sx*0.14,-0.03,0.31),false); iris.scale=Vector3(1,1.3,0.4)
		mesh(head,sph(0.025),Color(1,1,1),Vector3(sx*0.14+0.025,0.01,0.34),false)
		var br:=mesh(head,sph(0.05),hair,Vector3(sx*0.14,0.1,0.31),false); br.scale=Vector3(1.6,0.25,0.3)
	d.root=root
	return d
func box_mesh(x:float,y:float,z:float)->BoxMesh:
	var b:=BoxMesh.new(); b.size=Vector3(x,y,z); return b
func add_glasses(g:Dictionary):
	pass

func build_player():
	player=Node3D.new(); add_child(player)
	var g:=make_girl(Color(1,0.88,0.8),Color(0.3,0.2,0.55),Color(0.17,0.3,0.6),Color(0.17,0.3,0.6),Color(1,0.35,0.5))
	player.add_child(g.root); legl=g.legl; legr=g.legr; arml=g.arml; armr=g.armr
	player.position=Vector3(0,0,2)
	var cols=[[Color(1,0.85,0.75),Color(0.95,0.5,0.6),Color(1,0.7,0.8),Color(0.9,0.5,0.6),Color(1,1,0.4)],[Color(1,0.87,0.78),Color(0.2,0.55,0.55),Color(0.9,0.95,1),Color(0.7,0.4,0.6),Color(0.4,0.9,1)],[Color(0.95,0.8,0.7),Color(0.85,0.7,0.3),Color(1,0.9,0.6),Color(0.5,0.5,0.8),Color(1,0.5,0.3)]]
	no_outline=true
	yo_ref=make_boy(Color(0.82,0.58,0.4),Color(0.42,0.24,0.12),true)
	var yo=yo_ref; yo.root.position=Vector3(2.2,0,-2.0); yo.root.rotation_degrees.y=200; add_child(yo.root)
	var ra:=make_girl(Color(1,0.88,0.8),Color(0.45,0.2,0.65),Color(0.17,0.3,0.6),Color(0.5,0.52,0.56),Color(0.85,0.1,0.15),true,true)
	ra.root.position=Vector3(-2.2,0,-3.0); ra.root.rotation_degrees.y=160; add_child(ra.root)
	for i in range(2):
		var c=cols[i%3]; var n:=make_girl(c[0],c[1],c[2],c[3],c[4],i%2==0)
		var side=-1 if i%2==0 else 1
		n.root.position=Vector3(side*6.0,0.0,-8.0-i*13.0); n.root.rotation.y=side*-1.57 if false else (1.57 if side<0 else -1.57)
		add_child(n.root)

var yo_ref:Dictionary
var npcs:=[]
func add_npc(node:Node3D,pos:Vector3,key:String,bg:String,lines:Array):
	node.position=pos; add_child(node); npcs.append({"n":node,"key":key,"bg":bg,"lines":lines})
func spawn_npcs():
	no_outline=false
	var ay:=make_girl(Color(1,0.88,0.8),Color(0.45,0.2,0.65),Color(0.17,0.3,0.6),Color(0.5,0.52,0.56),Color(0.85,0.1,0.15),true,true)
	add_npc(ay.root,Vector3(-1.5,0,-26),"gate","",[["أياني","صباح الخير. انت الطالب الجديد؟ أنا أياني، رئيسة الفصل.","rana_calm"],["أياني","الفصل كله بيتقيّم بالنقاط. خلي بالك، أنا مش هسيبك تسبقني بسهولة.","rana_close"],["أياني","بس لو احتجت حاجة قولي. يلا بينا نشوف المدرسة.","rana_smile",[["أرد بثقة","العلاقات",5],["أسكت وأمشي","الدراسة",3]]]])
	var ka:=make_boy(Color(0.9,0.68,0.52),Color(0.42,0.24,0.12),true)
	add_npc(ka.root,Vector3(1.5,0,-58),"front","",[["كايتو","يا باشا! أنا كايتو، قاعد جنبك في الفصل.","youssef_laugh"],["كايتو","متقلقش، هعرّفك على كل حاجة. أول حاجة: الكافيه بعد المدرسة عليّ!","youssef_smile"],["كايتو","بس أياني دي شكلها هتبقى منافستك الأولى، خلي بالك 😄","youssef_joy"]])
	var ka2:=make_boy(Color(0.9,0.68,0.52),Color(0.42,0.24,0.12),true)
	add_npc(ka2.root,Vector3(-1.5,0,-73),"cafe","",[["كايتو","ده كافيه الهدوء. أحلى قهوة في ساكورا هيل. تحب نقعد؟","youssef_joy",[["نقعد ونتكلم","العلاقات",10],["نذاكر سوا","الدراسة",10]]]])
	var ay2:=make_girl(Color(1,0.88,0.8),Color(0.45,0.2,0.65),Color(0.17,0.3,0.6),Color(0.5,0.52,0.56),Color(0.85,0.1,0.15),true,true)
	add_npc(ay2.root,Vector3(1.5,0,-88),"class","",[["أياني","ده فصلنا. أول امتحان بعد أسبوع، استعد.","rana_think",[["أذاكر معاها","الدراسة",10],["أنا هتصرف","الصحة",3]]]])
	var cat:Node3D=load_char("cat",cmat(Color(1,0.95,0.9),Color(0.95,0.6,0.35),Color(1,1,1),Color(1,1,1),Color(1,1,1),Color(0.3,0.6,0.35))).root
	add_npc(cat,Vector3(1.8,0,-12),"momo","",[["مومو","مياو! 🐱 (القطة مومو بتحك نفسها في رجلك)","youssef_joy",[["أحضنها","الصحة",5],["أديها أكل","العلاقات",4]]]])
	var n1:=make_boy(Color(0.95,0.78,0.62),Color(0.25,0.2,0.18),false,Color(0.2,0.5,0.3))
	add_npc(n1.root,Vector3(-68.5,0,-22),"w1","",[["سعيد","أهلاً يا بني! أنا بعمل أحلى طيّارات ورق في الحي.","pt_w1",[["أسأله عن الحي","المجتمع",6],["أساعده","الفلوس",4]]]])
	var n2:=make_girl(Color(1,0.86,0.78),Color(0.2,0.15,0.12),Color(0.9,0.6,0.2),Color(0.3,0.5,0.4),Color(1,0.9,0.3),false)
	add_npc(n2.root,Vector3(68.5,0,-60),"w2","",[["ميرا","بجري كل صباح هنا. الهواء في الجادة الشرقية ينعش!","pt_w2",[["أجري معاها","الصحة",8],["أتكلم معاها","المجتمع",4]]]])
	var n3:=make_boy(Color(0.85,0.62,0.45),Color(0.15,0.1,0.1),true,Color(0.9,0.5,0.1))
	add_npc(n3.root,Vector3(-30,0,-36.5),"w3","",[["دودي","شفت القطة مومو؟ بتهرب مني كل يوم 😅","pt_w3",[["هساعدك تدور عليها","العلاقات",3],["أضحك وأمشي","المجتمع",3]]]])
	var n4:=make_girl(Color(0.98,0.84,0.74),Color(0.55,0.3,0.15),Color(0.5,0.7,0.9),Color(0.9,0.9,0.95),Color(1,0.5,0.6),true)
	add_npc(n4.root,Vector3(30,0,-98.5),"w4","",[["هدى","بشتغل في مكتبة صغيرة هناك. لو بتحب القراية تعالى.","pt_w4",[["أسألها عن كتب","الدراسة",8],["أشكرها","المجتمع",3]]]])
	no_outline=false
func _nox():
	no_outline=false
func build_ui():
	var cl:=CanvasLayer.new(); add_child(cl); ui=cl
	var f:Font=load("res://fonts/arabic.ttf")
	var lb:=Label.new(); lb.text="شارع الحياة"; lb.add_theme_font_override("font",f); lb.add_theme_font_size_override("font_size",34)
	lb.add_theme_color_override("font_outline_color",Color(0.3,0.1,0.4)); lb.add_theme_constant_override("outline_size",10)
	lb.position=Vector2(24,20); lb.text_direction=Control.TEXT_DIRECTION_RTL; cl.add_child(lb)
	hud_time=Label.new(); hud_time.add_theme_font_override("font",f); hud_time.add_theme_font_size_override("font_size",20); hud_time.add_theme_color_override("font_color",Color(1,1,1))
	var ys0:=get_viewport().get_visible_rect().size
	var panel:=Panel.new(); panel.position=Vector2(ys0.x-330,16); panel.size=Vector2(300,64)
	var sb:=StyleBoxFlat.new(); sb.bg_color=Color(0.15,0.12,0.25,0.88); sb.set_corner_radius_all(18); panel.add_theme_stylebox_override("panel",sb); cl.add_child(panel)
	hud_time.position=Vector2(ys0.x-255,26); hud_time.text_direction=Control.TEXT_DIRECTION_RTL; cl.add_child(hud_time)
	var pf:=Panel.new(); pf.position=Vector2(ys0.x-92,10); pf.size=Vector2(76,76)
	var sb2:=StyleBoxFlat.new(); sb2.bg_color=Color(1,0.8,0.85); sb2.set_corner_radius_all(14); sb2.set_border_width_all(4); sb2.border_color=Color(0.15,0.12,0.25); pf.add_theme_stylebox_override("panel",sb2); cl.add_child(pf)
	var img:=load("res://assets_portrait.png") as Texture2D
	if img:
		var tr:=TextureRect.new(); hud_face=tr; tr.texture=img; tr.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; tr.custom_minimum_size=Vector2(68,68); tr.position=pf.position+Vector2(4,4); tr.size=Vector2(68,68); tr.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; cl.add_child(tr)
	var clock:=Control.new(); clock.position=Vector2(ys0.x-304,26); cl.add_child(clock)
	clock.draw.connect(func():
		clock.draw_circle(Vector2(8,22),26,Color(0.7,0.7,1)); clock.draw_circle(Vector2(8,22),21,Color(1,1,1))
		var a=hud_min/720.0*TAU-PI/2; var a2=hud_min/60.0*TAU-PI/2
		clock.draw_line(Vector2(8,22),Vector2(8,22)+Vector2(cos(a),sin(a))*11,Color(0.1,0.1,0.2),3)
		clock.draw_line(Vector2(8,22),Vector2(8,22)+Vector2(cos(a2),sin(a2))*17,Color(0.1,0.1,0.2),2))
	hud_clock=clock
	var hint:=Label.new(); hint.text="اسحب الدائرة للمشي"; hint.add_theme_font_override("font",f); hint.add_theme_font_size_override("font_size",22)
	hint.position=Vector2(40,560); hint.name="hint"; cl.add_child(hint)
	base=Control.new(); base.position=Vector2(170,560); cl.add_child(base)
	base.draw.connect(func(): base.draw_circle(Vector2.ZERO,80,Color(1,1,1,0.25)))
	knob=Control.new(); knob.position=Vector2(170,560); cl.add_child(knob)
	knob.draw.connect(func(): knob.draw_circle(Vector2.ZERO,38,Color(1,0.7,0.85,0.8)))
	base.queue_redraw(); knob.queue_redraw()
	var ys:=get_viewport().get_visible_rect().size
	base.position=Vector2(170,ys.y-170); knob.position=base.position; hint.position=Vector2(40,ys.y-60)

func petal_fx():
	petals=CPUParticles3D.new(); petals.amount=30; petals.lifetime=6.0; petals.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX
	petals.emission_box_extents=Vector3(8,0.5,10); petals.gravity=Vector3(0.4,-0.9,0); petals.initial_velocity_min=0.1; petals.initial_velocity_max=0.4
	var q:=QuadMesh.new(); q.size=Vector2(0.12,0.08)
	var m:=StandardMaterial3D.new(); m.albedo_color=Color(1,0.78,0.88); m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; m.cull_mode=BaseMaterial3D.CULL_DISABLED
	q.material=m; petals.mesh=q; petals.angular_velocity_min=-180; petals.angular_velocity_max=180
	add_child(petals)

func img_tex(path:String)->Texture2D:
	return load(path) as Texture2D
func lbl(txt:String,size:int,pos:Vector2,col:=Color(1,1,1))->Label:
	var l:=Label.new(); l.text=txt; l.add_theme_font_override("font",ar); l.add_theme_font_size_override("font_size",size); l.add_theme_color_override("font_color",col)
	l.add_theme_color_override("font_outline_color",Color(0.15,0.1,0.25)); l.add_theme_constant_override("outline_size",8); l.position=pos; l.text_direction=Control.TEXT_DIRECTION_RTL; return l
func build_select():
	var vs:=get_viewport().get_visible_rect().size
	select_layer=Control.new(); select_layer.size=vs; ui.add_child(select_layer)
	var bg:=ColorRect.new(); bg.color=Color(0.1,0.08,0.2,0.88); bg.size=vs; select_layer.add_child(bg)
	var t:=lbl("اختار شخصيتك",54,Vector2(vs.x/2-170,40)); select_layer.add_child(t)
	for k in range(2):
		var who='girl' if k==0 else 'boy'
		var p:=Panel.new(); p.size=Vector2(300,380); p.position=Vector2(vs.x/2-330+k*360,150)
		var sb:=StyleBoxFlat.new(); sb.bg_color=Color(1,0.85,0.9) if k==0 else Color(0.8,0.88,1); sb.set_corner_radius_all(24); sb.set_border_width_all(6); sb.border_color=Color(1,1,1); p.add_theme_stylebox_override("panel",sb); select_layer.add_child(p)
		var tr:=TextureRect.new(); tr.texture=img_tex("res://art/%s.png"%who); tr.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; tr.size=Vector2(260,260); tr.position=p.position+Vector2(20,20); select_layer.add_child(tr)
		select_layer.add_child(lbl("ساكورا" if k==0 else "هاروتو",44,p.position+Vector2(110,290)))
		p.set_meta("who",who); p.name="p_"+who
func pick(who:String):
	if mode!='select': return
	mode='play'; select_layer.visible=false; who_pick=who
	if not ('shot' in OS.get_cmdline_user_args()): load_game()
	hud_face.texture=img_tex("res://art/%s.png"%who)
	if who=='boy':
		player.get_child(0).queue_free()
		var g:=make_boy(Color(1,0.88,0.8),Color(0.1,0.15,0.4),false)
		player.add_child(g.root); legl=g.legl; legr=g.legr; arml=g.arml; armr=g.armr
	start_scene('room','',[[ 'أنا','يوم جديد في ساكورا هيل... أول يوم في المدرسة الجديدة.',who,[]],['أنا','أفطر الأول ولا أنزل بدري؟',who,[['أفطر وأروق','الصحة',8],['أنزل بدري','الدراسة',8]]]])
func build_scene_ui():
	var vs:=get_viewport().get_visible_rect().size
	scene_layer=Control.new(); scene_layer.size=vs; scene_layer.visible=false; ui.add_child(scene_layer)
	sc_bg=TextureRect.new(); sc_bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; sc_bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; sc_bg.size=vs; scene_layer.add_child(sc_bg)
	var box:=Panel.new(); box.size=Vector2(vs.x-80,170); box.position=Vector2(40,vs.y-200)
	var sb:=StyleBoxFlat.new(); sb.bg_color=Color(0.12,0.1,0.25,0.9); sb.set_corner_radius_all(22); sb.set_border_width_all(3); sb.border_color=Color(1,0.75,0.85); box.add_theme_stylebox_override("panel",sb); scene_layer.add_child(box)
	sc_face=TextureRect.new(); sc_face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; sc_face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; sc_face.size=Vector2(190,190); sc_face.position=Vector2(vs.x-260,vs.y-250); scene_layer.add_child(sc_face)
	sc_name=lbl("",34,Vector2(vs.x-480,vs.y-190),Color(1,0.8,0.9)); scene_layer.add_child(sc_name)
	sc_txt=lbl("",30,Vector2(80,vs.y-150)); sc_txt.size=Vector2(vs.x-380,100); sc_txt.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; sc_txt.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; scene_layer.add_child(sc_txt)
	scene_layer.add_child(lbl("اضغط للمتابعة",22,Vector2(60,vs.y-45),Color(1,1,0.8)))
	for k in range(2):
		var b:=Button.new(); b.size=Vector2(560,64); b.position=Vector2(vs.x/2-280,vs.y-420+k*80); b.add_theme_font_override("font",ar); b.add_theme_font_size_override("font_size",30); b.visible=false
		var sbn:=StyleBoxFlat.new(); sbn.bg_color=Color(1,0.93,0.6) if k==0 else Color(1,1,1); sbn.set_corner_radius_all(14); sbn.set_border_width_all(3); sbn.border_color=Color(0.2,0.15,0.3)
		b.add_theme_stylebox_override("normal",sbn); b.add_theme_stylebox_override("hover",sbn); b.add_theme_stylebox_override("pressed",sbn); b.add_theme_color_override("font_color",Color(0.1,0.08,0.2)); b.add_theme_color_override("font_hover_color",Color(0.1,0.08,0.2)); b.add_theme_color_override("font_pressed_color",Color(0.1,0.08,0.2))
		b.pressed.connect(func(): choose(k)); scene_layer.add_child(b); choice_btns.append(b)
	stats_layer=Control.new(); stats_layer.size=vs; stats_layer.visible=false; ui.add_child(stats_layer)
	var sbg:=ColorRect.new(); sbg.color=Color(0.1,0.08,0.2,0.92); sbg.size=vs; stats_layer.add_child(sbg)
	stats_layer.add_child(lbl("إحصائياتك",46,Vector2(vs.x/2-100,24)))
	var pc:=Control.new(); pc.position=Vector2(vs.x/2,vs.y/2+30); stats_layer.add_child(pc)
	pc.draw.connect(func():
		var keys=stats.keys(); var n=keys.size(); var R=190.0
		for lv in [0.25,0.5,0.75,1.0]:
			var pts:=PackedVector2Array()
			for i in range(n): pts.append(Vector2(sin(i*TAU/n),-cos(i*TAU/n))*R*lv)
			pts.append(pts[0]); pc.draw_polyline(pts,Color(1,1,1,0.35),2)
		var poly:=PackedVector2Array()
		for i in range(n): poly.append(Vector2(sin(i*TAU/n),-cos(i*TAU/n))*R*float(stats[keys[i]])/100.0)
		pc.draw_colored_polygon(poly,Color(0.4,0.9,0.55,0.55))
		for i in range(n):
			var p:Vector2=Vector2(sin(i*TAU/n),-cos(i*TAU/n))*(R+34)
			pass
		for i in range(n):
			var lb2:Label=stat_lbls[i]; lb2.text="%s %d"%[keys[i],stats[keys[i]]]
			lb2.position=pc.position+Vector2(sin(i*TAU/n),-cos(i*TAU/n))*(R+50)-Vector2(60,18))
	for i in range(5):
		var l2:=lbl("",28,Vector2.ZERO); l2.size=Vector2(120,40); l2.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; stats_layer.add_child(l2); stat_lbls.append(l2)
	stats_layer.set_meta("pc",pc)
	stats_layer.add_child(lbl("اضغط للرجوع",24,Vector2(60,vs.y-50),Color(1,1,0.8)))
func start_scene(key:String,bg:String,lines:Array):
	if scene_done.has(key): return
	cur_key=key; scene_done[key]=true; mode='scene'; phone_btn.visible=false; badge.visible=false; joy_vec=Vector2.ZERO; joy_id=-1; knob.position=base.position
	sc_bg.texture=(img_tex("res://art/%s.jpg"%bg) if bg!="" else null); scene_lines=lines; scene_i=0; scene_layer.visible=true; show_line()
func show_line():
	sfx('blip',randf_range(0.9,1.15))
	var l=scene_lines[scene_i]; sc_name.text=l[0]; sc_txt.text=l[1]; sc_face.texture=img_tex("res://art/%s.png"%l[2])
	var ch:Array=l[3] if l.size()>3 else []
	choices_on=ch.size()>0
	for k in range(2):
		choice_btns[k].visible=k<ch.size()
		if k<ch.size(): choice_btns[k].text=ch[k][0]
func choose(k:int):
	var ch:Array=scene_lines[scene_i][3]
	stats[ch[k][1]]=clampi(stats[ch[k][1]]+ch[k][2],0,100)
	if ch[k][1]=='العلاقات': add_aff(npc_of.get(cur_key,scene_lines[scene_i][0]),1)
	if ch[k].size()>3: energy=clampi(energy+ch[k][3],0,5); hearts.queue_redraw()
	choices_on=false
	for b in choice_btns: b.visible=false
	advance()
func advance():
	scene_i+=1
	if scene_i>=scene_lines.size():
		scene_layer.visible=false; mode='play'; phone_btn.visible=true; refresh_badge()
		var who:String=npc_of.get(cur_key,"")
		var day:=int(hud_min/1440.0)
		if who!="": qadd('talk',who)
		if who!="" and aff_day.get(who,-1)!=day: aff_day[who]=day; add_aff(who,1)
		if rel_queue.size()>0:
			var sc:Array=rel_queue.pop_front(); scene_done.erase("rel_"+str(Time.get_ticks_msec())); start_scene("rel_"+str(Time.get_ticks_msec()),"",sc)
	else: show_line()
func check_triggers():
	if in_room!='':
		for n in room_pts:
			var d:Vector3=player.position-n.n.position
			if Vector2(d.x,d.z).length()<n.r and not scene_done.has(n.key):
				if n.key=='r_bed':
					hud_min=(floor(hud_min/1440.0)+1)*1440.0+480.0
				n.n.rotation.y=atan2(d.x,d.z) if n.key!='r_bed' else n.n.rotation.y
				start_scene(n.key,n.bg,n.lines)
		if player.position.z>bnd.end.y-0.25 and abs(player.position.x)<1.3: exit_room()
		return
	for n in npcs:
		var d:Vector3=player.position-n.n.position
		if Vector2(d.x,d.z).length()<3.2 and not scene_done.has(n.key) and (n.key!='momo' or n.n.visible):
			n.n.rotation.y=atan2(d.x,d.z)
			start_scene(n.key,n.bg,n.lines)
	if false: start_scene('konbini',"",[["البائع","أهلاً! عروض النهاردة على الأونيجيري.","youssef_smile",[["أشتري (ادفع ٥ فلوس)","الفلوس",-5],["مش دلوقتي","الصحة",2]]]])
func _input(e):
	if mode=='select':
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			var p:Vector2=e.position
			for who in ['girl','boy']:
				var n:Control=select_layer.get_node("p_"+who)
				if Rect2(n.position,n.size).has_point(p): pick(who)
		return
	if mode=='phone' or mode=='map': return
	if mode=='stats':
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			stats_layer.visible=false; mode='play'
		return
	if mode=='play' and ((e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed)):
		var hp:Vector2=e.position; var vs0:=get_viewport().get_visible_rect().size
		if Rect2(vs0.x-150,vs0.y-150,130,130).has_point(hp): open_phone(); return
		if Rect2(vs0.x-340,10,330,80).has_point(hp):
			mode='stats'; stats_layer.visible=true; stats_layer.get_meta('pc').queue_redraw(); return
	if mode=='scene':
		if choices_on: return
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed) or (e is InputEventKey and e.pressed and not e.echo): advance()
		return
	var ys=get_viewport().get_visible_rect().size
	if e is InputEventScreenTouch or e is InputEventMouseButton:
		var pressed=e.pressed
		var p:Vector2=e.position
		if pressed and joy_id==-1 and p.x<ys.x*0.5:
			joy_id=e.index if e is InputEventScreenTouch else 0; joy_center=p; base.position=p; knob.position=p
		elif not pressed:
			joy_id=-1; joy_vec=Vector2.ZERO; knob.position=base.position
	elif (e is InputEventScreenDrag or e is InputEventMouseMotion) and joy_id!=-1:
		var d:Vector2=e.position-joy_center
		joy_vec=(d/80.0).limit_length(1.0); knob.position=joy_center+joy_vec*80

func tod()->String:
	var h=int(hud_min/60.0)%24
	if h<12: return "صباحاً"
	if h<17: return "ظهراً"
	return "مساءً"

var peds:=[]
var ped_streets:=[[true,0.0,-110.0,4.0],[true,-70.0,-108.0,4.0],[true,70.0,-108.0,4.0],[false,-38.75,-108.0,108.0],[false,-100.0,-108.0,108.0]]
var cars:=[]
func spawn_cars():
	pglb_load("car")
	var cc=[Color(0.95,0.35,0.4),Color(0.3,0.6,0.95),Color(0.98,0.8,0.3),Color(0.45,0.8,0.55),Color(0.9,0.9,0.95)]
	var defs=[[0,-60.0,1.0],[0,-20.0,-1.0],[3,-30.0,1.0],[4,40.0,-1.0],[3,60.0,-1.0]]
	for i in range(defs.size()):
		var n:=MeshInstance3D.new(); n.mesh=pmeshes["car"]; n.material_override=pmat(Color(1,1,1),cc[i%5]); add_child(n)
		cars.append({"n":n,"si":defs[i][0],"t":defs[i][1],"dir":defs[i][2]})
func update_cars(dt:float):
	for c in cars:
		var st:Array=ped_streets[c.si]; var lo:float=minf(st[2],st[3]); var hi:float=maxf(st[2],st[3])
		var sp:=7.0
		var pp:float=player.position.z if st[0] else player.position.x
		var lat:float=absf((player.position.x-st[1]) if st[0] else (player.position.z-st[1]))
		var ahead:float=(pp-c.t)*c.dir
		if in_room=='' and lat<4.0 and ahead>0.0 and ahead<9.0:
			sp=0.0
			c['hk']=c.get('hk',0.0)+dt
			if c['hk']>1.6 and c['hk']-dt<=1.6 and player.position.distance_to(c.n.position)<14.0: sfx('horn',0.95+randf()*0.2)
		else: c['hk']=0.0
		c.t+=c.dir*sp*dt
		if c.t>hi: c.t=lo
		if c.t<lo: c.t=hi
		var off:float=2.3*c.dir*(1.0 if st[0] else -1.0)
		var n:Node3D=c.n
		n.position=Vector3(st[1]+off,0.0,c.t) if st[0] else Vector3(c.t,0.0,st[1]+off)
		n.rotation.y=atan2(0.0,c.dir) if st[0] else atan2(c.dir,0.0)
		n.visible=in_room=='' and player.position.distance_to(n.position)<60.0
func spawn_peds():
	var rng:=RandomNumberGenerator.new(); rng.seed=7
	var skins=[Color(1,0.88,0.8),Color(0.9,0.7,0.55),Color(0.8,0.58,0.42)]
	var hairs=[Color(0.15,0.1,0.1),Color(0.4,0.22,0.12),Color(0.75,0.55,0.25),Color(0.55,0.25,0.55),Color(0.2,0.3,0.6)]
	var outf=[Color(0.9,0.4,0.5),Color(0.3,0.6,0.8),Color(0.95,0.8,0.3),Color(0.45,0.75,0.5),Color(0.8,0.5,0.8)]
	for i in range(6):
		var g:Dictionary
		if i%2==0: g=make_girl(skins[i%3],hairs[(i*2)%5],outf[i%5],outf[(i+2)%5],outf[(i+3)%5],i%4==0)
		else: g=make_boy(skins[(i+1)%3],hairs[(i*3)%5],i%3==0,outf[(i+1)%5])
		add_child(g.root)
		peds.append({"d":g,"si":i%5,"t":rng.randf_range(-100,-5),"off":(7.5 if i%2==0 else -7.5),"dir":(1.0 if i%3==0 else -1.0),"ph":rng.randf()*6.0})
		place_ped(peds[-1])
func ped_pos(p:Dictionary)->Vector3:
	var st:Array=ped_streets[p.si]
	return Vector3(st[1]+p.off,0,p.t) if st[0] else Vector3(p.t,0,st[1]+p.off)
func place_ped(p:Dictionary):
	var n:Node3D=p.d.root; n.position=ped_pos(p)
	var st:Array=ped_streets[p.si]
	var dirv:=Vector3(0,0,p.dir) if st[0] else Vector3(p.dir,0,0)
	n.rotation.y=atan2(dirv.x,dirv.z)
func update_peds(dt:float):
	for p in peds:
		var n:Node3D=p.d.root
		var st:Array=ped_streets[p.si]
		var lo:float=minf(st[2],st[3]); var hi:float=maxf(st[2],st[3])
		p.t+=p.dir*1.3*dt
		if p.t<lo or p.t>hi: p.dir=-p.dir; p.t=clampf(p.t,lo,hi)
		var d:=player.position.distance_to(n.position)
		if d>70.0:
			# jump to a street near the player, out of sight
			var best:=-1; var bd:=1e9
			for k in range(ped_streets.size()):
				var s2:Array=ped_streets[k]
				var ap:=Vector3(s2[1],0,clampf(player.position.z,-108,4)) if s2[0] else Vector3(clampf(player.position.x,-108,108),0,s2[1])
				var dd:=ap.distance_to(player.position)
				if dd<bd and randf()<0.7: bd=dd; best=k
			if best>=0:
				p.si=best; var s3:Array=ped_streets[best]
				var pt:float=(player.position.z if s3[0] else player.position.x)+randf_range(25,45)*(1.0 if randf()<0.5 else -1.0)
				p.t=clampf(pt,minf(s3[2],s3[3]),maxf(s3[2],s3[3])); p.off=7.5*(1.0 if randf()<0.5 else -1.0)
				if d>1e8: pass
		place_ped(p)
		var deep:bool=fmod(hud_min/60.0,24.0)<4.5
		n.visible=in_room=='' and not deep and player.position.distance_to(n.position)<32.0
		if not p.has("bub"):
			var lb:=Label3D.new(); lb.font=ar; lb.font_size=64; lb.pixel_size=0.007; lb.billboard=BaseMaterial3D.BILLBOARD_ENABLED; lb.no_depth_test=true; lb.modulate=Color(1,1,1); lb.outline_modulate=Color(0.25,0.1,0.2); lb.outline_size=14; lb.position=Vector3(0,2.9,0); lb.visible=false; n.add_child(lb); p["bub"]=lb; p["bt"]=0.0; p["gday"]=-1
		var bl:Label3D=p.bub
		if p.bt>0.0:
			p.bt-=dt
			if p.bt<=0.0: bl.visible=false
		elif in_room=='' and mode=='play' and player.position.distance_to(n.position)<2.6:
			var gd:=int(hud_min/1440.0)
			var hr:=int(fmod(hud_min,1440.0)/60.0)
			var greets=["أهلاً يا جميل","منور الحي!","سلام!"]
			if hr<12: greets+=["صباح الخير!","صباح النور!"]
			elif hr<18: greets+=["يوم حلو النهاردة","عاش، نهارك سعيد"]
			else: greets+=["مساء الخير","ليلة حلوة!","خلي بالك من نفسك"]
			bl.text=greets[randi()%greets.size()]; bl.visible=true; p.bt=2.5
			if p.gday!=gd: p.gday=gd; stats['المجتمع']=clampi(stats['المجتمع']+1,0,100); qadd('greet')
		var sw:=sin(Time.get_ticks_msec()*0.006+p.ph)*0.6
		var dd2:Dictionary=p.d
		dd2.legl.rotation.x=sw; dd2.legr.rotation.x=-sw; dd2.arml.rotation.x=-sw*0.8; dd2.armr.rotation.x=sw*0.8

var save_t:=0.0
func save_game():
	var d={'stats':stats,'inv':inv,'aff':aff,'aff_day':aff_day,'rel_seen':rel_seen,'min':hud_min,'outfit':outfit_i,'qday':qday,'qp':qp,'qdone':qdone,'year':year_shown,'owned':owned.keys(),'energy':energy,'who':who_pick,'read':read_ids.keys(),'px':(street_ret.x if in_room!='' else player.position.x),'pz':(street_ret.z if in_room!='' else player.position.z)}
	var f=FileAccess.open('user://save.json',FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d))
func load_game():
	if not FileAccess.file_exists('user://save.json'): return
	var d=JSON.parse_string(FileAccess.get_file_as_string('user://save.json'))
	if typeof(d)!=TYPE_DICTIONARY: return
	for k in d.get('stats',{}): stats[k]=int(d.stats[k])
	for k in d.get('inv',{}): inv[k]=int(d.inv[k])
	for k in d.get('aff',{}): aff[k]=int(d.aff[k])
	aff_day=d.get('aff_day',{}); rel_seen=d.get('rel_seen',{})
	hud_min=float(d.get('min',hud_min)); if d.has('px') and in_room=='': player.position=Vector3(clampf(float(d.px),-8.0,60.0),0,clampf(float(d.pz),-118.0,4.0))
	energy=int(d.get('energy',energy))
	for k in d.get('read',[]): read_ids[k]=true
	qday=int(d.get('qday',-1)); qp=d.get('qp',{}); qdone=d.get('qdone',{}); year_shown=bool(d.get('year',false))
	for k in d.get('owned',[]): owned[int(k)]=true
	if int(d.get('outfit',0))>0: apply_outfit(int(d.outfit))
func _notification(what):
	if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_WM_GO_BACK_REQUEST or what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		if mode!='select' and not ('shot' in OS.get_cmdline_user_args()): save_game()
func _process(dt):
	if mode=='play' and not ('shot' in OS.get_cmdline_user_args()):
		save_t+=dt
		if save_t>15.0: save_t=0.0; save_game()
	for n in npcs:
		n.n.visible=in_room=='' and player.position.distance_to(n.n.position)<14.0
		if n.key=='momo' and (fmod(hud_min/60.0,24.0)<5.0 or fmod(hud_min/60.0,24.0)>=23.0): n.n.visible=false
		elif n.key=='momo' and n.n.visible:
			var mt:float=Time.get_ticks_msec()*0.0006
			var mx:float=1.8+1.6*sin(mt); n.n.position=Vector3(mx,0.05*absf(sin(mt*9.0)),-12.0)
			n.n.rotation.y=(1.57 if cos(mt)>0 else -1.57)
		if n.n.visible and n.key!='momo':
			var ph:float=float(n.n.get_instance_id()%97)
			var tt:float=Time.get_ticks_msec()*0.0021+ph
			n.n.scale=Vector3(1.0,1.0+0.012*sin(tt),1.0)
			var al=n.n.get_node_or_null("arml"); var ar2=n.n.get_node_or_null("armr")
			if al: al.rotation.z=0.06+0.05*sin(tt+0.8)
			if ar2: ar2.rotation.z=-0.06-0.05*sin(tt+0.8)
	if peds.size()>0: update_peds(dt)
	if cars.size()>0: update_cars(dt)
	if city_map and city_map.visible and map_layer.visible: city_dot.queue_redraw()
	if mode!='play':
		if mode=='scene': return
		return
	check_triggers()
	hud_min+=dt*2.0
	apply_tod(dt)
	var hh=int(hud_min/60.0)%12; if hh==0: hh=12
	var day=1+int(hud_min/1440.0)
	if day>=29 and not year_shown and mode=='play' and in_room=='': year_shown=true; show_year_end()
	var ht="يوم %d، %s، %s"%[day,tod(),["ربيع","صيف","خريف","شتاء"][int((day-1)/7)%4]]
	if ht!=hud_time.text: hud_time.text=ht
	if mode=='play' and in_room=='' and player.position.x>18.0 and player.position.x<66.0:
		bench_cd-=dt
		var bz:float=player.position.z
		var nearb:=false
		for k in range(5):
			var bx:float=20.0+k*9.0
			if (absf(player.position.x-bx)<1.3 and absf(bz+7.2)<1.2) or (absf(player.position.x-bx-4.0)<1.3 and absf(bz+13.8)<1.2): nearb=true
		if nearb and bench_cd<=0.0:
			bench_cd=40.0; hud_min+=20.0; hud_clock.queue_redraw()
			if energy<5: energy+=1; hearts.queue_redraw()
			stats['الصحة']=clampi(stats['الصحة']+1,0,100)
			player_say("قعدت ارتاحت شوية على الكنبة"); qadd("rest")
	if bench_t>0.0:
		bench_t-=dt
		if bench_t<=0.0 and bench_lb!=null: bench_lb.visible=false
	if int(hud_min)%5==0 and int(hud_min)!=last_min: last_min=int(hud_min); hud_clock.queue_redraw()
	var v:=joy_vec
	var k:=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	if k.length()>0.1: v=k
	var moving=v.length()>0.1
	if moving:
		var dir:=Vector3(v.x,0,v.y).normalized()
		player.position+=dir*v.length()*4.2*dt
		player.position=clamp_walk(player.position)
		var tgt=atan2(dir.x,dir.z)
		player.rotation.y=lerp_angle(player.rotation.y,tgt,10*dt)
		walk_t+=dt*9.0*v.length()
		foot_t-=dt
		if foot_t<=0: foot_t=0.36/max(v.length(),0.4); sfx('foot',randf_range(0.85,1.15))
		var sw=sin(walk_t)*0.7
		legl.rotation.x=sw; legr.rotation.x=-sw; arml.rotation.x=-sw*0.8; armr.rotation.x=sw*0.8
		player.position.y=abs(sin(walk_t))*0.05
	else:
		for n in [legl,legr,arml,armr]: n.rotation.x=lerp(n.rotation.x,0.0,10*dt)
		player.position.y=0
	var target=player.position+(Vector3(0,5.6,5.6) if in_room!='' else Vector3(0,3.6,6.0))
	if get_tree().root.has_meta("x"): return
	cam.position=cam.position.lerp(target,min(1.0,6*dt))
	cam.look_at(player.position+(Vector3(0,0.3,-2.0) if in_room!='' else Vector3(0,1.3,-1.5)))
	petals.position=player.position+Vector3(0,5,-4)

var frames:=0

var walk_rects:=[Rect2(-8.5,-120,17,126),Rect2(8,-19.5,53,18),Rect2(-78.5,-114,17,120),Rect2(61.5,-114,17,120),Rect2(-112,-47.25,224,17),Rect2(-112,-108.5,224,17)]
func clamp_walk(p:Vector3)->Vector3:
	if in_room!='':
		return Vector3(clamp(p.x,bnd.position.x,bnd.end.x),p.y,clamp(p.z,bnd.position.y,bnd.end.y))
	var best:=Vector3.ZERO; var bd:=1e9
	for r in walk_rects:
		var q:=Vector3(clamp(p.x,r.position.x,r.end.x),p.y,clamp(p.z,r.position.y,r.end.y))
		var d:=q.distance_squared_to(p)
		if d<bd: bd=d; best=q
	return best

func _physics_process(_d):
	if "shot" in OS.get_cmdline_user_args():
		frames+=1
		if frames<8: joy_vec=Vector2(0.0,-1)
		if frames==30 and 'scene' in OS.get_cmdline_user_args(): player.position.z=-76
		if frames==40 and 'choice' in OS.get_cmdline_user_args(): advance()
		if frames==40 and 'stats' in OS.get_cmdline_user_args(): advance(); choose(0); mode='stats'; stats_layer.visible=true; stats_layer.get_meta('pc').queue_redraw()
		if frames==59 and "front" in OS.get_cmdline_user_args():
			cam.position=player.position+Vector3(0.9,2.0,-3.0); cam.fov=40; cam.look_at(player.position+Vector3(0,1.7,0)); get_tree().root.set_meta('x',true); player.rotation.y=2.9
		if frames==30 and 'cast' in OS.get_cmdline_user_args():
			var ni:=1 if 'k1' in OS.get_cmdline_user_args() else (4 if 'k4' in OS.get_cmdline_user_args() else 0)
			var tp:Vector3=npcs[ni].n.position; player.position=tp+Vector3(0,0,9); scene_layer.visible=false; mode='play'
		if frames>=50 and frames<=59 and 'cast' in OS.get_cmdline_user_args():
			var ni2:=1 if 'k1' in OS.get_cmdline_user_args() else (4 if 'k4' in OS.get_cmdline_user_args() else 0)
			var nn:Node3D=npcs[ni2].n; nn.rotation.y=0; player.visible=false; get_tree().root.set_meta("x",true)
			cam.position=nn.position+Vector3(0.6,2.0,3.6); cam.fov=40; cam.look_at(nn.position+Vector3(0,1.45,0))
		if frames==30 and 'ptr' in OS.get_cmdline_user_args():
			var pi0:int=int(OS.get_cmdline_user_args()[-1]); player.position=npcs[pi0].n.position+Vector3(0,0,9); scene_layer.visible=false; mode='play'; ui.visible=false
		if frames>=50 and frames<=59 and 'ptr' in OS.get_cmdline_user_args():
			var pi:int=int(OS.get_cmdline_user_args()[-1]); var pn:Node3D=npcs[pi].n; pn.rotation.y=0; player.visible=false; get_tree().root.set_meta("x",true)
			cam.position=pn.position+Vector3(0.1,2.0,2.3); cam.fov=34; cam.look_at(pn.position+Vector3(0,1.9,0))
		if frames==40 and ('night' in OS.get_cmdline_user_args() or 'deep' in OS.get_cmdline_user_args()): env_t=0.0
		if frames==100 and ('night' in OS.get_cmdline_user_args() or 'deep' in OS.get_cmdline_user_args()): pass
		if frames==40 and 'map' in OS.get_cmdline_user_args(): mode='play'; open_map()
		if frames==40 and 'rel' in OS.get_cmdline_user_args(): mode='play'; add_aff('كايتو',4); add_aff('أياني',7); add_aff('مومو',1); open_phone(); open_app(5)
		if frames==40 and 'ward' in OS.get_cmdline_user_args(): mode='play'; apply_outfit(1); open_phone(); open_app(6)
		if frames==40 and 'year' in OS.get_cmdline_user_args(): mode='play'; add_aff('أياني',7); stats['الدراسة']=80; hud_min=28*1440.0+600.0
		if frames==40 and 'lib' in OS.get_cmdline_user_args(): mode='play'; scene_layer.visible=false; travel('library')
		if frames==40 and 'bout' in OS.get_cmdline_user_args(): mode='play'; scene_layer.visible=false; travel('boutique')
		if frames==40 and 'quest' in OS.get_cmdline_user_args(): mode='play'; qadd('talk','a'); qadd('park'); qadd('rest'); qadd('greet'); qadd('greet'); open_phone(); open_app(7)
		if frames==40 and 'phone7' in OS.get_cmdline_user_args(): mode='play'; open_phone()
		if frames==42 and 'city' in OS.get_cmdline_user_args(): city_map.visible=true; player.position=Vector3(0,0,-60)
		if frames==40 and 'phone' in OS.get_cmdline_user_args(): mode='play'; open_phone()
		if frames==40 and 'msgs' in OS.get_cmdline_user_args(): mode='play'; hud_min=30300.0; open_msgs()
		for rk in ['cafe','konbini','home','class','store']:
			if frames==36 and rk in OS.get_cmdline_user_args(): mode='play'; scene_done.clear(); travel({'class':'school'}.get(rk,rk))
			if frames==50 and rk in OS.get_cmdline_user_args(): scene_layer.visible=false; mode='play'
			if frames==52 and rk in OS.get_cmdline_user_args(): for p in room_pts: scene_done[p.key]=true
			if frames==52 and rk in OS.get_cmdline_user_args(): player.position+=Vector3(-2.0,0,-1.5) if rk!='home' else Vector3(-1.5,0,-3.0)
		if frames==20 and 'outw' in OS.get_cmdline_user_args(): scene_layer.visible=false; mode='play'; phone_btn.visible=true; player.position=Vector3(0,0,-20); apply_outfit(3)
		if frames==20 and 'newst' in OS.get_cmdline_user_args(): scene_layer.visible=false; mode='play'; phone_btn.visible=true; player.position=Vector3(-68.5,0,-14); player.rotation.y=PI
		if frames==20 and 'snow' in OS.get_cmdline_user_args(): scene_layer.visible=false; mode='play'; phone_btn.visible=true; player.position=Vector3(0,0,-20); hud_min=21*1440.0+600.0
		if frames==20 and 'cars' in OS.get_cmdline_user_args(): scene_layer.visible=false; mode='play'; phone_btn.visible=true; player.position=Vector3(0,0,-22); cars[0].t=-30.0; cars[1].t=-34.0
		if frames==20 and 'greet' in OS.get_cmdline_user_args(): scene_layer.visible=false; mode='play'; phone_btn.visible=true; peds[0].si=0; peds[0].off=7.5; peds[0].t=-20.0; player.position=Vector3(7.5,0,-16.5)
		if frames==20 and 'talk' in OS.get_cmdline_user_args(): scene_layer.visible=false; mode='play'; player.position=Vector3(-68.5,0,-17.5)
		if frames==30 and 'talk' in OS.get_cmdline_user_args(): start_scene('w1','',npcs[5].lines)
		if frames==20 and 'momo' in OS.get_cmdline_user_args(): scene_layer.visible=false; mode='play'; player.position=Vector3(0,0,-6)
		if frames==20 and 'bench' in OS.get_cmdline_user_args(): scene_layer.visible=false; mode='play'; energy=2; player.position=Vector3(20.0,0,-7.2)
		if frames==20 and ('night' in OS.get_cmdline_user_args() or 'deep' in OS.get_cmdline_user_args()): scene_layer.visible=false; mode='play'; player.position=Vector3(0,0,-6); hud_min=(2.0 if 'deep' in OS.get_cmdline_user_args() else 22.0)*60.0; env_t=0.0; player.position=Vector3(0,0,-8)
		if frames==20 and 'rain' in OS.get_cmdline_user_args(): scene_layer.visible=false; mode='play'; player.position=Vector3(0,0,-6); env_t=0.0
		if frames==20 and 'street' in OS.get_cmdline_user_args(): scene_layer.visible=false; mode='play'; phone_btn.visible=true; player.position=Vector3(0,0,-20)
		if frames==20 and 'park' in OS.get_cmdline_user_args(): scene_layer.visible=false; mode='play'; phone_btn.visible=true; player.position=Vector3(34.5,0,-4.5)
		if frames==20 and 'world' in OS.get_cmdline_user_args(): scene_layer.visible=false; mode='play'; phone_btn.visible=true; player.position=Vector3(0,0,-30)
		if frames==5 and 'dusk' in OS.get_cmdline_user_args(): hud_min=17.5*60+(14*1440.0 if not "winter" in OS.get_cmdline_user_args() else 22*1440.0); env_t=0.0
		if frames==59: print('STAT nodes=',get_tree().get_node_count(),' draws=',RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),' prims=',RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		if frames==60:
			get_viewport().get_texture().get_image().save_png("/tmp/shot1.png"); get_tree().quit()

var energy:=5
var rain_p:AudioStreamPlayer=null
var rain_on:=false
var rain:CPUParticles3D=null
var stars:MeshInstance3D=null
var bench_cd:=0.0
var bench_t:=0.0
var bench_lb:Label3D=null
var sun:DirectionalLight3D
var env_t:=0.0
var season_i:=-1
var env:Environment
var bnd:=Rect2(-8.5,-120,17,126)
var in_room:=''
var room_pts:=[]
var room_org:={}
var street_ret:=Vector3.ZERO
var street_npcs:=[]
var exit_btn:Button
var hearts:Control
var city_map:TextureRect; var city_dot:Control; var phone_layer:Control; var map_layer:Control; var msg_layer:Control; var phone_btn:Control; var badge:Label
var msgs:=[]
var read_ids:={}
var travel_note:Label
func build_phone():
	var vs:=get_viewport().get_visible_rect().size
	hearts=Control.new(); hearts.position=Vector2(30,80); ui.add_child(hearts)
	hearts.draw.connect(func():
		for i in range(5):
			var c:=Color(1,0.3,0.45) if i<energy else Color(0.4,0.35,0.5,0.7)
			var p:=Vector2(i*34,0)
			hearts.draw_circle(p+Vector2(-6,0),9,c); hearts.draw_circle(p+Vector2(6,0),9,c)
			hearts.draw_colored_polygon(PackedVector2Array([p+Vector2(-14,4),p+Vector2(14,4),p+Vector2(0,22)]),c))
	hearts.queue_redraw()
	exit_btn=Button.new(); exit_btn.text="خروج للشارع"; exit_btn.size=Vector2(200,56); exit_btn.position=Vector2(30,vs.y-90); exit_btn.visible=false
	exit_btn.add_theme_font_override("font",ar); exit_btn.add_theme_font_size_override("font_size",26); exit_btn.pressed.connect(func(): if mode=='play': exit_room()); ui.add_child(exit_btn)
	phone_btn=Control.new(); phone_btn.position=Vector2(vs.x-150,vs.y-150); ui.add_child(phone_btn)
	phone_btn.draw.connect(func():
		phone_btn.draw_rect(Rect2(30,10,60,100),Color(0.1,0.1,0.18),true); phone_btn.draw_rect(Rect2(36,22,48,70),Color(0.55,0.85,1),true)
		phone_btn.draw_circle(Vector2(60,100),4,Color(1,1,1)))
	phone_btn.queue_redraw()
	badge=lbl("1",26,Vector2(vs.x-84,vs.y-156),Color(1,1,1)); ui.add_child(badge)
	# phone
	phone_layer=Control.new(); phone_layer.size=vs; phone_layer.visible=false; ui.add_child(phone_layer)
	var dim:=ColorRect.new(); dim.color=Color(0,0,0,0.55); dim.size=vs; phone_layer.add_child(dim)
	var body:=Panel.new(); body.size=Vector2(340,vs.y-30); body.position=Vector2(vs.x/2-170,15); body.name="body"
	var sb:=StyleBoxFlat.new(); sb.bg_color=Color(0.14,0.15,0.3); sb.set_corner_radius_all(36); sb.set_border_width_all(6); sb.border_color=Color(0.05,0.05,0.1); body.add_theme_stylebox_override("panel",sb); phone_layer.add_child(body)
	var sc:=ColorRect.new(); sc.color=Color(0.75,0.88,1); sc.size=body.size-Vector2(30,60); sc.position=body.position+Vector2(15,30); phone_layer.add_child(sc)
	phone_layer.add_child(lbl("الهاتف",34,body.position+Vector2(110,40),Color(0.1,0.1,0.3)))
	var apps=[["الخريطة",Color(1,0.8,0.5),0],["المخزون",Color(0.7,0.85,1),1],["المتجر",Color(1,0.7,0.8),2],["الإحصائيات",Color(0.7,1,0.8),3],["الإعدادات",Color(0.85,0.8,1),4],["العلاقات",Color(1,0.75,0.85),5],["الدولاب",Color(0.95,0.85,0.6),6],["المهام",Color(0.8,0.95,0.7),7]]
	for a in apps:
		var b:=Button.new(); b.size=Vector2(130,92); b.position=body.position+Vector2(25+(a[2]%2)*155,95+int(a[2]/2)*105)
		var sbb:=StyleBoxFlat.new(); sbb.bg_color=a[1]; sbb.set_corner_radius_all(26); sbb.set_border_width_all(4); sbb.border_color=Color(1,1,1)
		for st in ["normal","hover","pressed"]: b.add_theme_stylebox_override(st,sbb)
		b.text=a[0]; b.add_theme_font_override("font",ar); b.add_theme_font_size_override("font_size",24); b.add_theme_color_override("font_color",Color(0.1,0.1,0.25)); b.add_theme_color_override("font_hover_color",Color(0.1,0.1,0.25)); b.add_theme_color_override("font_pressed_color",Color(0.1,0.1,0.25))
		var kk:int=a[2]; b.pressed.connect(func(): open_app(kk)); phone_layer.add_child(b)
	var cb:=Button.new(); cb.text="إغلاق"; cb.size=Vector2(200,56); cb.position=body.position+Vector2(70,body.size.y-110); cb.add_theme_font_override("font",ar); cb.add_theme_font_size_override("font_size",26)
	cb.pressed.connect(close_phone); phone_layer.add_child(cb)
	travel_note=lbl("",24,body.position+Vector2(30,520),Color(0.1,0.1,0.3)); travel_note.size=Vector2(280,200); travel_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; travel_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; phone_layer.add_child(travel_note)
	app_layer=Control.new(); app_layer.size=vs; app_layer.visible=false; ui.add_child(app_layer)
	# map
	map_layer=Control.new(); map_layer.size=vs; map_layer.visible=false; ui.add_child(map_layer)
	var mbg:=ColorRect.new(); mbg.color=Color(0.96,0.93,0.85); mbg.size=vs; map_layer.add_child(mbg)
	var mh:=vs.y-90.0; var mw:=mh*595.0/600.0; var mp:=Vector2(vs.x/2-mw/2,70)
	var mt:=TextureRect.new(); mt.texture=img_tex("res://art/map.jpg"); mt.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; mt.size=Vector2(mw,mh); mt.position=mp; map_layer.add_child(mt)
	map_layer.add_child(lbl("خريطة تلة ساكورا",40,Vector2(vs.x/2-150,8),Color(0.9,0.3,0.4)))
	var places=[["المدرسة","school",Vector2(160,70)],["البيت","home",Vector2(340,85)],["الكافيه","cafe",Vector2(180,315)],["السوبر ماركت","store",Vector2(500,380)],["الحديقة","park",Vector2(260,400)],["كونبيني","konbini",Vector2(330,290)],["المكتبة","library",Vector2(470,230)],["البوتيك","boutique",Vector2(105,235)]]
	for p in places:
		var b:=Button.new(); b.text=p[0]; b.size=Vector2(150,50); b.position=mp+p[2]*(mh/600.0)-Vector2(75,25)
		b.add_theme_font_override("font",ar); b.add_theme_font_size_override("font_size",24)
		var sbm:=StyleBoxFlat.new(); sbm.bg_color=Color(1,0.93,0.6,0.95); sbm.set_corner_radius_all(14); sbm.set_border_width_all(3); sbm.border_color=Color(0.35,0.2,0.3)
		for st in ["normal","hover","pressed"]: b.add_theme_stylebox_override(st,sbm)
		for st in ["font_color","font_hover_color","font_pressed_color"]: b.add_theme_color_override(st,Color(0.15,0.08,0.2))
		var key:String=p[1]; b.pressed.connect(func(): travel(key)); map_layer.add_child(b)
	# city grid minimap
	var cm:=TextureRect.new(); cm.texture=img_tex("res://art/citymap.png"); cm.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	var cw:=vs.x-40.0; var ch:=cw*0.6
	cm.size=Vector2(cw,ch); cm.position=Vector2(20,(vs.y-ch)/2+20); cm.visible=false; map_layer.add_child(cm); city_map=cm
	var dot:=Control.new(); dot.size=cm.size; dot.mouse_filter=Control.MOUSE_FILTER_IGNORE; cm.add_child(dot); city_dot=dot
	dot.draw.connect(func():
		var px:=(player.position.x+116.0)/232.0*dot.size.x
		var pz:=(8.0-player.position.z)/232.0/0.99*dot.size.x
		dot.draw_circle(Vector2(px,pz),dot.size.x*0.012+3,Color(1,1,1)); dot.draw_circle(Vector2(px,pz),dot.size.x*0.009,Color(1,0.2,0.35)))
	var names=[["شارع الساكورا",0.0,-60.0],["شارع الأمل",-70.0,-60.0],["شارع النور",70.0,-60.0]]
	for nm in names:
		var l:=lbl(nm[0],22,Vector2((nm[1]+116.0)/232.0*cw-70,ch*0.015),Color(0.25,0.1,0.3)); l.size=Vector2(140,30); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; cm.add_child(l)
	var tg:=Button.new(); tg.text="مدينتي"; tg.size=Vector2(170,52); tg.position=Vector2(vs.x-200,10); tg.add_theme_font_override("font",ar); tg.add_theme_font_size_override("font_size",26)
	tg.pressed.connect(func(): city_map.visible=not city_map.visible; tg.text=("الأماكن" if city_map.visible else "مدينتي")); map_layer.add_child(tg)
	var back:=Button.new(); back.text="رجوع"; back.size=Vector2(140,52); back.position=Vector2(30,10); back.add_theme_font_override("font",ar); back.add_theme_font_size_override("font_size",26)
	back.pressed.connect(func(): map_layer.visible=false; phone_layer.visible=true; mode='phone'); map_layer.add_child(back)
	# messages
	msg_layer=Control.new(); msg_layer.size=vs; msg_layer.visible=false; ui.add_child(msg_layer)
	var gbg:=ColorRect.new(); gbg.color=Color(0.85,0.95,0.9); gbg.size=vs; msg_layer.add_child(gbg)
	msg_layer.add_child(lbl("الرسائل",40,Vector2(vs.x/2-60,10),Color(0.1,0.3,0.25)))
	var back2:=Button.new(); back2.text="رجوع"; back2.size=Vector2(140,52); back2.position=Vector2(30,10); back2.add_theme_font_override("font",ar); back2.add_theme_font_size_override("font_size",26)
	back2.pressed.connect(func(): msg_layer.visible=false; phone_layer.visible=true; mode='phone'); msg_layer.add_child(back2)
	msgs=[
	{"id":"m1","from":"كايتو","text":"تيجي الكافيه بعد المدرسة؟ أنا حاجز لنا الترابيزة اللي جنب الشباك","after":0,"face":"youssef_smile","bg":"in_cafe","lines":[["كايتو","أخيراً جيت! اطلب أي حاجة، النهاردة عليّ.","youssef_joy",[["أطلب قهوة وأقعد معاه","العلاقات",8,-1],["أسأله لو في شغل هنا","الفلوس",5,-1]]]]},
	{"id":"m2","from":"أياني","text":"تنبيه مذاكرة: الامتحان بعد أسبوع. مش هسيبك تسبقني.","after":720,"face":"rana_think","bg":"school_hall","lines":[["أياني","فاكر الامتحان؟ أنا بذاكر من ٣ أيام.","rana_think",[["أذاكر معاها","الدراسة",10,-1],["أنا هتصرف","الصحة",3,0]]]]},
	{"id":"m3","from":"مومو","text":"مياو! القطة مومو واقفة قدام البيت وعايزة أكل","after":1500,"face":"youssef_joy","bg":"in_room","lines":[["أنا","مومو جت تسلم عليا. هديها شوية لبن.","%s","[]"]]},
	{"id":"m4","from":"أياني","text":"مهرجان المدرسة الأسبوع الجاي! محتاجة حد يساعدني في الزينة","after":4320,"face":"rana_smile","bg":"school_hall","lines":[["أياني","المهرجان بعد أسبوع، وأنا مسؤولة عن الزينة. مش هقدر أعملها لوحدي.","rana_calm"],["أياني","ممكن تساعدني؟ مش تفتكر إني محتاجاك، بس الشغل كتير.","rana_smile",[["أساعدها في الزينة","العلاقات",10],["أراجع للامتحان","الدراسة",8]]]]},
	{"id":"m5","from":"كايتو","text":"الصيف جه! تعالى نروح نلعب كورة في الحديقة","after":10080,"face":"youssef_joy","bg":"ex_hill","lines":[["كايتو","الصيف بدأ يا باشا! الجو حر بس الحديقة حلوة.","youssef_laugh"],["كايتو","هات مية وتعالى نلعب شوية.","youssef_joy",[["أروح ألعب","الصحة",10],["أقعد في الكافيه","العلاقات",6]]]]},
	{"id":"m6","from":"هدى","text":"وصل كتب جديدة في مكتبة النور. تعالى شوفهم","after":14400,"face":"rana_calm","bg":"in_room","lines":[["هدى","وصلتني كتب جديدة النهاردة، بتاعة حكايات وقصص.","rana_calm"],["هدى","لو جيت المكتبة هسيبلك تقرا الأول.","rana_smile",[["أروح أقرا","الدراسة",8],["بعدين","المجتمع",2]]]]},
	{"id":"m7","from":"مومو","text":"مياو مياو! مومو ضاعت في الخريف وسط الورق!","after":18000,"face":"youssef_joy","bg":"in_room","lines":[["أنا","مومو مش في مكانها. دورت عليها في الورق الأحمر والبرتقالي.","%s"],["أنا","لقيتها نايمة تحت الشجرة! 🐱","%s",[["أحملها وأرجعها","الصحة",6],["أصورها","المجتمع",5]]]]},
	{"id":"m8","from":"أياني","text":"أول تلج النهاردة! تعالى المدرسة نعمل رجل تلج","after":30240,"face":"rana_smile","bg":"school_front","lines":[["أياني","التلج نزل! أول مرة أشوفه بالشكل ده في ساكورا هيل.","rana_smile"],["أياني","تعالى نعمل رجل تلج قدام المدرسة، من غير ما حد يشوفنا 😄","rana_smile",[["أروح معاها","العلاقات",10],["أستنى جوا","الصحة",3]]]]}]
	refresh_badge()
func new_msgs()->Array:
	var out:=[]
	for m in msgs:
		if hud_min>=480+m.after and not read_ids.has(m.id): out.append(m)
	return out
func refresh_badge():
	badge.visible=false
func open_phone():
	mode='phone'; phone_layer.visible=true; refresh_badge()
	var body:Control=phone_layer.get_node("body"); var y0:=body.position.y
	phone_layer.position.y=700; var tw:=create_tween(); tw.tween_property(phone_layer,"position:y",0.0,0.25)
func close_phone():
	phone_layer.visible=false; mode='play'; phone_layer.position.y=0
func open_map():
	phone_layer.visible=false; map_layer.visible=true; mode='map'
func open_msgs():
	phone_layer.visible=false; msg_layer.visible=true; mode='phone'
	for c in msg_layer.get_children():
		if c.has_meta("row"): c.queue_free()
	var vs:=get_viewport().get_visible_rect().size; var y:=90.0
	var shown:=[]
	for m in msgs:
		if hud_min>=480+m.after: shown.append(m)
	shown.reverse(); shown=shown.slice(0,5)
	for m in shown:
		var b:=Button.new(); b.set_meta("row",true); b.size=Vector2(vs.x-120,74); b.position=Vector2(60,y); y+=84
		var done=read_ids.has(m.id)
		b.text=m.from+": "+m.text+("" if done else "  ●")
		b.add_theme_font_override("font",ar); b.add_theme_font_size_override("font_size",24); b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var sbb:=StyleBoxFlat.new(); sbb.bg_color=Color(1,1,1) if done else Color(1,0.95,0.7); sbb.set_corner_radius_all(18); sbb.set_border_width_all(3); sbb.border_color=Color(0.3,0.5,0.4)
		for st in ["normal","hover","pressed"]: b.add_theme_stylebox_override(st,sbb)
		for st in ["font_color","font_hover_color","font_pressed_color"]: b.add_theme_color_override(st,Color(0.1,0.15,0.2))
		var mm=m; b.pressed.connect(func(): open_msg(mm)); msg_layer.add_child(b)
func open_msg(m):
	read_ids[m.id]=true; msg_layer.visible=false; mode='play'
	var lines=[]
	for l in m.lines:
		var ll=l.duplicate(true)
		if ll[2]=="%s": ll[2]=who_pick
		if typeof(ll[3])==TYPE_STRING: ll[3]=[]
		lines.append(ll)
	scene_done.erase("msg_"+m.id); start_scene("msg_"+m.id,m.bg,lines); refresh_badge()
func travel(key:String):
	if key!='home' and energy<1:
		map_layer.visible=false; phone_layer.visible=true; mode='phone'; travel_note.text="تعبان! روح البيت وخد نوم."; return
	map_layer.visible=false; mode='play'; phone_layer.visible=false; phone_layer.position.y=0
	if key=="park":
		qadd('park')
		hud_min+=20.0; hud_clock.queue_redraw(); energy=mini(5,energy+1); hearts.queue_redraw()
		if in_room!='': exit_room()
		player.position=Vector3(14.0,0,-10.5); player.rotation.y=-PI/2; return
	var rooms={"school":"class","home":"home","cafe":"cafe","store":"store","konbini":"konbini","library":"library","boutique":"boutique"}
	if rooms.has(key):
		hud_min+=30.0; hud_clock.queue_redraw(); enter_room(rooms[key]); return
	var bgs={"school":"school_front","home":"in_room","cafe":"in_cafe","store":"in_store","park":"ex_hill","konbini":"ex_konbini"}
	var lines=[]
	var f=who_pick
	match key:
		"school": lines=[["أنا","وصلت المدرسة. اليوم هيبقى طويل.",f,[["أدخل الفصل وأذاكر","الدراسة",6,-1],["أقعد مع الأصحاب في الساحة","العلاقات",6,-1]]]]
		"home": lines=[["أنا","كفاية النهاردة. أنام وأصحى بكرة بطاقة كاملة.",f,[]]]
		"cafe": lines=[["كايتو","شغل الباريستا ورديات نص ساعة. تحب تشتغل؟","youssef_smile",[["أشتغل ورديّة باريستا (+فلوس)","الفلوس",15,-2],["أشرب قهوة وأرتاح","الصحة",5,0]]]]
		"store": lines=[["البائع","السوبر ماركت شغال ٢٤ ساعة. اتفضل.","youssef_smile",[["أشتري أكل صحي (-٥ فلوس)","الصحة",8,-1],["أتفرج بس","المجتمع",2,0]]]]
		"park": lines=[["أنا","الحديقة هادية وشجرة الساكورا حلوة قوي.",f,[["أقعد وأفكّر","الصحة",6,0],["أقابل ناس","المجتمع",6,-1]]]]
		"konbini": lines=[["البائع","أهلاً! عروض النهاردة على الأونيجيري.","youssef_smile",[["أشتري أونيجيري","الصحة",4,0],["أمشي","المجتمع",1,0]]]]
	var cost=30.0 if key!='home' else 0.0
	scene_done.erase("tr_"+key)
	if key=='home':
		hud_min=(floor(hud_min/1440.0)+1)*1440.0+480.0; energy=5; hearts.queue_redraw()
	else: hud_min+=cost
	start_scene("tr_"+key,bgs[key],lines); refresh_badge(); hud_clock.queue_redraw()

func B(o:Vector3,sz:Vector3,c:Color,p:Vector3):
	box(self,sz,c,o+p+Vector3(0,sz.y/2,0))
func build_room(kind:String):
	var idx:=room_org.size()
	var o:=Vector3(300+idx*40,0,0); room_org[kind]=o
	batching=true
	var floor_c:=Color(0.72,0.5,0.32); var wall_c:=Color(1,0.93,0.82)
	if kind=='konbini' or kind=='store': floor_c=Color(0.92,0.94,0.98); wall_c=Color(0.85,0.95,1)
	if kind=='boutique': floor_c=Color(0.95,0.85,0.88); wall_c=Color(1,0.9,0.95)
	if kind=='library': floor_c=Color(0.6,0.42,0.3); wall_c=Color(0.95,0.88,0.75)
	if kind=='class': floor_c=Color(0.8,0.65,0.45); wall_c=Color(0.95,0.95,0.88)
	if kind=='home': floor_c=Color(0.85,0.7,0.55); wall_c=Color(1,0.88,0.92)
	B(o,Vector3(10.6,0.2,8.8),floor_c,Vector3(0,-0.2,0))
	B(o,Vector3(10.6,3.4,0.2),wall_c,Vector3(0,0,-4.3))
	B(o,Vector3(0.2,3.4,8.8),wall_c,Vector3(-5.3,0,0)); B(o,Vector3(0.2,3.4,8.8),wall_c,Vector3(5.3,0,0))
	B(o,Vector3(10.6,0.4,0.25),Color(0.55,0.35,0.25),Vector3(0,0,-4.2))
	B(o,Vector3(2.0,0.05,0.6),Color(1,0.85,0.4),Vector3(0,0.02,4.1))
	for x in [-3.3,0.0,3.3]: B(o,Vector3(1.8,1.3,0.06),Color(0.7,0.9,1),Vector3(x,1.2,-4.15))
	match kind:
		'cafe':
			pass
		'class':
			B(o,Vector3(5.5,1.6,0.1),Color(0.15,0.4,0.3),Vector3(0,1.0,-4.1))
		'home': pass
	flush_batches()
	batching=false
	prop_begin()
	match kind:
		'cafe': cafe_props(o)
		'konbini': konbini_props(o,false)
		'store': konbini_props(o,true)
		'home': home_props(o)
		'class': class_props(o)
		'library': library_props(o)
		'boutique': boutique_props(o)
	prop_end()
var pb:={}
var pb_mat:={}
var pb_on:=false
func prop_begin():
	pb.clear(); pb_mat.clear(); pb_on=true
func prop_end():
	pb_on=false
	for k in pb.keys():
		var n:=MeshInstance3D.new(); n.mesh=(pb[k] as SurfaceTool).commit(); n.material_override=pb_mat[k]; add_child(n)
	pb.clear()
func prop(pack:String,nm:String,pos:Vector3,ry:=0.0,sc:=1.0)->Node3D:
	var ps:=load("res://models/%s/%s.glb"%[pack,nm]) as PackedScene
	if ps==null: return null
	var n:=ps.instantiate() as Node3D
	var bb:AABB; var first:=true
	var ms:=n.find_children("*","MeshInstance3D",true,false)
	for m in ms:
		var a:AABB=(m as MeshInstance3D).get_aabb()
		bb=a if first else bb.merge(a); first=false
	var off:=Vector3(-(bb.position.x+bb.size.x/2),-bb.position.y,-(bb.position.z+bb.size.z/2))
	var root:=Transform3D(Basis(Vector3.UP,ry).scaled(Vector3(sc,sc,sc)),pos)*Transform3D(Basis(),off)
	for m in ms:
		var mi:=m as MeshInstance3D
		var t:=Transform3D.IDENTITY; var node:Node=mi
		while node!=n and node!=null:
			t=(node as Node3D).transform*t; node=node.get_parent()
		for sf in range(mi.mesh.get_surface_count()):
			var sm=mi.mesh.surface_get_material(sf)
			var col:Color=Color(1,0.8,0.5)
			if sm is BaseMaterial3D: col=(sm as BaseMaterial3D).albedo_color
			if pack=='mini-market' and col.r>0.96 and col.g>0.96 and col.b>0.96:
				var mc:={'shelf-boxes':Color(0.95,0.78,0.5),'shelf-bags':Color(0.6,0.85,0.92),'shelf-end':Color(0.92,0.6,0.62),'freezers-standing':Color(0.68,0.88,1),'cash-register':Color(0.6,0.62,0.75),'display-bread':Color(0.95,0.75,0.45),'display-fruit':Color(0.7,0.9,0.5),'shopping-basket':Color(1,0.5,0.4),'shopping-cart':Color(0.7,0.72,0.8)}
				col=mc.get(nm,Color(0.9,0.85,0.7))
			if pack=='food':
				var fc:={'cake':Color(1,0.75,0.8),'croissant':Color(0.9,0.6,0.25),'donut-sprinkles':Color(1,0.6,0.75),'cupcake':Color(0.7,0.85,1),'cup-coffee':Color(0.95,0.95,1)}
				col=fc.get(nm,Color(1,0.8,0.5))
			var key:=str(col)
			if not pb.has(key):
				pb[key]=SurfaceTool.new(); pb_mat[key]=mat(col,true,0.02)
			(pb[key] as SurfaceTool).append_from(mi.mesh,sf,root*t)
	n.queue_free(); return null
func konbini_props(o:Vector3,big:bool):
	var M:='mini-market'; var S:=2.5
	var rows:=[-0.6,1.2] if not big else [-1.2,0.4,2.0]
	for z in rows:
		for k in range(3): prop(M,'shelf-boxes' if int(z*10+k)%2==0 else 'shelf-bags',o+Vector3(-3.3+k*2.0,0,z),0.0,S)
		prop(M,'shelf-end',o+Vector3(-4.6,0,z),0.0,S)
	for z in [-2.6,-0.6,1.4]: prop(M,'freezers-standing',o+Vector3(4.5,0,z),-1.57,S)
	prop('furniture','kitchenCabinet',o+Vector3(-3.6,0,-3.3),0.0,S); prop('furniture','kitchenCabinet',o+Vector3(-2.4,0,-3.3),0.0,S)
	prop(M,'cash-register',o+Vector3(-3.0,1.12,-3.3),0.0,1.6)
	prop(M,'display-bread',o+Vector3(0.8,0,-3.2),0.0,S); prop(M,'display-fruit',o+Vector3(2.6,0,-3.2),0.0,S)
	prop(M,'shopping-basket',o+Vector3(3.4,0,2.8),0.0,S)
	if big: prop(M,'shopping-cart',o+Vector3(-4.2,0,3.0),0.5,S)
	prop('furniture','pottedPlant',o+Vector3(-4.6,0,3.0),0.0,S)
func home_props(o:Vector3):
	var F:='furniture'; var S:=2.5
	prop(F,'bedSingle',o+Vector3(-3.4,0,-2.4),1.57,1.6)
	prop(F,'sideTableDrawers',o+Vector3(-4.6,0,-0.4),1.57,S); prop(F,'lampRoundTable',o+Vector3(-4.6,0.9,-0.4),0.0,S)
	prop(F,'desk',o+Vector3(2.0,0,-3.2),0.0,S); prop(F,'chairDesk',o+Vector3(2.0,0,-2.1),3.14,S)
	prop(F,'computerScreen',o+Vector3(2.0,0.95,-3.3),0.0,S); prop(F,'computerKeyboard',o+Vector3(2.0,0.95,-2.9),0.0,S)
	prop(F,'bookcaseClosedWide',o+Vector3(4.2,0,-3.3),0.0,S); prop(F,'bookcaseClosedDoors',o+Vector3(4.7,0,-1.0),-1.57,S)
	prop(F,'rugRectangle',o+Vector3(0,0.02,1.0),0.0,3.4)
	prop(F,'loungeSofa',o+Vector3(-3.2,0,3.0),3.14,S)
	prop(F,'cabinetTelevision',o+Vector3(2.6,0,3.3),3.14,S); prop(F,'televisionModern',o+Vector3(2.6,0.9,3.3),3.14,S)
	prop(F,'pottedPlant',o+Vector3(4.5,0,3.0),0.0,S); prop(F,'pillow',o+Vector3(-3.4,0.8,-2.0),0.5,S)
func class_props(o:Vector3):
	var F:='furniture'; var S:=2.5
	for r in range(3):
		for c in range(3):
			var p:=Vector3(-3.2+c*3.2,0,-0.8+r*2.0)
			prop(F,'desk',o+p,0.0,S); prop(F,'chairDesk',o+p+Vector3(0,0,0.9),3.14,S)
	prop(F,'desk',o+Vector3(3.6,0,-3.2),0.0,3.0); prop(F,'chairDesk',o+Vector3(3.6,0,-2.2),3.14,S)
	prop(F,'bookcaseClosedWide',o+Vector3(-3.6,0,-3.7),0.0,S); prop(F,'pottedPlant',o+Vector3(-4.7,0,3.2),0.0,S)
	prop(F,'trashcan',o+Vector3(4.6,0,3.2),0.0,S)
	var lb:=Label3D.new(); lb.text="الفصل 2-أ"; lb.font=ar; lb.font_size=120; lb.pixel_size=0.006; lb.modulate=Color(1,1,0.9); lb.outline_modulate=Color(0.1,0.25,0.2); lb.outline_size=16
	lb.position=o+Vector3(0,1.8,-4.0); add_child(lb)
func boutique_props(o:Vector3):
	var F:='furniture'; var S:=2.5
	for k in range(5): prop(F,'coatRackStanding',o+Vector3(-3.6+k*1.8,0,-3.3),0.0,S)
	for x in [-3.0,3.0]: prop(F,'loungeSofa',o+Vector3(x,0,2.4),3.14,S*0.8)
	prop(F,'rugRound',o+Vector3(0,0.02,0.6),0.0,4.5)
	for z in [-1.2,0.6]: prop(F,'coatRackStanding',o+Vector3(-4.7,0,z),1.57,S); prop(F,'coatRackStanding',o+Vector3(4.7,0,z),-1.57,S)
	prop(F,'pottedPlant',o+Vector3(0,0,-1.2),0.0,S)
	prop(F,'lampWall',o+Vector3(-5.1,2.5,0.5),1.57,S); prop(F,'lampWall',o+Vector3(5.1,2.5,0.5),-1.57,S)
	var lb:=Label3D.new(); lb.text="بوتيك ساكورا"; lb.font=ar; lb.font_size=140; lb.pixel_size=0.006; lb.modulate=Color(1,0.7,0.85); lb.outline_modulate=Color(0.3,0.1,0.2); lb.outline_size=24
	lb.position=o+Vector3(0.0,2.9,-4.0); add_child(lb)
func library_props(o:Vector3):
	var F:='furniture'; var S:=2.5
	for k in range(4): prop(F,'bookcaseClosedWide',o+Vector3(-3.6+k*2.4,0,-3.7),0.0,S)
	for z in [-1.4,0.6]: prop(F,'bookcaseOpen',o+Vector3(-4.9,0,z),1.57,S); prop(F,'bookcaseOpen',o+Vector3(4.9,0,z),-1.57,S)
	for p in [Vector3(-1.6,0,1.6),Vector3(1.6,0,1.6)]:
		prop(F,'tableRound',o+p,0.0,S); prop(F,'chairCushion',o+p+Vector3(-1.1,0,0),1.57,S); prop(F,'chairCushion',o+p+Vector3(1.1,0,0),-1.57,S)
		prop(F,'books',o+p+Vector3(0,0.9,0),0.0,2.0)
	prop(F,'desk',o+Vector3(-3.4,0,-1.9),0.0,S)
	prop(F,'rugRectangle',o+Vector3(0,0.02,0.5),0.0,3.6)
	prop(F,'pottedPlant',o+Vector3(-4.5,0,3.0),0.0,S); prop(F,'pottedPlant',o+Vector3(4.5,0,3.0),0.0,S)
	prop(F,'lampWall',o+Vector3(-5.1,2.5,0.5),1.57,S); prop(F,'lampWall',o+Vector3(5.1,2.5,0.5),-1.57,S)
	var lb:=Label3D.new(); lb.text="مكتبة النور"; lb.font=ar; lb.font_size=140; lb.pixel_size=0.006; lb.modulate=Color(1,0.9,0.6); lb.outline_modulate=Color(0.3,0.15,0.1); lb.outline_size=24
	lb.position=o+Vector3(0.0,2.9,-4.0); add_child(lb)
func cafe_props(o:Vector3):
	var F:='furniture'; var S:=2.5
	for k in range(6): prop(F,'kitchenCabinet',o+Vector3(-3.1+k*1.25,0,-3.2),0.0,S)
	prop(F,'kitchenCoffeeMachine',o+Vector3(-2.5,1.12,-3.3),0.0,S)
	prop('food','cake',o+Vector3(-0.3,1.12,-3.2),0.0,1.0); prop('food','croissant',o+Vector3(0.7,1.12,-3.2),0.0,2.0); prop('food','donut-sprinkles',o+Vector3(1.5,1.12,-3.2),0.0,2.0); prop('food','cupcake',o+Vector3(2.3,1.12,-3.2),0.0,2.0)
	for x in [-3.6,-1.8]: prop(F,'kitchenCabinetUpperDouble',o+Vector3(x,2.2,-3.95),0.0,S)
	prop(F,'kitchenFridge',o+Vector3(4.2,0,-3.4),0.0,S)
	for x in [-1.8,0.0,1.8]: prop(F,'stoolBar',o+Vector3(x,0,-1.9),0.0,S)
	var tp=[Vector3(-3.2,0,1.0),Vector3(0.2,0,1.6),Vector3(3.3,0,0.7)]
	for p in tp:
		prop(F,'tableRound',o+p,0.0,S)
		prop(F,'chairCushion',o+p+Vector3(-1.2,0,0),1.57,S); prop(F,'chairCushion',o+p+Vector3(1.2,0,0),-1.57,S)
		prop('food','cup-coffee',o+p+Vector3(-0.3,0.9,0),0.0,2.0); prop('food','cake',o+p+Vector3(0.3,0.9,0.1),0.0,0.9)
	prop(F,'pottedPlant',o+Vector3(-4.5,0,2.9),0.0,S); prop(F,'pottedPlant',o+Vector3(4.5,0,2.9),0.0,S)
	prop(F,'bookcaseOpen',o+Vector3(-4.9,0,-1.0),1.57,S)
	prop(F,'rugRound',o+Vector3(0,0.02,1.2),0.0,4.0)
	prop(F,'coatRackStanding',o+Vector3(4.7,0,1.9),0.0,S)
	prop(F,'lampWall',o+Vector3(-5.1,2.5,0.5),1.57,S); prop(F,'lampWall',o+Vector3(5.1,2.5,0.5),-1.57,S)
	var lb:=Label3D.new(); lb.text="كافيه الهدوء"; lb.font=ar; lb.font_size=140; lb.pixel_size=0.006; lb.modulate=Color(1,0.85,0.5); lb.outline_modulate=Color(0.3,0.15,0.1); lb.outline_size=24
	lb.position=o+Vector3(0.9,2.9,-4.0); add_child(lb)
func spawn_room_npc(kind:String,node:Node3D,rel:Vector3,key:String,lines:Array,face:=0.0):
	node.position=room_org[kind]+rel; node.rotation.y=face; add_child(node); room_pts.append({"n":node,"key":key,"bg":"","lines":lines,"r":2.4})
func room_extras(kind:String):
	no_outline=false
	match kind:
		'cafe':
			var ka:=make_boy(Color(0.9,0.68,0.52),Color(0.42,0.24,0.12),true)
			spawn_room_npc(kind,ka.root,Vector3(-3.2,0,1.8),"r_cafe_k",[["كايتو","اتأخرت! اقعد، النهاردة عليّ. تحب تشتغل ورديّة هنا بعد القهوة؟","youssef_joy",[["أقعد معاه","العلاقات",8,-1],["أشتغل ورديّة باريستا","الفلوس",15,-2]]]],3.14)
		'konbini','store':
			var cs:=make_girl(Color(1,0.88,0.8),Color(0.3,0.25,0.2),Color(0.2,0.6,0.35),Color(0.2,0.6,0.35),Color(1,1,1),false)
			spawn_room_npc(kind,cs.root,Vector3(-3.5,0,-2.3),"r_shop",[["البائعة","أهلاً وسهلاً! اتفضل، عروض النهاردة على الأونيجيري والعصير.","rana_smile",[["أشتري أكل (-٥ فلوس)","الصحة",8,-1],["أتفرج بس","المجتمع",2,0]]]],0.0)
		'boutique':
			var bu:=make_girl(Color(1,0.86,0.78),Color(0.15,0.1,0.15),Color(0.9,0.3,0.5),Color(0.9,0.3,0.5),Color(1,1,1),true)
			spawn_room_npc(kind,bu.root,Vector3(0.0,0,-1.9),"r_boutique",[["صاحبة البوتيك","أهلاً بيك! ستايلات جديدة كل أسبوع. افتح الدولاب في الهاتف وشوف الجديد.","rana_smile",[["أسألها عن الموضة","المجتمع",5],["أتفرج بس","العلاقات",2]]]])
		'library':
			var hu:=make_girl(Color(0.98,0.84,0.74),Color(0.55,0.3,0.15),Color(0.5,0.7,0.9),Color(0.9,0.9,0.95),Color(1,0.5,0.6),true)
			spawn_room_npc(kind,hu.root,Vector3(0.0,0,-1.6),"r_huda",[["هدى","أهلاً في مكتبة النور! الهدوء هنا بيخلي المذاكرة أسهل بكتير.","rana_calm",[["أذاكر ساعة","الدراسة",10,-1],["أقرا رواية","الصحة",4,0]]]])
		'home':
			var cat:=Node3D.new(); mesh(cat,sph(0.22),Color(1,0.95,0.9),Vector3(0,0.22,0)); mesh(cat,sph(0.15),Color(1,0.95,0.9),Vector3(0,0.42,0.2))
			for sx in [-1,1]: mesh(cat,sph(0.05),Color(1,0.7,0.5),Vector3(sx*0.09,0.58,0.2))
			spawn_room_npc(kind,cat,Vector3(0.5,0,1.0),"r_momo",[["مومو","مياو! (مومو جت تسلم عليك)","youssef_joy",[["أحضنها","الصحة",5,0],["أديها لبن","العلاقات",4,0]]]],0.5)
			var bed:=Node3D.new(); spawn_room_npc(kind,bed,Vector3(-2.2,0,-1.2),"r_bed",[["أنا","كفاية النهاردة. أنام وأصحى بكرة بطاقة كاملة.",who_pick,[["أنام للصبح","الصحة",5,5]]]])
		'class':
			var ay:=make_girl(Color(1,0.88,0.8),Color(0.45,0.2,0.65),Color(0.17,0.3,0.6),Color(0.5,0.52,0.56),Color(0.85,0.1,0.15),true,true)
			spawn_room_npc(kind,ay.root,Vector3(0.0,0,-2.0),"r_ayane",[["أياني","ده فصلنا. أول امتحان بعد أسبوع. هتذاكر معايا؟","rana_think",[["أذاكر معاها","الدراسة",10,-1],["أنا هتصرف","الصحة",3,0]]]],0.0)
	no_outline=false
func enter_room(kind:String):
	if in_room=='' : street_ret=player.position
	if not room_org.has(kind): build_room(kind)
	# clear old points
	for p in room_pts: p.n.queue_free()
	room_pts.clear()
	room_extras(kind)
	in_room=kind; var o:Vector3=room_org[kind]
	bnd=Rect2(o.x-4.8,o.z-3.6,9.6,7.6)
	player.position=o+Vector3(0,0,3.2); cam.position=player.position+Vector3(0,5.6,5.6)
	petals.visible=false
	env.ambient_light_color=Color(1,0.86,0.68); env.ambient_light_energy=0.8; env.adjustment_saturation=1.3
	for p in room_pts: scene_done.erase(p.key)
	exit_btn.visible=true
	sfx('bong'); play_bg('cafe' if kind=='cafe' else 'street')
func exit_room():
	in_room=''; bnd=Rect2(-8.5,-120,17,126); player.position=street_ret; exit_btn.visible=false; petals.visible=true; env_t=0.0; env.ambient_light_color=Color(0.86,0.9,1.0); env.ambient_light_energy=0.55; env.adjustment_saturation=1.2
	cam.position=player.position+Vector3(0,3.6,6.0); sfx('bong'); play_bg('street')

var app_layer:Control
var inv:={}
var snd_on:=true
var hq:=false
var items:={"أونيجيري":[5,1,'الصحة',3],"قهوة":[8,1,'الصحة',2],"كيكة":[12,2,'الصحة',4],"دبدوب هدية":[20,0,'العلاقات',8]}
func clear_app():
	for c in app_layer.get_children(): c.queue_free()
func app_head(title:String,col:Color):
	clear_app(); var vs:=get_viewport().get_visible_rect().size
	var bg:=ColorRect.new(); bg.color=col; bg.size=vs; app_layer.add_child(bg)
	app_layer.add_child(lbl(title,40,Vector2(vs.x/2-80,10),Color(1,1,1)))
	var back:=Button.new(); back.text="رجوع"; back.size=Vector2(140,52); back.position=Vector2(30,10); back.add_theme_font_override("font",ar); back.add_theme_font_size_override("font_size",26)
	back.pressed.connect(func(): app_layer.visible=false; phone_layer.visible=true; mode='phone'); app_layer.add_child(back)
	var m:=lbl("الفلوس: %d   الطاقة: %d/5"%[stats['الفلوس'],energy],26,Vector2(vs.x-380,16)); app_layer.add_child(m)
func app_btn(txt:String,pos:Vector2,sz:Vector2,col:Color,cb:Callable):
	var b:=Button.new(); b.text=txt; b.size=sz; b.position=pos; b.add_theme_font_override("font",ar); b.add_theme_font_size_override("font_size",26)
	var sbb:=StyleBoxFlat.new(); sbb.bg_color=col; sbb.set_corner_radius_all(14); sbb.set_border_width_all(3); sbb.border_color=Color(0.2,0.15,0.3)
	for st in ["normal","hover","pressed"]: b.add_theme_stylebox_override(st,sbb)
	for st in ["font_color","font_hover_color","font_pressed_color"]: b.add_theme_color_override(st,Color(0.1,0.08,0.2))
	b.pressed.connect(cb); app_layer.add_child(b)
func open_app(k:int):
	sfx('click')
	if k==0: open_map(); return
	if k==3:
		phone_layer.visible=false; mode='stats'; stats_layer.visible=true; stats_layer.get_meta('pc').queue_redraw(); return
	phone_layer.visible=false; app_layer.visible=true; mode='phone'
	if k==1: show_inv()
	if k==2: show_shop()
	if k==4: show_settings()
	if k==5: show_rel()
	if k==6: show_wardrobe()
	if k==7: show_quests()

var aff:={"كايتو":0,"أياني":0,"مومو":0}
var aff_day:={}
var rel_seen:={}
var cur_key:=""
var rel_queue:=[]
var npc_of:={"gate":"أياني","class":"أياني","r_class_a":"أياني","front":"كايتو","cafe":"كايتو","r_cafe_k":"كايتو","momo":"مومو","m1":"كايتو","w1":"سعيد","w2":"ميرا","w3":"دودي","w4":"هدى","r_huda":"هدى"}
func rel_title(v:int)->String:
	if v>=10: return "قريبين جداً"
	if v>=6: return "أعز أصحاب"
	if v>=3: return "صحاب"
	if v>=1: return "معارف"
	return "غرباء"
func add_aff(who:String,n:int):
	if not aff.has(who): return
	var old:int=aff[who]; aff[who]=clampi(old+n,0,10)
	for lv in [3,6,10]:
		if old<lv and aff[who]>=lv and not rel_seen.has(who+str(lv)):
			rel_seen[who+str(lv)]=true; rel_queue.append(rel_scene(who,lv))
func rel_scene(who:String,lv:int)->Array:
	var f:="youssef_smile"; var f2:="rana_smile"
	match who+str(lv):
		"كايتو3": return [["كايتو","عارف يا باشا؟ بقالي زمان ماليش صاحب أرتاح معاه كده.",f],["كايتو","من النهاردة انت صاحبي الأصلي. لو احتجت أي حاجة أنا موجود.",f]]
		"كايتو6": return [["كايتو","أنا مش بقول ده لحد: انت أعز صاحب ليّ هنا. هعملك مفاجأة في الكافيه قريب.","youssef_joy"],["كايتو","بس متقولش لأياني، هتسخر مني 😄","youssef_laugh"]]
		"كايتو10": return [["كايتو","لو مكنتش جيت ساكورا هيل كنت لسه زي ما أنا. شكراً إنك بقيت جزء من يومي.","youssef_smile"],["كايتو","[نهاية الصداقة: ما بينكم رباط حقيقي]","youssef_joy"]]
		"أياني3": return [["أياني","بصراحة... اتفاجئت إنك مش زي ما توقعت. مش وحش.",f2],["أياني","لسه المنافسة قايمة، بس هسيبك تذاكر معايا لو حبيت.","rana_smile"]]
		"أياني6": return [["أياني","كنت فاكرة إني بحب أبقى الأولى لوحدي. بس معاك الدراسة بقت أحلى.","rana_calm"],["أياني","متفهمش غلط. ده مجرد اعتراف بالموهبة.","rana_think"]]
		"أياني10": return [["أياني","أنا... مش بعرف أقول حاجات زي دي. بس وجودك بقى حاجة مهمة في أيامي.","rana_close"],["أياني","[نهاية المنافسة اللطيفة: بقيتوا أقرب من أي حد]","rana_smile"]]
		"مومو3": return [["مومو","مياو~ (مومو بدأت تتبعك وتنام جنب رجلك)","youssef_joy"]]
		"مومو6": return [["مومو","مياو! (مومو بتجيلك كل ما تعدي الشارع دلوقتي)","youssef_joy"]]
		"مومو10": return [["مومو","مرررر... (مومو قررت إنك صاحبها للأبد)","youssef_joy"],["أنا","[نهاية القطة: عندك رفيق مخلص]","youssef_smile"]]
	return [["أنا","...",f]]
var qday:=-1
var qp:={}
var qdone:={}
var qdefs:={"talk":["اتكلم مع ٢ من أصحابك",2,20],"park":["روح الحديقة",1,10],"buy":["اشتري حاجة من المتجر",1,10],"eat":["كُل أو اشرب حاجة",1,10],"rest":["ارتاح على كنبة في الحديقة",1,10],"greet":["سلّم على ٣ ناس في الشارع",3,15]}
func qadd(k:String,who:="")->void:
	var d:=int(hud_min/1440.0)
	if d!=qday: qday=d; qp={}; qdone={}
	if k=="talk":
		var l:Array=qp.get("talkw",[])
		if who in l: return
		l.append(who); qp["talkw"]=l; qp["talk"]=l.size()
	else: qp[k]=qp.get(k,0)+1
	var q:Array=qdefs[k]
	if not qdone.has(k) and qp.get(k,0)>=q[1]:
		qdone[k]=true; stats['الفلوس']=clampi(stats['الفلوس']+q[2],0,100); sfx('bong')
		if travel_note: travel_note.text="خلصت مهمة: %s (+%d فلوس)"%[q[0],q[2]]
func show_quests():
	var d:=int(hud_min/1440.0)
	if d!=qday: qday=d; qp={}; qdone={}
	app_head("مهام النهاردة",Color(0.4,0.65,0.35)); var vs:=get_viewport().get_visible_rect().size; var y:=110.0
	for k in qdefs.keys():
		var q:Array=qdefs[k]; var ok:=qdone.has(k)
		app_layer.add_child(lbl(("✓ " if ok else "• ")+q[0]+"  ("+str(mini(qp.get(k,0),q[1]))+"/"+str(q[1])+")  +"+str(q[2])+" فلوس",30,Vector2(vs.x/2-300,y),Color(0.8,1,0.8) if ok else Color(1,1,1)))
		y+=75
	app_layer.add_child(lbl("المهام بتتجدد كل يوم",24,Vector2(vs.x/2-120,y+20),Color(1,1,0.85)))
var year_shown:=false
func show_year_end():
	phone_layer.visible=false; app_layer.visible=true; mode='phone'
	app_head("السنة الأولى",Color(0.9,0.55,0.45)); var vs:=get_viewport().get_visible_rect().size
	var best:String="كايتو"; for k in aff.keys(): if aff[k]>aff[best]: best=k
	var bs:String="الدراسة"; for k in stats.keys(): if k!='الفلوس' and stats[k]>stats[bs]: bs=k
	var ttl:String={"الدراسة":"الطالب المثالي","العلاقات":"قلب الفصل","الصحة":"بطل الطاقة","المجتمع":"نجم الحي"}.get(bs,"طالب ساكورا هيل")
	var y:=100.0
	app_layer.add_child(lbl("عدّت سنة كاملة في ساكورا هيل!",36,Vector2(vs.x/2-230,y),Color(1,1,0.9))); y+=70
	app_layer.add_child(lbl("لقبك: "+ttl,40,Vector2(vs.x/2-170,y),Color(1,0.95,0.6))); y+=75
	app_layer.add_child(lbl("أقرب صاحب ليك: %s (%d/10 قلوب)"%[best,aff[best]],30,Vector2(vs.x/2-240,y),Color(1,1,1))); y+=60
	var epi:String={"كايتو":"كايتو وعدك إنكم تفضلوا أصحاب حتى بعد التخرج.","أياني":"أياني كتبتلك رسالة طويلة وقالتلك إنك أحسن حاجة حصلتلها السنة دي.","هاروتو":"هاروتو قالك: السنة الجاية أنا اللي هسبقك!","ساكورا":"ساكورا حطت ورقة ساكورا في كتابك عشان تفتكر السنة دي."}.get(best,"صحابك في الحي مش هينسوك.")
	app_layer.add_child(lbl(epi,24,Vector2(vs.x/2-300,y-4),Color(1,0.9,0.95))); y+=50
	for k in stats.keys(): if k!='الفلوس': app_layer.add_child(lbl("%s: %d"%[k,stats[k]],28,Vector2(vs.x/2-80,y),Color(1,1,1))); y+=44
	app_layer.add_child(lbl("ارجع واكمل سنة تانية!",26,Vector2(vs.x/2-120,y+10),Color(1,1,0.85)))
var outfit_i:=0
var owned:={0:true,1:true,2:true}
var ocost:={3:30,4:35,5:40}
var outfits:=[["يونيفورم المدرسة",Color(0.17,0.3,0.6),Color(0.17,0.3,0.6),Color(1,0.35,0.5)],["فستان الصيف",Color(0.3,0.8,0.7),Color(1,0.8,0.3),Color(0.3,0.8,0.7)],["كاجوال وردي",Color(0.35,0.4,0.6),Color(1,0.65,0.78),Color(1,1,1)],["ستايل أحمر",Color(0.15,0.15,0.2),Color(0.85,0.15,0.2),Color(1,0.9,0.4)],["أخضر هادي",Color(0.95,0.95,0.9),Color(0.4,0.75,0.5),Color(0.9,0.5,0.3)],["شتوي بنفسجي",Color(0.25,0.2,0.35),Color(0.55,0.35,0.8),Color(1,0.8,0.9)]]
func apply_outfit(i:int):
	outfit_i=i; var o=outfits[i]
	for mi in player.find_children("*","MeshInstance3D",true,false):
		var m=mi.material_override
		if m is ShaderMaterial and m.shader==cshader:
			if not m.has_meta("own"): m=m.duplicate(); m.set_meta("own",true); mi.material_override=m
			m.set_shader_parameter("p_top",Vector3(o[1].r,o[1].g,o[1].b)); m.set_shader_parameter("p_bot",Vector3(o[2].r,o[2].g,o[2].b)); m.set_shader_parameter("p_acc",Vector3(o[3].r,o[3].g,o[3].b))
func show_wardrobe():
	app_head("الدولاب",Color(0.75,0.6,0.3)); var vs:=get_viewport().get_visible_rect().size
	for i in range(outfits.size()):
		var ii:int=i
		var has:bool=owned.has(i)
		var tx:String=("✓ " if i==outfit_i else "")+outfits[i][0]
		if not has: tx+=" (%d فلوس)"%ocost[i]
		app_btn(tx,Vector2(vs.x/2-250+(i%2)*260,110+int(i/2)*90),Vector2(240,70),outfits[i][1].lightened(0.3) if has else Color(0.75,0.75,0.75),func():
			if owned.has(ii): apply_outfit(ii)
			elif stats['الفلوس']>=ocost[ii]: stats['الفلوس']-=ocost[ii]; owned[ii]=true; sfx('bong'); apply_outfit(ii)
			else: sfx('click')
			show_wardrobe())
	app_layer.add_child(lbl("اللبس الرمادي مقفول، اشتريه بالفلوس من المهام",24,Vector2(vs.x/2-130,400),Color(1,1,0.85)))
func show_rel():
	app_head("العلاقات",Color(0.85,0.5,0.65)); var vs:=get_viewport().get_visible_rect().size; var y:=100.0
	for nm in aff.keys():
		var v:int=aff[nm]
		var hs:=""
		for i in range(10): hs+=("♥" if i<v else "♡")
		app_layer.add_child(lbl("%s  —  %s"%[nm,rel_title(v)],34,Vector2(vs.x/2-250,y),Color(1,1,1)))
		app_layer.add_child(lbl(hs,40,Vector2(vs.x/2-250,y+50),Color(1,0.85,0.9)))
		y+=140
	app_layer.add_child(lbl("اتكلم معاهم كل يوم أو اديهم هدية من المخزون",24,Vector2(vs.x/2-230,y+10),Color(1,1,0.85)))
func gift_pick(nm:String):
	app_head("اختار هتهدي مين",Color(0.85,0.5,0.65)); var vs:=get_viewport().get_visible_rect().size; var y:=130.0
	for w in aff.keys():
		var ww:String=w
		app_btn(ww,Vector2(vs.x/2-200,y),Vector2(400,70),Color(1,0.9,0.95),func(): give_gift(nm,ww)); y+=90
func give_gift(nm:String,who:String):
	inv[nm]-=1; add_aff(who,3); sfx('bong'); show_inv()
func show_inv():
	app_head("المخزون",Color(0.45,0.55,0.8)); var vs:=get_viewport().get_visible_rect().size; var y:=90.0
	if inv.is_empty(): app_layer.add_child(lbl("المخزون فاضي. روح المتجر!",32,Vector2(vs.x/2-200,200)))
	for nm in inv.keys():
		if inv[nm]<=0: continue
		var it:Array=items[nm]; var n:String=nm
		app_btn("%s ×%d  (استخدم)"%[nm,inv[nm]],Vector2(vs.x/2-300,y),Vector2(600,64),Color(1,0.95,0.7),func(): (gift_pick(n) if n=="دبدوب هدية" else use_item(n))); y+=76
func use_item(nm:String):
	var it:Array=items[nm]; inv[nm]-=1; energy=clampi(energy+it[1],0,5); stats[it[2]]=clampi(stats[it[2]]+it[3],0,100); hearts.queue_redraw(); qadd('eat'); sfx('open'); show_inv()
func show_shop():
	app_head("المتجر",Color(0.85,0.5,0.65)); var vs:=get_viewport().get_visible_rect().size; var y:=90.0
	for nm in items.keys():
		var it:Array=items[nm]; var n:String=nm
		app_btn("%s  —  %d فلوس"%[nm,it[0]],Vector2(vs.x/2-300,y),Vector2(600,64),Color(1,0.95,0.7) if stats['الفلوس']>=it[0] else Color(0.8,0.8,0.8),func(): buy(n)); y+=76
func buy(nm:String):
	var it:Array=items[nm]
	if stats['الفلوس']<it[0]: sfx('click'); return
	stats['الفلوس']-=it[0]; inv[nm]=inv.get(nm,0)+1; qadd('buy'); sfx('bong'); show_shop()
func show_settings():
	app_head("الإعدادات",Color(0.55,0.5,0.75)); var vs:=get_viewport().get_visible_rect().size
	app_btn("الصوت: "+("شغال" if snd_on else "مقفول"),Vector2(vs.x/2-250,140),Vector2(500,70),Color(1,0.95,0.7),func(): snd_on=not snd_on; AudioServer.set_bus_mute(0,not snd_on); show_settings())
	app_btn("الجرافيك: "+("عالي" if hq else "عادي (أخف)"),Vector2(vs.x/2-250,240),Vector2(500,70),Color(1,0.95,0.7),func(): hq=not hq; get_viewport().scaling_3d_scale=0.85 if hq else 0.6; show_settings())
	app_btn("لعبة جديدة (يمسح التقدم)",Vector2(vs.x/2-250,340),Vector2(500,70),Color(1,0.75,0.75),func(): DirAccess.remove_absolute(ProjectSettings.globalize_path('user://save.json')); get_tree().reload_current_scene())
	app_layer.add_child(lbl("الصوت والخرائط: مكتبات Kenney (CC0)",22,Vector2(vs.x/2-200,440)))
# audio
var mus:AudioStreamPlayer; var amb:AudioStreamPlayer; var sfxp:Array=[]; var sfx_i:=0; var snd:={}
var foot_t:=0.0
func build_audio():
	for n in ["music_street","music_cafe","amb_cafe","amb_street","foot","bong","click1","click2","open","horn"]:
		var st=load("res://audio/%s.ogg"%n)
		if st==null: continue
		if n.begins_with("music") or n.begins_with("amb"): st.loop=true
		snd[n]=st
	mus=AudioStreamPlayer.new(); mus.volume_db=-13; add_child(mus); amb=AudioStreamPlayer.new(); amb.volume_db=-17; add_child(amb)
	for i in range(4):
		var p:=AudioStreamPlayer.new(); p.volume_db=-6; add_child(p); sfxp.append(p)
	var rst=load("res://audio/rain.ogg")
	if rst:
		rst.loop=true; rain_p=AudioStreamPlayer.new(); rain_p.stream=rst; rain_p.volume_db=-16; rain_p.autoplay=true; rain_p.stream_paused=true; add_child(rain_p)
	var fst=load("res://audio/fountain.ogg")
	if fst:
		fst.loop=true; var fp:=AudioStreamPlayer3D.new(); fp.stream=fst; fp.position=Vector3(34.5,1.0,-10.5); fp.unit_size=5.0; fp.max_distance=32.0; fp.volume_db=-4; fp.autoplay=true; add_child(fp)
	play_bg('street')
func play_bg(kind:String):
	if snd.is_empty(): return
	var mk="music_cafe" if kind=='cafe' else "music_street"; var ak="amb_cafe" if kind=='cafe' else "amb_street"
	if mus.stream!=snd.get(mk): mus.stream=snd.get(mk); mus.play()
	if amb.stream!=snd.get(ak): amb.stream=snd.get(ak); amb.play()
func sfx(n:String,pitch:=1.0):
	if snd.is_empty(): return
	var key={"click":"click1","blip":"click2","foot":"foot","bong":"bong","open":"open"}.get(n,n)
	var p:AudioStreamPlayer=sfxp[sfx_i]; sfx_i=(sfx_i+1)%sfxp.size(); p.stream=snd.get(key); p.pitch_scale=pitch; p.play()

func player_say(t:String):
	if bench_lb==null:
		bench_lb=Label3D.new(); bench_lb.font=ar; bench_lb.font_size=64; bench_lb.pixel_size=0.007; bench_lb.billboard=BaseMaterial3D.BILLBOARD_ENABLED; bench_lb.no_depth_test=true; bench_lb.outline_modulate=Color(0.25,0.1,0.2); bench_lb.outline_size=14; bench_lb.position=Vector3(0,2.9,0); player.add_child(bench_lb)
	bench_lb.text=t; bench_lb.visible=true; bench_t=3.5

func apply_tod(dt:float):
	if rain_p!=null: rain_p.stream_paused=(in_room!='' or not rain_on)
	if rain!=null and player!=null: rain.position=player.position+Vector3(0,8,0)
	if in_room!='': return
	env_t-=dt
	if env_t>0: return
	env_t=1.0
	var h:=fmod(hud_min/60.0,24.0)
	var sc:Color; var se:float; var am:Color; var ae:float; var fog:Color
	if h>=6 and h<11: sc=Color(1,0.9,0.72); se=0.7; am=Color(0.86,0.9,1); ae=0.55; fog=Color(0.88,0.93,1)
	elif h>=11 and h<16: sc=Color(1,0.98,0.92); se=0.8; am=Color(0.9,0.94,1); ae=0.6; fog=Color(0.86,0.93,1)
	elif h>=16 and h<19.5: sc=Color(1,0.62,0.38); se=0.75; am=Color(1,0.78,0.72); ae=0.5; fog=Color(1,0.82,0.7)
	else: sc=Color(0.5,0.55,0.95); se=0.35; am=Color(0.5,0.55,0.85); ae=0.42; fog=Color(0.35,0.4,0.6)
	var dday:=int(hud_min/1440.0)
	var rainy:bool=(dday%5==2 and h>=13.0 and h<19.0 and int(dday/7)%4!=3) or ('rain' in OS.get_cmdline_user_args())
	if rain==null:
		rain=CPUParticles3D.new(); rain.amount=260; rain.lifetime=0.8; rain.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX; rain.emission_box_extents=Vector3(12,0.5,12)
		rain.direction=Vector3(0.1,-1,0); rain.spread=2.0; rain.initial_velocity_min=16.0; rain.initial_velocity_max=19.0; rain.gravity=Vector3(0,-6,0)
		var qm:=QuadMesh.new(); qm.size=Vector2(0.02,0.55); var rm:=StandardMaterial3D.new(); rm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; rm.albedo_color=Color(0.85,0.92,1.0,0.55); rm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; rm.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES; rm.disable_fog=true
		qm.material=rm; rain.mesh=qm; rain.local_coords=false; rain.emitting=false; add_child(rain)
	if rainy and not rain_on and mode=='play' and in_room=='': player_say('بدأت تمطر... الجو حلو النهاردة')
	rain.emitting=rainy; rain_on=rainy
	if rainy: sc=sc.darkened(0.25); am=am.darkened(0.15)
	var day:=int(hud_min/1440.0); var si:=int(day/7)%4
	var tint:Color=[Color(1,0.97,1),Color(1,1,0.94),Color(1,0.93,0.86),Color(0.92,0.96,1.04)][si]
	var tw:=create_tween().set_parallel(true)
	tw.tween_property(sun,"light_color",sc*tint,1.0); tw.tween_property(sun,"light_energy",se,1.0)
	var bgm:float=0.95 if (h>=6 and h<16) else (0.7 if (h>=16 and h<19.5) else 0.16)
	tw.tween_property(env,"background_energy_multiplier",bgm,1.0)
	RenderingServer.global_shader_parameter_set('night',1.0 if bgm<0.3 else (0.5 if bgm<0.8 else 0.0))
	tw.tween_property(env,"ambient_light_color",am*tint,1.0); tw.tween_property(env,"ambient_light_energy",ae,1.0); tw.tween_property(env,"fog_light_color",fog,1.0)
	if si!=season_i:
		season_i=si; RenderingServer.global_shader_parameter_set('snow',1.0 if si==3 else 0.0)
		var pc:Color=[Color(1,0.78,0.88),Color(0.8,1,0.7),Color(1,0.62,0.25),Color(1,1,1)][si]
		(petals.mesh.material as StandardMaterial3D).albedo_color=pc
		var tc:Color=[Color(1,0.78,0.88),Color(0.5,0.85,0.42),Color(1,0.55,0.2),Color(0.96,0.98,1.0)][si]
		if tree_mat: (tree_mat as ShaderMaterial).set_shader_parameter("accent",Vector3(tc.r,tc.g,tc.b))
