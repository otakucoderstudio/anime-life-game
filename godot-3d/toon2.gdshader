shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 shade_color : source_color = vec4(0.62,0.5,0.8,1.0);
uniform float bands = 2.0;
uniform float rim = 0.35;
uniform float scissor = 0.0;
uniform float lift = 1.06;
void fragment(){
	vec4 t = texture(tex, UV);
	if(scissor > 0.0 && t.a < scissor) discard;
	ALBEDO = t.rgb * tint.rgb * lift;
	float fr = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	EMISSION = vec3(1.0,0.92,0.85) * fr * rim * 0.5;
}
void light(){
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float s = smoothstep(0.42, 0.50, d);
	float s2 = smoothstep(0.62, 0.70, d);
	vec3 shade = ALBEDO * shade_color.rgb;
	vec3 mid = mix(shade, ALBEDO, s);
	vec3 c = mix(mid, ALBEDO * 1.12, s2 * 0.6);
	DIFFUSE_LIGHT += c * LIGHT_COLOR / PI * ATTENUATION;
}
