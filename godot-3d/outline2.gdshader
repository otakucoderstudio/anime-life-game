shader_type spatial;
render_mode cull_front, unshaded;
uniform float thickness = 0.01;
uniform vec4 line_color : source_color = vec4(0.16,0.09,0.1,1.0);
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float scissor = 0.0;
void vertex(){ VERTEX += NORMAL * thickness; }
void fragment(){
	if(scissor > 0.0 && texture(tex, UV).a < scissor) discard;
	ALBEDO = line_color.rgb;
}
