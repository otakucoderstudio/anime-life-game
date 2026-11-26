shader_type spatial;
render_mode cull_back;
uniform vec3 tint : source_color = vec3(1.0);
uniform vec3 accent : source_color = vec3(1.0);
global uniform float snow;
uniform float bands = 3.0;
varying float up;
void vertex(){ up = normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz).y; }
uniform vec4 shade_color : source_color = vec4(0.52,0.42,0.74,1.0);
void fragment(){
	vec3 c = COLOR.rgb;
	if(COLOR.a < 0.25) c *= tint;
	else if(COLOR.a < 0.75) c *= accent;
	c = mix(c, vec3(0.95,0.97,1.0), snow*smoothstep(0.6,0.85,up)*0.9);
	ALBEDO = c;
}
void light(){
	float d = clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	float s = smoothstep(0.34, 0.40, d);
	vec3 c = mix(ALBEDO * shade_color.rgb, ALBEDO, s);
	DIFFUSE_LIGHT += c * LIGHT_COLOR / PI * ATTENUATION;
}
