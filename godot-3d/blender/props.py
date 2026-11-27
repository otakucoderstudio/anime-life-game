import bpy, math, sys, os, random
from mathutils import Vector
objs=[]
def lin(c): return tuple(x**2.2 for x in c)
def paint(o,col,a=1.0):
    ca=o.data.color_attributes.new("Col",'FLOAT_COLOR','POINT'); l=lin(col)
    for d in ca.data: d.color=(l[0],l[1],l[2],a)
WALL=0.0; ACC=0.5; FIX=1.0
def fin(o,col,a,smooth=True):
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    if smooth: bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40))
    paint(o,col,a); objs.append(o); return o
def bx(c,loc,dim,col=(1,1,1),a=FIX,bev=0.05,rot=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(location=loc); o=bpy.context.object
    o.scale=(dim[0]/2,dim[1]/2,dim[2]/2); o.rotation_euler=[math.radians(r) for r in rot]
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    if bev>0:
        m=o.modifiers.new('b','BEVEL'); m.width=min(bev,min(dim)/2.2); m.segments=1; m.limit_method='ANGLE'
        bpy.ops.object.modifier_apply(modifier='b')
    return fin(o,col,a,smooth=bev>0)
def cyl(loc,r,h,col,a=FIX,rot=(0,0,0),seg=14,r2=None):
    bpy.ops.mesh.primitive_cone_add(vertices=seg,radius1=r,radius2=r if r2 is None else r2,depth=h,location=loc,rotation=[math.radians(x) for x in rot])
    return fin(bpy.context.object,col,a)
def ell(loc,rad,col,a=FIX,seg=12,rings=8,rot=(0,0,0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,radius=1,location=loc,rotation=[math.radians(x) for x in rot])
    o=bpy.context.object; o.scale=rad; return fin(o,col,a)
def tor(loc,R,r,col,rot=(0,0,0),a=FIX):
    bpy.ops.mesh.primitive_torus_add(major_radius=R,minor_radius=r,major_segments=20,minor_segments=6,location=loc,rotation=[math.radians(x) for x in rot])
    return fin(bpy.context.object,col,a)
def done(name,path):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]; bpy.ops.object.join(); o=bpy.context.object; o.name=name
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True)
    try: bpy.ops.export_scene.gltf(filepath=path,export_format='GLB',export_vertex_color='ACTIVE',export_materials='NONE',use_selection=True)
    except TypeError: bpy.ops.export_scene.gltf(filepath=path,export_format='GLB',export_materials='NONE',use_selection=True)
    print('POLYS',name,len(o.data.polygons))
def clear():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(); objs.clear()
GL=(0.62,0.82,0.95); LIT=(1,0.93,0.62); FR=(0.88,0.88,0.93); DARK=(0.3,0.36,0.46)
def building(h,seed):
    clear(); rnd=random.Random(seed)
    # body: x in [-3.5,3.5] facade at +x
    bx(0,(0,0,h/2),(7,8.6,h) if False else (7,h and 8.6,h),WALL_C,WALL,bev=0.12) if False else None
    bpy.ops.mesh.primitive_cube_add(); o=bpy.context.object
    o.scale=(3.5,4.3,h/2); o.location=(0,0,h/2); bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    m=o.modifiers.new('b','BEVEL'); m.width=0.18; m.segments=3; m.limit_method='ANGLE'; bpy.ops.object.modifier_apply(modifier='b')
    fin(o,(1,1,1),WALL)
    bx(0,(0,0,h+0.2),(7.6,9.0,0.45),(0.7,0.7,0.7),WALL,bev=0.12)
    # ground-floor shop
    bx(0,(3.55,0,1.4),(0.2,5.6,2.6),(0.35,0.55,0.7),FIX,bev=0.04)
    bx(0,(3.58,0,1.4),(0.1,5.2,2.2),(0.85,0.95,1.0),FIX,bev=0.03)
    for k in (-1.3,1.3,0): bx(0,(3.63,k,1.4),(0.06,0.07,2.2),FR,FIX,bev=0.02)
    bx(0,(3.95,0,2.95),(0.9,6.2,0.5),(1,1,1),ACC,bev=0.12)
    # curved awning
    cyl((3.95,0,2.55),0.5,6.0,(1,1,1),FIX,rot=(90,0,0),seg=16,r2=0.5)
    objs[-1].scale=(1,1,1)
    bx(0,(4.0,0,2.6),(1.2,6.2,0.1),(1,1,1),FIX,bev=0.04)
    # upper floors
    nf=int((h-3.2)/2.6)
    for f in range(1,nf+1):
        y=3.6+(f-1)*2.6
        bx(0,(3.55,0,y-1.15),(0.15,8.7,0.3),(0.8,0.8,0.8),WALL,bev=0.0)
        for k in range(3):
            z=(k-1)*2.6; lit=rnd.random()<0.28
            bx(0,(3.58,z,y),(0.1,1.6,1.4),LIT if lit else GL,FIX,bev=0.0)
            bx(0,(3.75,z,y-0.78),(0.35,1.9,0.1),FR,FIX,bev=0.0)
        if (f+seed)%2==0:
            bx(0,(4.1,0,y-0.8),(1.2,5.6,0.1),(0.82,0.82,0.85),FIX,bev=0.03)
            bx(0,(4.65,0,y-0.4),(0.05,5.6,0.9),(0.4,0.45,0.5),FIX,bev=0.02)
            bx(0,(3.9,1.3,y-0.55),(0.7,0.7,0.55),(0.9,0.9,0.92),FIX,bev=0.08)
    # roof stuff
    cyl((-0.5,-1.5,h+1.1),0.8,1.4,(0.7,0.74,0.78),FIX,seg=16)
    cyl((-0.5,-1.5,h+1.95),0.9,0.3,(0.5,0.54,0.58),FIX,seg=16,r2=0.2)
    for k in range(3): bx(0,(2.0,k*1.7-1.7,h+0.7),(0.9,0.6,0.5),(0.8,0.82,0.85),FIX,bev=0.08)
    cyl((3.7,-3.8,h/2),0.05,h,(0.5,0.5,0.55),FIX,seg=8)
    done('b','%s/props/bld_%s.glb'%(os.path.expanduser('~/gp'),str(seed)))
def bike():
    clear()
    col=(1,1,1)
    for y in (-0.55,0.55):
        tor((0,y,0.36),0.31,0.035,(0.15,0.15,0.2),rot=(0,90,0)); cyl((0,y,0.36),0.03,0.04,(0.6,0.6,0.65),FIX,rot=(0,90,0),seg=8)
    cyl((0,0,0.68),0.025,1.1,col,ACC,rot=(90,0,0),seg=8)
    cyl((0,-0.2,0.6),0.025,0.65,col,ACC,rot=(60,0,0),seg=8)
    cyl((0,0.5,0.85),0.025,0.55,col,ACC,rot=(-15,0,0),seg=8)
    bx(0,(0,0.55,1.12),(0.45,0.05,0.05),(0.2,0.2,0.22),FIX,bev=0.02)
    bx(0,(0,-0.35,0.98),(0.2,0.34,0.07),(0.2,0.2,0.22),FIX,bev=0.03)
    bx(0,(0,0.62,0.95),(0.32,0.26,0.2),(0.75,0.75,0.8),FIX,bev=0.05)
    done('bike','%s/props/bike.glb'%os.path.expanduser('~/gp'))
def vending():
    clear()
    bx(0,(0,0,0.95),(0.95,0.85,1.9),(1,1,1),ACC,bev=0.1)
    bx(0,(0,-0.43,1.2),(0.72,0.05,1.0),(0.9,0.96,1),FIX,bev=0.03)
    cols=[(1,0.3,0.3),(0.3,0.7,1),(1,0.85,0.3),(0.4,0.85,0.5)]
    for r in range(3):
        for c in range(3): cyl((-0.22+c*0.22,-0.46,1.5-r*0.28),0.045,0.16,cols[(r+c)%4],FIX,seg=8)
    bx(0,(0.3,-0.43,0.75),(0.22,0.05,0.28),(0.2,0.2,0.25),FIX,bev=0.02)
    bx(0,(0,-0.43,0.28),(0.7,0.06,0.25),(0.15,0.15,0.18),FIX,bev=0.03)
    bx(0,(0,0.0,1.93),(0.9,0.8,0.1),(1,1,0.9),FIX,bev=0.04)
    done('vending','%s/props/vending.glb'%os.path.expanduser('~/gp'))
def pole():
    clear()
    cyl((0,0,4.5),0.16,9.0,(0.5,0.47,0.46),FIX,seg=10,r2=0.11)
    bx(0,(0,0,8.4),(0.14,2.2,0.14),(0.35,0.3,0.3),FIX,bev=0.03)
    bx(0,(0,0,7.6),(0.14,2.0,0.14),(0.35,0.3,0.3),FIX,bev=0.03)
    cyl((0.4,0,6.2),0.28,0.8,(0.5,0.55,0.5),FIX,seg=12)
    done('pole','%s/props/pole.glb'%os.path.expanduser('~/gp'))
def sakura(seed):
    clear(); rnd=random.Random(seed)
    trunk=(0.45,0.3,0.3)
    cyl((0,0,1.5),0.26,3.0,trunk,FIX,seg=10,r2=0.15)
    cyl((0,0,0.1),0.34,0.25,trunk,FIX,seg=10,r2=0.26)
    for ang in (30,150,270):
        a=math.radians(ang); cyl((math.cos(a)*0.35,math.sin(a)*0.35,3.3),0.07,1.3,trunk,FIX,rot=(math.degrees(math.sin(a))*0+ (35*math.sin(a)*-1 if False else 0),0,0),seg=6)
    pk=[(1,1,1),(0.95,0.94,0.97),(0.9,0.92,0.96),(1,0.97,0.96)]
    spots=[(0,0,4.4,1.4)]+[(math.cos(k*1.26+seed)*1.1,math.sin(k*1.26+seed)*1.1,3.7+(k%2)*0.6,0.95+rnd.random()*0.2) for k in range(5)]
    for i,(x,y,z,r) in enumerate(spots):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=r,location=(x,y,z)); o=bpy.context.object
        for v in o.data.vertices:
            n=1+0.14*math.sin(v.co.x*5+seed)*math.cos(v.co.y*4+v.co.z*3)
            v.co*=n
        fin(o,pk[(i+seed)%4],ACC)
    done('sakura','%s/props/sakura_%d.glb'%(os.path.expanduser('~/gp'),seed))

def bench():
    clear()
    W=(0.55,0.36,0.22)
    bx(0,(0,0,0.45),(1.5,0.5,0.08),W,FIX,bev=0.03)
    bx(0,(0,0.22,0.78),(1.5,0.08,0.45),W,FIX,bev=0.03)
    for x in (-0.65,0.65): bx(0,(x,0,0.22),(0.08,0.44,0.45),(0.25,0.25,0.3),FIX,bev=0.02)
    done('bench','%s/props/bench.glb'%os.path.expanduser('~/gp'))
def fountain():
    clear()
    ST=(0.82,0.82,0.86); WT=(0.55,0.8,0.95)
    cyl((0,0,0.25),2.2,0.5,ST,FIX,seg=24)
    cyl((0,0,0.52),1.95,0.1,WT,FIX,seg=24)
    cyl((0,0,0.9),0.35,0.8,ST,FIX,seg=16,r2=0.25)
    cyl((0,0,1.4),1.0,0.2,ST,FIX,seg=20,r2=0.8)
    cyl((0,0,1.52),0.85,0.05,WT,FIX,seg=20)
    cyl((0,0,1.9),0.12,0.8,ST,FIX,seg=10)
    ell((0,0,2.4),(0.28,0.28,0.35),WT,FIX,10,7)
    done('fountain','%s/props/fountain.glb'%os.path.expanduser('~/gp'))
def lamp():
    clear()
    cyl((0,0,1.7),0.07,3.4,(0.3,0.25,0.35),FIX,seg=8,r2=0.05)
    cyl((0,0,0.12),0.18,0.24,(0.3,0.25,0.35),FIX,seg=8)
    ell((0,0,3.5),(0.26,0.26,0.3),(1,0.93,0.65),FIX,10,7)
    cyl((0,0,3.8),0.3,0.1,(0.3,0.25,0.35),FIX,seg=10,r2=0.05)
    done('lamp','%s/props/lamp.glb'%os.path.expanduser('~/gp'))
def flowers():
    clear(); rnd=random.Random(5)
    bx(0,(0,0,0.15),(2.0,1.0,0.3),(0.5,0.35,0.25),FIX,bev=0.05)
    ell((0,0,0.35),(0.95,0.45,0.18),(0.4,0.7,0.35),FIX,10,6)
    for k in range(10):
        x=rnd.uniform(-0.8,0.8); y=rnd.uniform(-0.35,0.35)
        ell((x,y,0.5),(0.09,0.09,0.09),(1,1,1),ACC,6,4)
    done('flowers','%s/props/flowers.glb'%os.path.expanduser('~/gp'))

def car():
    clear()
    # kei car: front is -y. length 3.4, width 1.48, height 1.62
    bx(0,(0,0,0.62),(1.48,3.4,0.62),(1,1,1),ACC,bev=0.16)          # lower body
    bx(0,(0,-0.08,1.2),(1.38,2.35,0.78),(1,1,1),ACC,bev=0.2)        # cabin shell (body colour pillars)
    bx(0,(0,-0.08,1.62),(1.34,2.2,0.08),(1,1,1),ACC,bev=0.05)       # roof
    GLS=(0.55,0.78,0.92)
    bx(0,(0,-1.2,1.2),(1.26,0.06,0.62),GLS,FIX,bev=0.02,rot=(-24,0,0))   # windscreen
    bx(0,(0,1.02,1.2),(1.24,0.06,0.58),GLS,FIX,bev=0.02,rot=(18,0,0))    # rear glass
    for sx in (-1,1):
        bx(0,(sx*0.695,-0.08,1.2),(0.05,0.95,0.5),GLS,FIX,bev=0.02)       # side glass front
        bx(0,(sx*0.695,0.82,1.2),(0.05,0.5,0.5),GLS,FIX,bev=0.02)         # side glass rear
        bx(0,(sx*0.7,-0.08,0.98),(0.03,2.2,0.03),(0.2,0.22,0.28),FIX,bev=0)  # door line low
        bx(0,(sx*0.77,-0.68,1.02),(0.1,0.18,0.1),(0.2,0.22,0.28),FIX,bev=0.02)  # mirror
        for y in (-1.0,1.0):
            cyl((sx*0.63,y,0.34),0.34,0.05,(0.12,0.13,0.17),FIX,rot=(0,90,0),seg=14)  # arch shadow
            tor((sx*0.7,y,0.3),0.23,0.1,(0.08,0.08,0.1),rot=(0,90,0))
            cyl((sx*0.75,y,0.3),0.16,0.06,(0.82,0.83,0.88),FIX,rot=(0,90,0),seg=10)
            cyl((sx*0.78,y,0.3),0.05,0.04,(0.3,0.3,0.35),FIX,rot=(0,90,0),seg=6)
        ell((sx*0.46,-1.7,0.78),(0.2,0.05,0.14),(1,0.97,0.75),FIX,10,6)   # headlights
        ell((sx*0.5,1.7,0.82),(0.14,0.05,0.12),(0.95,0.15,0.15),FIX,10,6)  # tail lights
    bx(0,(0,-1.72,0.45),(1.3,0.1,0.18),(0.14,0.15,0.2),FIX,bev=0.04)       # front bumper
    bx(0,(0,1.72,0.45),(1.3,0.1,0.18),(0.14,0.15,0.2),FIX,bev=0.04)        # rear bumper
    bx(0,(0,-1.72,0.74),(0.5,0.06,0.1),(0.12,0.13,0.17),FIX,bev=0.02)      # grille
    bx(0,(0,1.76,0.62),(0.34,0.03,0.17),(1,1,0.95),FIX,bev=0.01)           # plate
    bx(0,(0,-0.08,1.67),(0.5,0.5,0.05),(0.9,0.9,0.95),FIX,bev=0.02)         # roof detail
    done('car','%s/props/car.glb'%os.path.expanduser('~/gp'))

which=sys.argv[-1]
if which=='b':
    for i,h in enumerate((7.0,9.2,11.4,13.6,15.8)): building(h,i)
elif which=='park':
    bench(); fountain(); lamp(); flowers()
elif which=='p':
    bike(); vending(); pole(); sakura(0); sakura(1); sakura(2)

elif which=='car':
    car()
