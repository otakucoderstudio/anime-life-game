shader_type spatial;
render_mode cull_back;
uniform vec4 albedo : source_color = vec4(1.0);
uniform float bands = 3.0;
uniform vec4 shade_color : source_color = vec4(0.52,0.42,0.74,1.0);
void fragment(){ ALBEDO = albedo.rgb; }
void light(){
	float d = clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	float s = floor(d * bands + 0.3) / bands;
	s = smoothstep(0.30, 0.36, s);
	vec3 c = mix(ALBEDO * shade_color.rgb, ALBEDO, s);
	DIFFUSE_LIGHT += c * LIGHT_COLOR / PI * ATTENUATION;
}
