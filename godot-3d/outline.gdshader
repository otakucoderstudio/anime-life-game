shader_type spatial;
render_mode cull_front, unshaded;
uniform float thickness = 0.03;
void vertex(){ VERTEX += NORMAL * thickness; }
void fragment(){ ALBEDO = vec3(0.12,0.08,0.18); }
