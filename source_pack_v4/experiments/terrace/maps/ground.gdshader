shader_type spatial;
render_mode diffuse_burley;
uniform vec4 grass : source_color = vec4(0.32,0.46,0.36,1.0);
uniform vec4 trail : source_color = vec4(0.64,0.58,0.40,1.0);
uniform vec4 bank : source_color = vec4(0.45,0.53,0.39,1.0);
uniform vec4 water : source_color = vec4(0.12,0.38,0.39,1.0);
uniform bool has_water = true;
uniform vec2 route_points[7];
uniform int route_count = 7;
uniform bool art_enabled = true;
uniform bool altar_field = false;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D paving_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D water_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D masonry_tex : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
 world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 world_normal = (MODEL_MATRIX * vec4(NORMAL,0.0)).xyz;
}
float segment_distance(vec2 p, vec2 a, vec2 b) {
 vec2 ab=b-a;
 return length(p-a-ab*clamp(dot(p-a,ab)/max(dot(ab,ab),0.001),0.0,1.0));
}
void fragment() {
 vec2 p=world_pos.xz;
 float d=1000.0;
 for(int i=0;i<6;i++) {
  if(i<route_count-1) d=min(d,segment_distance(p,route_points[i],route_points[i+1]));
 }
 float variation=sin(p.x*0.79+sin(p.y*0.31))*sin(p.y*0.53)*0.022;
 vec3 col=mix(grass.rgb,trail.rgb,1.0-smoothstep(1.5,2.8,d));
 if(art_enabled) {
  vec3 g=texture(grass_tex,p/7.0).rgb*0.9;
  vec3 earth=texture(dirt_tex,p/6.0).rgb*0.86;
  vec3 stone=texture(paving_tex,p/6.5).rgb*0.78;
  float edge=d+sin(p.x*1.1)*sin(p.y*0.9)*0.26;
  col=mix(g,earth,1.0-smoothstep(2.1,3.1,edge));
  col=mix(col,stone,1.0-smoothstep(1.45,2.15,edge));
  if(altar_field) {
   float upper=smoothstep(4.7,5.05,world_pos.y);
   float court=(1.0-smoothstep(9.0,11.0,abs(p.x)))*smoothstep(-1.0,2.0,p.y)*(1.0-smoothstep(12.0,14.0,p.y));
   col=mix(col,stone,max(upper,court*0.8));
   vec3 n=normalize(world_normal);
   float steep=1.0-smoothstep(0.25,0.7,abs(n.y));
   vec2 wall_uv=abs(n.x)>abs(n.z) ? vec2(p.y,world_pos.y)/3.0 : vec2(p.x,world_pos.y)/3.0;
   vec3 wall=texture(masonry_tex,wall_uv).rgb*0.77;
   col=mix(col,wall,steep);
   if(abs(p.x)<3.2 && p.y<6.0 && p.y>-3.0) {
    float tread=1.0-smoothstep(0.025,0.09,abs(fract((6.0-p.y)*2.0)-0.06));
    col=stone*mix(1.0,0.5,tread);
   }
  }
 }
 float wet=0.0;
 if(has_water) {
  float w=length(vec2((p.x+1.0+sin(p.y*0.19)*2.0)/9.0,(p.y-3.0)/12.0))+0.035*sin(p.x*0.8+p.y*0.45)+0.022*cos(p.y*0.9);
  vec3 shore=art_enabled ? texture(dirt_tex,p/4.0).rgb*vec3(0.64,0.77,0.72) : bank.rgb;
  col=mix(shore,col,smoothstep(1.01,1.19,w));
  wet=1.0-smoothstep(0.935,0.965,w);
  float ripple=sin(p.y*4.1+sin(p.x*0.7)+TIME*0.8)*0.008;
  vec3 water_col=water.rgb+vec3(ripple);
  if(art_enabled) {
   vec2 flow=p/13.0+vec2(sin(p.y*0.3+TIME*0.6)*0.004,TIME*0.003);
   water_col=texture(water_tex,flow).rgb*mix(0.36,0.58,clamp(w,0.0,1.0));
  }
  col=mix(col,water_col,wet);
  if(art_enabled)col=mix(col,vec3(0.12,0.24,0.22),(1.0-smoothstep(0.006,0.025,abs(w-0.947)))*0.5);
 }
 ALBEDO=clamp(col+vec3(variation)*(1.0-wet),vec3(0.0),vec3(1.0));
 ROUGHNESS=mix(0.94,0.56,wet);
 SPECULAR=0.18;
}
