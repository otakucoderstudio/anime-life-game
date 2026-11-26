shader_type spatial;
render_mode cull_front, unshaded;
uniform float thickness = 0.03;
void vertex(){ VERTEX += NORMAL * thickness; }
void fragment(){ ALBEDO = vec3(0.2,0.11,0.1); }
