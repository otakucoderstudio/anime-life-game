import bpy, bmesh, math, sys
from mathutils import Vector
def clear():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete()
objs=[]
def ell(region,loc,rad,rot=(0,0,0),seg=12,rings=7,tag='body'):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,radius=1,location=loc)
    o=bpy.context.object; o.scale=rad; o.rotation_euler=[math.radians(a) for a in rot]
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.ops.object.shade_smooth()
    o['tag']=tag; paint(o,region); objs.append(o); return o
def cone(region,loc,r,h,rot=(0,0,0),seg=8,tag='body',r2=0.0):
    bpy.ops.mesh.primitive_cone_add(vertices=seg,radius1=r,radius2=r2,depth=h,location=loc)
    o=bpy.context.object; o.rotation_euler=[math.radians(a) for a in rot]
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.ops.object.shade_smooth(); o['tag']=tag; paint(o,region); objs.append(o); return o
def paint(o,region):
    me=o.data; ca=me.color_attributes.new("Col",'FLOAT_COLOR','POINT')
    for d in ca.data: d.color=(region/16.0,0,0,1)
SK,HA,TOP,BOT,ACC,WH,IRIS,DK,PINK,HL,SHOE=range(11)
def taper_chin(o,z0,k):
    me=o.data
    for v in me.vertices:
        if v.co.z<z0:
            t=min(1,(z0-v.co.z)/0.35); f=1-k*t
            v.co.x*=f; v.co.y*= (1-0.5*k*t)
def face(z=2.05,spiky=False,girl=True):
    for sx in(-1,1):
        ex=sx*0.135
        ell(WH,(ex,-0.282,z-0.0),(0.088,0.04,0.11),(0,0,sx*-6),10,6)
        ell(IRIS,(ex,-0.312,z-0.012),(0.062,0.022,0.088),(0,0,0),10,6)
        ell(DK,(ex,-0.326,z-0.014),(0.032,0.012,0.052),(0,0,0),8,5)
        ell(WH,(ex+0.022*sx*-1+0.0,-0.336,z+0.03),(0.02,0.01,0.024),(0,0,0),6,4)
        ell(DK,(ex,-0.305,z+0.098),(0.108,0.03,0.02),(0,0,sx*-14),8,5)
        ell(DK,(ex+sx*0.005,-0.283,z+0.19),(0.075,0.022,0.014),(0,0,sx*-10),8,5)
        ell(PINK,(sx*0.215,-0.255,z-0.11),(0.06,0.02,0.032),(0,0,0),8,5)
    ell(SK,(0,-0.325,z-0.095),(0.02,0.018,0.016),(0,0,0),6,4)
    ell(PINK,(0,-0.312,z-0.19),(0.028,0.01,0.007),(0,0,0),8,4)
def build(kind):
    clear(); objs.clear()
    girl=kind.startswith('girl'); H=2.05 if girl else 2.15
    # head
    h=ell(SK,(0,0,H),(0.33,0.31,0.35),seg=18,rings=11); taper_chin(h,H-0.05,0.28)
    ell(SK,(0,0.0,H-0.4),(0.075,0.075,0.12),seg=8,rings=5)
    face(H,girl=girl)
    # hair base
    ell(HA,(0,0.05,H+0.06),(0.385,0.37,0.37),seg=16,rings=10)
    ell(HA,(0,-0.07,H+0.2),(0.37,0.3,0.2),seg=14,rings=8)
    for i,x in enumerate((-0.27,-0.14,0,0.14,0.27)):
        ell(HA,(x,-0.275,H+0.19-abs(x)*0.18),(0.085,0.05,0.16),(0,0,x*-60),8,6)
    for sx in(-1,1):
        ell(HA,(sx*0.325,-0.12,H-0.1),(0.05,0.07,0.24),(0,0,sx*-6),8,6)
        ell(HL,(sx*0.1,-0.34,H+0.27),(0.07,0.012,0.045),(0,0,sx*-25),6,4)
    ell(HL,(0.0,-0.02,H+0.52),(0.2,0.12,0.02),(0,0,0),8,4)
    if kind=='girl_long':
        ell(HA,(0,0.2,H-0.55),(0.3,0.14,0.62),seg=12,rings=8)
        ell(HA,(0,0.22,H-1.0),(0.2,0.1,0.35),seg=10,rings=6)
    if kind=='girl_bob':
        ell(HA,(0,0.1,H-0.2),(0.4,0.34,0.26),seg=14,rings=8)
        ell(ACC,(0.28,-0.18,H+0.28),(0.05,0.04,0.05),seg=8,rings=5)
    if kind=='boy_spiky':
        for k in range(7):
            a=-1.25+k*(2.5/6)
            import math as m
            cone(HA,(m.sin(a)*0.22,0.02-m.cos(a)*0.05,H+0.4),0.1,0.4,(-12,0,-a*55),8)
        cone(HA,(0.0,-0.2,H+0.42),0.08,0.3,(-35,0,0),8)
        cone(HA,(-0.12,-0.22,H+0.38),0.07,0.26,(-30,0,20),8)
    if kind=='boy_soft':
        for k in range(5):
            x=-0.26+k*0.13
            cone(HA,(x,-0.22,H+0.3),0.075,0.24,(-70,0,-x*60),8)
        ell(HA,(0,0.1,H-0.05),(0.4,0.36,0.34),seg=14,rings=8)
    # torso
    zt=1.38
    if girl:
        ell(WH,(0,0,zt),(0.22,0.14,0.3),seg=12,rings=8)
        ell(TOP,(0,-0.02,zt+0.24),(0.26,0.17,0.09),seg=12,rings=6)
        ell(ACC,(0,-0.17,zt+0.15),(0.08,0.03,0.05),(0,0,0),8,5)
        ell(ACC,(-0.07,-0.17,zt+0.15),(0.06,0.03,0.04),(0,0,25),6,4); ell(ACC,(0.07,-0.17,zt+0.15),(0.06,0.03,0.04),(0,0,-25),6,4)
        cone(BOT,(0,0,0.98),0.44,0.4,seg=20,r2=0.2)
    else:
        ell(TOP,(0,0,zt+0.05),(0.3,0.19,0.4),seg=14,rings=9)
        ell(WH,(0,-0.14,zt+0.28),(0.075,0.05,0.2),(0,0,0),8,6)
        ell(ACC,(0,-0.18,zt+0.2),(0.04,0.03,0.2),(0,0,0),8,6)
        ell(BOT,(0,0,0.95),(0.27,0.17,0.15),seg=12,rings=6)
    pieces={'body':[o for o in objs]}
    # limbs
    def limb(name,joint,sx,isarm):
        start=len(objs)
        jx,jy,jz=joint
        if isarm:
            sl=WH if girl else TOP
            ell(sl,(jx,jy,jz-0.17),(0.065,0.065,0.22),seg=10,rings=6)
            ell(sl,(jx,jy,jz-0.5),(0.055,0.055,0.2),seg=10,rings=6)
            ell(SK,(jx,jy,jz-0.72),(0.058,0.05,0.07),seg=8,rings=5)
        else:
            lc=SK if girl else BOT
            ell(lc,(jx,jy,jz-0.25),(0.09,0.09,0.3),seg=10,rings=6)
            ell(lc,(jx,jy,jz-0.66),(0.073,0.073,0.3),seg=10,rings=6)
            if girl: ell(WH,(jx,jy,jz-0.72),(0.082,0.082,0.22),seg=10,rings=6)
            ell(SHOE,(jx,jy-0.045,0.07),(0.095,0.16,0.075),seg=10,rings=6)
        new=objs[start:]
        pieces[name]=new
    limb('legl',(-0.13,0,0.9),-1,False); limb('legr',(0.13,0,0.9),1,False)
    limb('arml',(-0.31 if girl else -0.4,0,1.56 if girl else 1.7),-1,True)
    limb('armr',(0.31 if girl else 0.4,0,1.56 if girl else 1.7),1,True)
    # body pieces = everything before limbs
    nb=len(pieces['body'])
    allp={}
    bodyobjs=objs[:len(objs)]
    # recompute body as those not in limbs
    limbset=set()
    for n in('legl','legr','arml','armr'):
        for o in pieces[n]: limbset.add(o)
    pieces['body']=[o for o in objs if o not in limbset]
    joints={'legl':(-0.13,0,0.9),'legr':(0.13,0,0.9),'body':(0,0,0),
            'arml':(-0.31 if girl else -0.4,0,1.56 if girl else 1.7),'armr':(0.31 if girl else 0.4,0,1.56 if girl else 1.7)}
    final=[]
    for n,lst in pieces.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in lst: o.select_set(True)
        bpy.context.view_layer.objects.active=lst[0]
        bpy.ops.object.join(); o=bpy.context.object; o.name=n
        bpy.context.scene.cursor.location=joints[n]
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR'); final.append(o)
    return final
def cat():
    clear(); objs.clear()
    ell(SK,(0,0,0.22),(0.2,0.3,0.2),seg=14,rings=8)
    ell(SK,(0,-0.28,0.45),(0.2,0.18,0.17),seg=14,rings=8)
    ell(WH,(0,-0.3,0.34),(0.13,0.1,0.09),seg=10,rings=6)
    for sx in(-1,1):
        cone(SK,(sx*0.11,-0.26,0.65),0.075,0.15,(0,0,sx*-14),6)
        cone(PINK,(sx*0.11,-0.285,0.65),0.045,0.1,(0,0,sx*-14),6)
        ell(IRIS,(sx*0.075,-0.43,0.48),(0.04,0.02,0.055),seg=8,rings=5)
        ell(DK,(sx*0.075,-0.447,0.48),(0.02,0.01,0.035),seg=6,rings=4)
        ell(WH,(sx*0.07,-0.452,0.5),(0.01,0.006,0.012),seg=4,rings=3)
        ell(SK,(sx*0.09,-0.16,0.06),(0.07,0.1,0.06),seg=8,rings=5)
        ell(WH,(sx*0.09,-0.2,0.04),(0.06,0.08,0.04),seg=8,rings=5)
    ell(PINK,(0,-0.455,0.4),(0.02,0.012,0.014),seg=6,rings=4)
    ell(HA,(0,-0.46,0.52),(0.1,0.03,0.045),seg=8,rings=5)
    ell(SK,(0,0.35,0.35),(0.06,0.06,0.28),(-40,0,0),8,6)
    ell(HA,(0,0.5,0.5),(0.055,0.055,0.12),(-70,0,0),8,5)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]; bpy.ops.object.join(); bpy.context.object.name='body'
    return [bpy.context.object]
kind=sys.argv[-1]
fin=cat() if kind=='cat' else build(kind)
bpy.ops.object.select_all(action='SELECT')
out='/home/sandbox/gp/chars/%s.glb'%kind
import os; out=os.path.expanduser('~/gp/chars/%s.glb'%kind)
try:
    bpy.ops.export_scene.gltf(filepath=out,export_format='GLB',export_vertex_color='ACTIVE',export_materials='NONE',use_selection=True)
except TypeError:
    bpy.ops.export_scene.gltf(filepath=out,export_format='GLB',export_materials='NONE',use_selection=True)
print('TRIS',sum(len(o.data.polygons)*2 for o in fin), out)
