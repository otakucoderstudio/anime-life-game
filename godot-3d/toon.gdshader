shader_type spatial;
render_mode cull_back;
uniform vec4 albedo : source_color = vec4(1.0);
global uniform float snow;
uniform float bands = 3.0;
varying float up;
void vertex(){ up = normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz).y; }
uniform vec4 shade_color : source_color = vec4(0.52,0.42,0.74,1.0);
void fragment(){ ALBEDO = mix(albedo.rgb, vec3(0.95,0.97,1.0), snow*smoothstep(0.6,0.85,up)*0.6); }
void light(){
	float d = clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	float s = floor(d * bands + 0.3) / bands;
	s = smoothstep(0.30, 0.36, s);
	vec3 c = mix(ALBEDO * shade_color.rgb, ALBEDO, s);
	DIFFUSE_LIGHT += c * LIGHT_COLOR / PI * ATTENUATION;
}
