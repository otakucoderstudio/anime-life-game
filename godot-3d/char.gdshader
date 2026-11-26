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
	ALBEDO = c;
}
void light(){
	float d = clamp(dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.0, 1.0);
	float s = smoothstep(0.34, 0.40, d);
	vec3 c = mix(ALBEDO * shade_color.rgb, ALBEDO, s);
	DIFFUSE_LIGHT += c * LIGHT_COLOR / PI * ATTENUATION;
}
