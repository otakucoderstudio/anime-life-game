shader_type spatial;
render_mode cull_back;
uniform vec3 p_skin : source_color = vec3(1.0,0.88,0.8);
uniform vec3 p_hair : source_color = vec3(0.3,0.2,0.5);
uniform vec3 p_top : source_color = vec3(0.17,0.3,0.6);
uniform vec3 p_bot : source_color = vec3(0.17,0.3,0.6);
uniform vec3 p_acc : source_color = vec3(1.0,0.35,0.5);
uniform vec3 p_iris : source_color = vec3(0.2,0.45,0.7);
uniform vec4 shade_color : source_color = vec4(0.52,0.42,0.74,1.0);
varying float reg;
varying float rimv;
void vertex(){ reg = floor(COLOR.r*16.0+0.5); }
void fragment(){
	int r = int(reg+0.5);
	vec3 c = p_skin;
	if(r==1) c=p_hair;
	else if(r==2) c=p_top;
	else if(r==3) c=p_bot;
	else if(r==4) c=p_acc;
	else if(r==5) c=vec3(0.97,0.97,1.0);
	else if(r==6) c=p_iris;
	else if(r==7) c=vec3(0.1,0.05,0.07);
	else if(r==8) c=mix(p_skin,vec3(1.0,0.45,0.5),0.55);
	else if(r==9) c=mix(p_hair,vec3(1.0),0.28);
	else if(r==10) c=vec3(0.28,0.16,0.14);
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	if(r==1 || r==9){
		float ring = smoothstep(0.10,0.0,abs(NORMAL.y-0.42)) * 0.55;
		c = mix(c, mix(c,vec3(1.0),0.65), ring);
		c *= 0.92 + 0.08*NORMAL.y;
	}
	if(r==0 || r==8) c = mix(c, vec3(1.0,0.78,0.72), pow(1.0-ndv,2.5)*0.35);
	ALBEDO = c;
	EMISSION = c * pow(1.0-ndv,3.0) * 0.28;
}
void light(){
	float d = clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	float s = smoothstep(0.36, 0.42, d);
	float s2 = smoothstep(0.14, 0.20, d);
	vec3 deep = ALBEDO * shade_color.rgb * vec3(0.78,0.74,0.9);
	vec3 c = mix(deep, ALBEDO * shade_color.rgb, s2);
	c = mix(c, ALBEDO, s);
	DIFFUSE_LIGHT += c * LIGHT_COLOR / PI * ATTENUATION;
}
