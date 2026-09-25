shader_type spatial;
uniform sampler2D ground_texture : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D stone_texture : source_color, repeat_enable, filter_linear_mipmap;
uniform vec2 main_points[4];
uniform vec2 trail_points[7];
uniform vec2 water_points[46];
uniform vec2 low_points[6];
uniform vec2 high_points[5];
uniform float drained = 0.0;
uniform vec2 flood_center;
uniform vec2 flood_radii;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
float segment_distance(vec2 p, vec2 a, vec2 b) {
 vec2 ab=b-a;
 return length(p-a-ab*clamp(dot(p-a,ab)/max(dot(ab,ab),0.0001),0.0,1.0));
}
float shore_hash(vec2 p) {
 return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
float shore_noise(vec2 p) {
 vec2 cell=floor(p), f=fract(p);
 f=f*f*(3.0-2.0*f);
 return mix(mix(shore_hash(cell),shore_hash(cell+vec2(1,0)),f.x),
            mix(shore_hash(cell+vec2(0,1)),shore_hash(cell+vec2(1,1)),f.x),f.y);
}
vec3 water_paint(vec2 p, float depth, float clock) {
 float bed=shore_noise(p*1.3)*0.65+shore_noise(p*3.1)*0.35;
 vec3 shallows=mix(vec3(0.17,0.205,0.145),vec3(0.26,0.265,0.18),bed);
 vec3 deep=mix(vec3(0.075,0.145,0.13),vec3(0.12,0.195,0.17),shore_noise(p*0.43));
 vec3 color=mix(shallows,deep,depth);
 // Broken low-contrast wavelets, with derivatives to avoid sub-pixel sparkling.
 float phase=p.y*4.2+p.x*1.6+shore_noise(p*0.8)*3.0-clock*1.15;
 float line=abs(sin(phase));
 float aa=max(fwidth(phase)*0.7,0.05);
 float wave=1.0-smoothstep(0.055,0.11+aa,line);
 float broken=smoothstep(0.42,0.68,shore_noise(p*1.8+vec2(0,clock*0.12)));
 color+=vec3(0.075,0.095,0.08)*wave*broken*(0.25+depth*0.55);
 return color;
}
void fragment() {
 vec2 p=world_position.xz;
 float road=1000.0;
 for(int i=0;i<3;i++) road=min(road,segment_distance(p,main_points[i],main_points[i+1])/1.8);
 for(int i=0;i<6;i++) road=min(road,segment_distance(p,trail_points[i],trail_points[i+1])/1.35);
 for(int i=0;i<5;i++) road=min(road,segment_distance(p,low_points[i],low_points[i+1])/2.0);
 for(int i=0;i<4;i++) road=min(road,segment_distance(p,high_points[i],high_points[i+1])/1.25);
 float water_squared=1000000.0;
 for(int i=0;i<45;i++) {
  vec2 a=water_points[i], ab=water_points[i+1]-a;
  vec2 offset=p-a-ab*clamp(dot(p-a,ab)/max(dot(ab,ab),0.0001),0.0,1.0);
  water_squared=min(water_squared,dot(offset,offset));
 }
 float water=sqrt(water_squared);
 vec3 soil=texture(ground_texture,p/10.0).rgb*vec3(0.67,0.73,0.64);
 float upper=smoothstep(38.0,44.0,-p.y);
 float wet=upper*smoothstep(20.0,36.0,p.x);
 soil=mix(soil,soil*vec3(1.25,0.88,0.67),upper*(1.0-wet)*0.55);
 soil=mix(soil,vec3(0.16,0.135,0.08),wet*0.65);
 float grain=sin(p.x*2.1+sin(p.y*1.5))*0.015;
 vec3 ground=mix(soil,vec3(0.30,0.25,0.16)+grain,(1.0-smoothstep(0.65,1.0,road))*0.75);
 // Keep water inside the shared 0.65 wet-footstep band. The uneven bank is static.
 float bank_noise=(shore_noise(p*1.6)-0.5)*0.11;
 float water_edge=water+bank_noise;
 float damp=1.0-smoothstep(0.55,1.12,water_edge);
 vec3 bank=mix(soil*vec3(0.69,0.67,0.52),vec3(0.23,0.205,0.13),shore_noise(p*2.2)*0.4);
 ground=mix(ground,bank,damp*0.82);
 float depth=1.0-smoothstep(0.08,0.51,water_edge);
 vec3 stream=water_paint(p,depth,TIME);
 ALBEDO=mix(ground,stream,1.0-smoothstep(0.35,0.59,water_edge));
 float ripple=sin(p.y*3.0+p.x*1.1-TIME*1.7);
 float basin=1.0-smoothstep(0.88,1.0,length((p-flood_center)/flood_radii));
 vec3 tea_water=water_paint(p,1.0-smoothstep(0.55,1.0,length((p-flood_center)/flood_radii)),TIME)*vec3(0.94,0.92,0.81);
 // Receding shore exposes wet ground from the edge inward, rather than recoloring a pond.
 float pond_distance=length((p-flood_center)/flood_radii);
 float remaining_water=1.0-smoothstep(max(0.0,0.88-drained),max(0.001,1.0-drained),pond_distance);
 vec3 wet_silt=mix(soil*vec3(0.8,0.68,0.5),vec3(0.25,0.19,0.115),0.5);
 ALBEDO=mix(ALBEDO,wet_silt,basin);
 ALBEDO=mix(ALBEDO,tea_water,remaining_water*(1.0-step(0.999,drained)));
 // The upper facility keeps paving, dirt and runoff on this same opaque terrain.
 float facility=smoothstep(86.0,91.0,-p.y);
 vec3 painted_stone=texture(stone_texture,p/8.0,1.0).rgb;
 painted_stone=mix(vec3(dot(painted_stone,vec3(0.2126,0.7152,0.0722))),painted_stone,0.5);
 vec3 old_stone=painted_stone*vec3(0.34,0.368,0.348);
 float gallery=min(segment_distance(p,vec2(28,-89),vec2(14,-95)),segment_distance(p,vec2(28,-89),vec2(42,-95)));
 gallery=min(gallery,segment_distance(p,vec2(14,-95),vec2(14,-115)));
 gallery=min(gallery,segment_distance(p,vec2(42,-95),vec2(42,-115)));
 gallery=min(gallery,segment_distance(p,vec2(14,-115),vec2(28,-122)));
 gallery=min(gallery,segment_distance(p,vec2(42,-115),vec2(28,-122)));
 old_stone=mix(old_stone,old_stone*vec3(1.12,1.08,0.98),0.6*(1.0-smoothstep(1.8,2.5,gallery)));
 float cistern=step(20.8,p.x)*step(p.x,35.2)*step(-110.2,p.y)*step(p.y,-99.8);
 old_stone=mix(old_stone,vec3(0.085,0.18,0.17)+smoothstep(0.94,1.0,ripple)*0.015,cistern);
 ALBEDO=mix(ALBEDO,old_stone,facility);
 ROUGHNESS=1.0;
 SPECULAR=0.0;
}
