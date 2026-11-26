shader_type spatial;
render_mode cull_back;
uniform vec3 tint : source_color = vec3(1.0);
uniform vec3 accent : source_color = vec3(1.0);
global uniform float snow;
global uniform float night;
uniform float glow = 0.0;
uniform float bands = 3.0;
varying float up;
varying vec3 wp;
void vertex(){ up = normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz).y; wp = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
uniform vec4 shade_color : source_color = vec4(0.52,0.42,0.74,1.0);
void fragment(){
	vec3 c = COLOR.rgb;
	if(COLOR.a < 0.25){ c *= tint;
		float hl = smoothstep(0.0,0.06,abs(fract(wp.y/1.1)-0.5)*2.0-0.9)*0.0;
		float line = step(0.94,fract(wp.y/1.1));
		float cell = step(0.97,fract((wp.x+wp.z)/1.6));
		float n = fract(sin(dot(floor(vec2((wp.x+wp.z)/0.55,wp.y/0.37)),vec2(12.9898,78.233)))*43758.5453);
		c *= 1.0 - line*0.10 - cell*0.05 - n*0.045*(1.0-up*up); }
	else if(COLOR.a < 0.75){ c *= accent; EMISSION = c*night*0.9*glow; }
	c = mix(c, vec3(0.95,0.97,1.0), snow*smoothstep(0.6,0.85,up)*0.9);
	ALBEDO = c;
}
void light(){
	float d = clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	float s = smoothstep(0.34, 0.40, d);
	vec3 c = mix(ALBEDO * shade_color.rgb, ALBEDO, s);
	DIFFUSE_LIGHT += c * LIGHT_COLOR / PI * ATTENUATION;
}
