shader_type spatial;
render_mode diffuse_burley;

uniform vec2 route_points[10];
uniform int route_count = 10;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D paving_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D masonry_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D water_tex : source_color, filter_linear_mipmap, repeat_enable;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	world_normal=(MODEL_MATRIX*vec4(NORMAL,0.0)).xyz;
}

float segment_distance(vec2 p,vec2 a,vec2 b) {
	vec2 ab=b-a;
	return length(p-a-ab*clamp(dot(p-a,ab)/max(dot(ab,ab),0.001),0.0,1.0));
}

float river_bank(float z) {
	return 10.0+sin((z+10.0)*0.13)*5.0+sin((z-4.0)*0.045)*2.0;
}

void fragment() {
	vec2 p=world_pos.xz;
	float distance_to_route=1000.0;
	for(int i=0;i<9;i++) {
		if(i<route_count-1) distance_to_route=min(distance_to_route,segment_distance(p,route_points[i],route_points[i+1]));
	}
	// The material envelope extends one camera crop beyond ACT 2 so a gameplay
	// frame never exposes the unfinished neighboring graybox at its top edge.
	float act_two=smoothstep(-38.0,-34.0,p.y)*(1.0-smoothstep(23.0,27.0,p.y));
	float path=1.0-smoothstep(3.0,6.0,distance_to_route+sin(p.x*0.57)*sin(p.y*0.43)*0.28);
	float center=1.0-smoothstep(1.35,2.35,distance_to_route);
	vec3 grass_detail=texture(grass_tex,p/9.5).rgb*vec3(0.66,0.70,0.62);
	vec3 dirt_detail=texture(dirt_tex,p/9.0).rgb*vec3(0.68,0.62,0.50);
	vec3 paving_detail=texture(paving_tex,p/8.0).rgb*vec3(0.66,0.65,0.56);
	vec3 grass_color=mix(vec3(0.27,0.39,0.27),grass_detail,0.44);
	vec3 dirt_color=mix(vec3(0.48,0.40,0.25),dirt_detail,0.46);
	vec3 paving_color=mix(vec3(0.46,0.45,0.36),paving_detail,0.38);
	vec3 painted=mix(grass_color,dirt_color,path*0.88);
	painted=mix(painted,paving_color,center*0.32);
	float bank_distance=river_bank(p.y)-p.x;
	// Water is only the flat -1.55 surface. The transition wall must read as bank,
	// otherwise the water texture stretches down the cliff triangles.
	float water_mask=1.0-smoothstep(-1.49,-1.28,world_pos.y);
	vec2 flow=p/14.0+vec2(sin(p.y*0.22+TIME*0.38)*0.006,TIME*0.008);
	vec3 river=texture(water_tex,flow).rgb*vec3(0.42,0.61,0.60);
	river=mix(river,vec3(0.07,0.25,0.27),0.38);
	painted=mix(painted,river,water_mask);
	float steep=1.0-smoothstep(0.28,0.72,abs(normalize(world_normal).y));
	vec2 wall_uv=abs(world_normal.x)>abs(world_normal.z) ? vec2(p.y,world_pos.y)/4.0 : vec2(p.x,world_pos.y)/4.0;
	vec3 masonry=texture(masonry_tex,wall_uv).rgb*vec3(0.57,0.60,0.52);
	painted=mix(painted,masonry,steep*(1.0-water_mask));
	ALBEDO=mix(COLOR.rgb,painted,act_two);
	ROUGHNESS=mix(0.98,0.58,water_mask*act_two);
	SPECULAR=0.12;
}
