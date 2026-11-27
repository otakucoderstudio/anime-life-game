extends SceneTree
func _init():
	var n:Node=(load('res://models/fumi.glb') as PackedScene).instantiate()
	for mi in n.find_children('*','MeshInstance3D',true,false):
		for i in mi.mesh.get_surface_count():
			var m:BaseMaterial3D=mi.mesh.surface_get_material(i)
			var t=m.albedo_texture
			var px=''
			if t: var im=t.get_image(); px=str(im.get_pixel(im.get_width()/2,im.get_height()/2))+' '+str(im.get_size())
			print('M ',m.resource_name.right(14),' col=',m.albedo_color,' tex=',t!=null,' ',px,' metal=',m.metallic,' emis=',m.emission_enabled)
	quit()
