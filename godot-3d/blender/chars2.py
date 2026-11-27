# Heroine v2: lofted anime-proportion body. Run: blender -b -P chars2.py -- girl_sakura
import bpy, bmesh, math, sys, os
src=open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'chars.py')).read()
exec(src[:src.index('def build(')])
def loft(region,rings,seg=20,arc=None,cap_top=False,cap_bot=False,pleat=0.0,npl=0,tag='body'):
    if rings[0][0]>rings[-1][0]:
        rings=rings[::-1]; cap_top,cap_bot=cap_bot,cap_top
    me=bpy.data.meshes.new('l'); verts=[]; faces=[]
    full = arc is None
    a0,a1=(0,360) if full else arc
    n=seg if full else seg+1
    for (z,rx,ry,cx,cy) in rings:
        for i in range(n):
            t=math.radians(a0+(a1-a0)*i/seg)
            k=1+pleat*math.cos(npl*t) if npl else 1
            verts.append((cx+rx*k*math.cos(t),cy+ry*k*math.sin(t),z))
    R=len(rings)
    for j in range(R-1):
        for i in range(n if full else n-1):
            i2=(i+1)%n
            faces.append((j*n+i,j*n+i2,(j+1)*n+i2,(j+1)*n+i))
    if cap_top:
        z,rx,ry,cx,cy=rings[-1]; verts.append((cx,cy,z)); c=len(verts)-1
        for i in range(n if full else n-1): faces.append(((R-1)*n+i,(R-1)*n+(i+1)%n,c)) if False else faces.append(((R-1)*n+(i+1)%n,(R-1)*n+i,c)) if False else faces.append(((R-1)*n+i,c,(R-1)*n+(i+1)%n)) if False else faces.append(((R-1)*n+i,(R-1)*n+(i+1)%n,c))
    if cap_bot:
        z,rx,ry,cx,cy=rings[0]; verts.append((cx,cy,z)); c=len(verts)-1
        for i in range(n if full else n-1): faces.append((i,c,(i+1)%n))
    me.from_pydata(verts,[],faces); me.update()
    o=bpy.data.objects.new('l',me); bpy.context.collection.objects.link(o)
    bpy.context.view_layer.objects.active=o
    for p in me.polygons: p.use_smooth=True
    o['tag']=tag; paint(o,region); objs.append(o); return o
def strand(region,p0,p1,w,seg=8):
    # tapered flat card from p0 (root) to p1 (tip)
    import mathutils
    a=mathutils.Vector(p0); b=mathutils.Vector(p1); d=b-a; L=d.length
    o=cone(region,tuple((a+b)/2),w,L,seg=seg,r2=0.0)
    # cone axis is z, apex up; rotate so apex at root(a): axis from tip->root
    bpy.ops.object.select_all(action="DESELECT"); o.select_set(True)
    up=mathutils.Vector((0,0,1)); axis=(b-a).normalized()
    q=up.rotation_difference(axis); o.rotation_euler=q.to_euler()
    bpy.context.view_layer.objects.active=o; o.select_set(True)
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=False)
    for v in o.data.vertices: v.co.y*=0.45 if False else 1
    return o
def build2(kind):
    clear(); objs.clear()
    H=2.05; S=0.72; Hn=2.27
    # ---- head (unscaled frame) ----
    h=ell(SK,(0,0,H),(0.33,0.31,0.35),seg=24,rings=14); taper_chin(h,H-0.02,0.34)
    face(H,girl=True)
    # hair: back/side shell (bob) + cap + bangs + side locks
    loft(HA,[(H-0.46,0.33,0.31,0,0.05),(H-0.36,0.395,0.37,0,0.06),(H-0.15,0.42,0.39,0,0.06),(H+0.06,0.41,0.385,0,0.06),(H+0.22,0.36,0.34,0,0.05),(H+0.34,0.27,0.25,0,0.04),(H+0.40,0.12,0.11,0,0.03)],seg=24,arc=(-40,220),cap_top=False)
    ell(HA,(0,0.02,H+0.2),(0.375,0.35,0.25),seg=22,rings=12)
    bx=[-0.32,-0.24,-0.16,-0.08,0.0,0.08,0.16,0.24,0.32]
    for x in bx:
        L=0.36-abs(x)*0.35
        strand(HA,(x*0.7,-0.26,H+0.44),(x*1.0,-0.375+abs(x)*0.18,H+0.44-L-0.12),0.075)
    for sx in(-1,1):
        strand(HA,(sx*0.30,-0.13,H+0.28),(sx*0.335,-0.27,H-0.30),0.085)
        strand(HA,(sx*0.31,-0.02,H+0.2),(sx*0.37,-0.12,H-0.40),0.075)
    ell(ACC,(0.27,-0.2,H+0.3),(0.05,0.03,0.04),(0,0,25),8,5)  # hair clip
    ell(ACC,(0.31,-0.2,H+0.3),(0.05,0.03,0.04),(0,0,-25),8,5)
    for o in objs:
        for v in o.data.vertices:
            v.co.x*=S; v.co.y*=S; v.co.z=(v.co.z-H)*S+Hn
    head_n=len(objs)
    # ---- neck + torso ----
    loft(SK,[(2.0,0.075,0.075,0,0.0),(2.12,0.07,0.07,0,0.0)],seg=14)
    # shirt+blazer torso, lofted slim waist
    loft(TOP,[(1.12,0.185,0.125,0,0),(1.3,0.155,0.105,0,0),(1.5,0.185,0.125,0,0),(1.68,0.23,0.14,0,0),(1.83,0.235,0.135,0,0),(1.93,0.14,0.1,0,0.0),(1.99,0.085,0.085,0,0)],seg=22,cap_bot=True)
    # shirt V and collar
    ell(WH,(0,-0.1,1.86),(0.085,0.05,0.12),(0,0,0),10,6)
    for sx in(-1,1): ell(WH,(sx*0.06,-0.1,1.97),(0.06,0.035,0.035),(0,sx*0,sx*-30),8,5)
    ell(ACC,(0,-0.135,1.82),(0.05,0.03,0.04),(0,0,0),8,5)
    ell(ACC,(-0.06,-0.135,1.79),(0.055,0.028,0.034),(0,0,28),8,5); ell(ACC,(0.06,-0.135,1.79),(0.055,0.028,0.034),(0,0,-28),8,5)
    ell(ACC,(-0.025,-0.138,1.7),(0.025,0.02,0.07),(0,0,8),6,4); ell(ACC,(0.025,-0.138,1.7),(0.025,0.02,0.07),(0,0,-8),6,4)
    # skirt: pleated flare
    loft(BOT,[(0.72,0.34,0.26,0,0),(0.9,0.31,0.23,0,0),(1.05,0.225,0.16,0,0),(1.15,0.19,0.13,0,0)],seg=32,pleat=0.07,npl=12,cap_top=True)
    pieces={'body':list(objs)}
    jt={'legl':(-0.1,0,1.0),'legr':(0.1,0,1.0),'arml':(-0.24,0,1.82),'armr':(0.24,0,1.82),'body':(0,0,0)}
    def limb(name):
        s=len(objs); jx,jy,jz=jt[name]
        if name.startswith('arm'):
            sx=-1 if name=='arml' else 1
            loft(TOP,[(jz+0.04,0.062,0.062,jx,jy),(jz-0.16,0.056,0.056,jx+sx*0.01,jy),(jz-0.42,0.048,0.048,jx+sx*0.03,jy)],seg=12,cap_top=True)
            loft(WH,[(jz-0.4,0.047,0.047,jx+sx*0.03,jy),(jz-0.46,0.043,0.043,jx+sx*0.03,jy)],seg=12)
            ell(SK,(jx+sx*0.035,jy,jz-0.53),(0.04,0.03,0.075),(0,0,0),10,6)
        else:
            loft(SK,[(jz,0.092,0.092,jx,jy),(jz-0.2,0.08,0.08,jx,jy),(jz-0.4,0.058,0.058,jx,jy)],seg=14)
            loft(WH,[(jz-0.4,0.06,0.06,jx,jy),(jz-0.7,0.055,0.055,jx,jy),(jz-0.93,0.048,0.048,jx,jy)],seg=14,cap_top=True)
            ell(SHOE,(jx,jy-0.05,0.06),(0.075,0.14,0.06),seg=12,rings=7)
        pieces[name]=objs[s:]
    for n in('legl','legr','arml','armr'): limb(n)
    limbset=set(o for n in('legl','legr','arml','armr') for o in pieces[n])
    pieces['body']=[o for o in objs if o not in limbset]
    fin=[]
    for n,lst in pieces.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in lst: o.select_set(True)
        bpy.context.view_layer.objects.active=lst[0]
        bpy.ops.object.join(); o=bpy.context.object; o.name=n
        bpy.context.scene.cursor.location=jt[n]
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR'); fin.append(o)
    return fin
kind=sys.argv[-1]
fin=build2(kind)
bpy.ops.object.select_all(action='SELECT')
out=os.path.expanduser('~/gp/chars/%s.glb'%kind)
bpy.ops.export_scene.gltf(filepath=out,export_format='GLB',export_vertex_color='ACTIVE',export_materials='NONE',use_selection=True)
print('TRIS',sum(len(o.data.polygons)*2 for o in fin), out)
